import '../../domain/entities/user.dart';
import '../../domain/entities/notificacao.dart';
import '../../domain/repositories/i_acessos_repositories.dart';

class ErroPermissao implements Exception {
  final String message;
  ErroPermissao([this.message = 'Acesso negado: operação exclusiva da Administração.']);

  @override
  String toString() => 'ErroPermissao: $message';
}

class ErroValidacao implements Exception {
  final String message;
  ErroValidacao(this.message);

  @override
  String toString() => 'ErroValidacao: $message';
}

class AutorAuditoria {
  final String usuarioUid;
  final String usuarioNome;
  final String usuarioEmail;
  final String usuarioPerfil;

  const AutorAuditoria({
    required this.usuarioUid,
    required this.usuarioNome,
    required this.usuarioEmail,
    required this.usuarioPerfil,
  });
}

AutorAuditoria autorAuditoria(UserProfile u) {
  return AutorAuditoria(
    usuarioUid: u.uid,
    usuarioNome: u.nome,
    usuarioEmail: u.email,
    usuarioPerfil: u.perfil,
  );
}

Future<void> registrarAuditoriaSemFalhar(IAuditLogRepository repo, AuditLogInput input) async {
  try {
    await repo.registrarLog(input);
  } catch (e) {
    // A auditoria nunca derruba a operação principal: falhas viram aviso no console.
    // ignore: avoid_print
    print('Falha ao registrar auditoria: $e');
  }
}

Future<int> notificarAdministradores(
  IUsersRepository usersRepo,
  INotificationsRepository notificationsRepo,
  Notificacao Function(UserProfile admin) montar, [
  String? exceto,
]) async {
  List<UserProfile> admins = [];
  try {
    admins = await usersRepo.listarAdministradoresAtivos();
  } catch (e) {
    // ignore: avoid_print
    print('Não foi possível localizar a Administração para notificar: $e');
    return 0;
  }
  int enviados = 0;
  for (final admin in admins) {
    if (admin.uid == exceto) continue;
    try {
      await notificationsRepo.criar(montar(admin));
      enviados++;
    } catch (e) {
      // ignore: avoid_print
      print('Falha ao notificar a Administração: $e');
    }
  }
  return enviados;
}

String limparTexto(String? valor, int max) {
  final s = (valor ?? '').trim();
  return s.length > max ? s.substring(0, max) : s;
}

bool emailValido(String email) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
}

