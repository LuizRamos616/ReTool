import '../../domain/entities/user.dart';
import '../../domain/entities/notificacao.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import 'acessos_comum.dart';

class DadosCadastro {
  final String uid;
  final String email;
  final String nome;

  const DadosCadastro({required this.uid, required this.email, required this.nome});
}

class SolicitarCadastroUseCase {
  final IUsersRepository usersRepo;
  final IAuditLogRepository auditRepo;
  final INotificationsRepository notificationsRepo;

  SolicitarCadastroUseCase(this.usersRepo, this.auditRepo, this.notificationsRepo);

  Future<UserProfile> execute(DadosCadastro dados) async {
    final nome = limparTexto(dados.nome, 120);
    if (nome.isEmpty) throw ErroValidacao('Informe seu nome completo.');

    final agora = DateTime.now().toIso8601String();
    final perfil = UserProfile(
      uid: dados.uid,
      email: dados.email.trim().toLowerCase(),
      nome: nome,
      perfil: UserRoles.convidado,
      ativo: false,
      statusAprovacao: 'pendente',
      criadoEm: agora,
    );
    await usersRepo.setProfile(perfil);

    final notificados = await notificarAdministradores(usersRepo, notificationsRepo, (admin) => Notificacao(
      id: idNotificacao(NotificacaoTipos.contaNova, perfil.uid, admin.uid),
      tipo: NotificacaoTipos.contaNova,
      destinatarioUid: admin.uid,
      remetenteUid: perfil.uid,
      titulo: 'Novo cadastro aguardando aprovação',
      descricao: '$nome (${perfil.email}) criou uma conta e aguarda a definição de cargo.',
      dataHora: agora,
      lida: false,
      entidadeId: perfil.uid,
    ));

    final autor = autorAuditoria(perfil);
    await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
      usuarioUid: autor.usuarioUid,
      usuarioNome: autor.usuarioNome,
      usuarioEmail: autor.usuarioEmail,
      usuarioPerfil: autor.usuarioPerfil,
      acao: AuditLogAcoes.cadastro,
      categoria: AuditLogCategorias.autenticacao,
      acaoDescricao: 'Solicitou cadastro no sistema (Convidado aguardando aprovação)',
      tipoEntidade: 'usuario',
      entidadeId: perfil.uid,
      entidadeNome: nome,
      conteudo: {
        'email': perfil.email,
        'perfil': perfil.perfil,
        'statusAprovacao': perfil.statusAprovacao,
        'administradoresNotificados': notificados,
      },
    ));

    return perfil;
  }
}

