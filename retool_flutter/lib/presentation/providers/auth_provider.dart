import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/notificacao.dart';
import '../../domain/entities/solicitacao_cargo.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import '../../data/datasources/firebase_datasource.dart';
import '../../data/repositories/firestore_users_repository.dart';
import '../../data/repositories/firestore_audit_log_repository.dart';
import '../../data/repositories/firestore_notifications_repository.dart';
import '../../data/repositories/firestore_solicitacoes_cargo_repository.dart';
import '../../application/usecases/solicitar_cadastro_usecase.dart';
import '../../application/usecases/decidir_cadastro_usecase.dart';
import '../../application/usecases/criar_conta_administrativa_usecase.dart';
import '../../application/usecases/concluir_troca_senha_usecase.dart';
import '../../application/usecases/solicitar_alteracao_cargo_usecase.dart';
import '../../application/usecases/decidir_solicitacao_cargo_usecase.dart';

final usersRepoProvider = Provider<IUsersRepository>((ref) => FirestoreUsersRepository());
final auditRepoProvider = Provider<IAuditLogRepository>((ref) => FirestoreAuditLogRepository());
final notificationsRepoProvider = Provider<INotificationsRepository>((ref) => FirestoreNotificationsRepository());
final solicitacoesCargoRepoProvider = Provider<ISolicitacoesCargoRepository>((ref) => FirestoreSolicitacoesCargoRepository());

class AuthState {
  final User? firebaseUser;
  final UserProfile? userProfile;
  final bool loading;
  final String? errorMessage;
  final List<UserProfile> users;
  final List<SolicitacaoCargo> solicitacoesCargo;
  final List<Notificacao> notifications;

  const AuthState({
    this.firebaseUser,
    this.userProfile,
    this.loading = true,
    this.errorMessage,
    this.users = const [],
    this.solicitacoesCargo = const [],
    this.notifications = const [],
  });

  String get currentRole => userProfile?.perfil ?? UserRoles.convidado;
  RoleConfig get roleConfig => configDoPerfil(userProfile?.perfil);
  bool get isOperacional => isContaOperacional(userProfile);
  TelaDaSessao get tela => telaDaSessao(userProfile);

  bool get canConsultar => roleConfig.canConsultar;
  bool get canCadastrar => roleConfig.canCadastrar;
  bool get canEditar => roleConfig.canEditar;
  bool get canExcluir => roleConfig.canExcluir;
  bool get canAprovar => roleConfig.canAprovar;
  bool get canSolicitar => roleConfig.canSolicitar;
  bool get canGerenciarUsuarios => roleConfig.canGerenciarUsuarios;
  bool get canVerLogs => roleConfig.canVerLogs;

  AuthState copyWith({
    User? firebaseUser,
    UserProfile? userProfile,
    bool? loading,
    String? errorMessage,
    List<UserProfile>? users,
    List<SolicitacaoCargo>? solicitacoesCargo,
    List<Notificacao>? notifications,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userProfile: userProfile ?? this.userProfile,
      loading: loading ?? this.loading,
      errorMessage: errorMessage,
      users: users ?? this.users,
      solicitacoesCargo: solicitacoesCargo ?? this.solicitacoesCargo,
      notifications: notifications ?? this.notifications,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<List<UserProfile>>? _usersSubscription;
  StreamSubscription<List<SolicitacaoCargo>>? _solicitacoesSubscription;
  StreamSubscription<List<Notificacao>>? _notificationsSubscription;

  AuthNotifier(this.ref) : super(const AuthState()) {
    _init();
  }

  void _init() {
    try {
      _authSubscription = FirebaseDataSource.auth.authStateChanges().listen((user) async {
        if (user == null) {
          _cancelSubscriptions();
          state = const AuthState(loading: false);
        } else {
          state = state.copyWith(firebaseUser: user, loading: true);
          _subscribeToUserData(user.uid);
        }
      });
    } catch (_) {
      // In offline/test mode without native Firebase initialized
      state = state.copyWith(loading: false);
    }
  }

  void _cancelSubscriptions() {
    _profileSubscription?.cancel();
    _usersSubscription?.cancel();
    _solicitacoesSubscription?.cancel();
    _notificationsSubscription?.cancel();
  }

  void _subscribeToUserData(String uid) {
    _cancelSubscriptions();
    final usersRepo = ref.read(usersRepoProvider);
    final notificationsRepo = ref.read(notificationsRepoProvider);
    final solicitacoesRepo = ref.read(solicitacoesCargoRepoProvider);

    _profileSubscription = usersRepo.watchProfile(uid).listen((profile) {
      state = state.copyWith(userProfile: profile, loading: false);
      if (profile != null && profile.perfil == UserRoles.admin) {
        _usersSubscription = usersRepo.watchUsers().listen((usersList) {
          state = state.copyWith(users: usersList);
        });
      }
    });

    _notificationsSubscription = notificationsRepo.watchNotifications(uid).listen((notes) {
      state = state.copyWith(notifications: notes);
    });

    _solicitacoesSubscription = solicitacoesRepo.watchSolicitacoes().listen((solicitacoes) {
      state = state.copyWith(solicitacoesCargo: solicitacoes);
    });
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      await FirebaseDataSource.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      state = state.copyWith(loading: false, errorMessage: _traduzirErroAuth(e));
      rethrow;
    }
  }

  Future<void> register(String email, String password, String nome) async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final cred = await FirebaseDataSource.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final usecase = SolicitarCadastroUseCase(
        ref.read(usersRepoProvider),
        ref.read(auditRepoProvider),
        ref.read(notificationsRepoProvider),
      );
      await usecase.execute(DadosCadastro(uid: cred.user!.uid, email: email, nome: nome));
    } catch (e) {
      state = state.copyWith(loading: false, errorMessage: _traduzirErroAuth(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    _cancelSubscriptions();
    try {
      await FirebaseDataSource.auth.signOut();
    } catch (_) {}
    state = const AuthState(loading: false);
  }

  Future<void> decidirCadastro(String alvoUid, bool aprovar, [String? perfil, String? motivo]) async {
    final usecase = DecidirCadastroUseCase(
      ref.read(usersRepoProvider),
      ref.read(auditRepoProvider),
      ref.read(notificationsRepoProvider),
    );
    await usecase.execute(DecisaoCadastro(
      admin: state.userProfile,
      alvoUid: alvoUid,
      aprovar: aprovar,
      perfil: perfil,
      motivo: motivo,
    ));
  }

  Future<ContaCriada> criarContaComSenhaTemporaria(String nome, String email, String perfil) async {
    final usecase = CriarContaAdministrativaUseCase(
      ref.read(usersRepoProvider),
      ref.read(auditRepoProvider),
      (mail, pass) async {
        final secApp = await FirebaseDataSource.getSecondaryApp();
        final secAuth = FirebaseAuth.instanceFor(app: secApp);
        final cred = await secAuth.createUserWithEmailAndPassword(email: mail, password: pass);
        return ContaAuthCriada(
          uid: cred.user!.uid,
          desfazer: () => cred.user!.delete(),
          finalizar: () => secAuth.signOut(),
        );
      },
    );
    return usecase.execute(DadosNovaConta(
      admin: state.userProfile,
      nome: nome,
      email: email,
      perfil: perfil,
    ));
  }

  Future<void> concluirTrocaSenha(String senhaAtual, String novaSenha, String confirmacao) async {
    final usecase = ConcluirTrocaSenhaUseCase(
      ref.read(usersRepoProvider),
      ref.read(auditRepoProvider),
      (atual, nova) async {
        final user = FirebaseDataSource.auth.currentUser;
        if (user == null || user.email == null) throw Exception('Sessão expirada.');
        final cred = EmailAuthProvider.credential(email: user.email!, password: atual);
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(nova);
      },
    );
    await usecase.execute(DadosTrocaSenha(
      usuario: state.userProfile!,
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
      confirmacao: confirmacao,
    ));
  }

  Future<void> solicitarAlteracaoCargo(String perfilSolicitado, [String? justificativa]) async {
    final usecase = SolicitarAlteracaoCargoUseCase(
      ref.read(solicitacoesCargoRepoProvider),
      ref.read(usersRepoProvider),
      ref.read(auditRepoProvider),
      ref.read(notificationsRepoProvider),
    );
    await usecase.execute(DadosSolicitacaoCargo(
      usuario: state.userProfile,
      perfilSolicitado: perfilSolicitado,
      justificativa: justificativa,
    ));
  }

  Future<void> decidirSolicitacaoCargo(String solicitacaoId, bool aprovar, [String? motivo]) async {
    final usecase = DecidirSolicitacaoCargoUseCase(
      ref.read(solicitacoesCargoRepoProvider),
      ref.read(usersRepoProvider),
      ref.read(auditRepoProvider),
      ref.read(notificationsRepoProvider),
    );
    await usecase.execute(DadosDecisaoCargo(
      admin: state.userProfile,
      solicitacaoId: solicitacaoId,
      aprovar: aprovar,
      motivo: motivo,
    ));
  }

  Future<void> marcarNotificacaoLida(String id, bool lida) async {
    await ref.read(notificationsRepoProvider).marcarLida(id, lida);
  }

  Future<void> marcarNotificacaoResolvida(String id, bool resolvida) async {
    await ref.read(notificationsRepoProvider).marcarResolvida(id, resolvida);
  }

  Future<void> toggleUserStatus(String uid, bool ativo) async {
    await ref.read(usersRepoProvider).updateProfile(uid, {
      'ativo': ativo,
      'atualizadoEm': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateUserRole(String uid, String perfil) async {
    await ref.read(usersRepoProvider).updateProfile(uid, {
      'perfil': perfil,
      'atualizadoEm': DateTime.now().toIso8601String(),
    });
  }

  void setUserProfileForTesting(UserProfile profile) {
    state = state.copyWith(userProfile: profile, loading: false);
  }

  String _traduzirErroAuth(dynamic err) {
    final code = err is FirebaseAuthException ? err.code : err.toString();
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado no sistema.';
      case 'weak-password':
        return 'A senha deve conter no mínimo 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas seguidas. Aguarde alguns minutos e tente novamente.';
      case 'invalid-email':
        return 'Informe um e-mail válido.';
      default:
        return 'Erro ao processar autenticação: $code';
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

