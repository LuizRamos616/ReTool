import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/solicitacao_cargo.dart';
import '../../domain/entities/notificacao.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import 'acessos_comum.dart';

class DadosSolicitacaoCargo {
  final UserProfile? usuario;
  final String perfilSolicitado;
  final String? justificativa;

  const DadosSolicitacaoCargo({
    required this.usuario,
    required this.perfilSolicitado,
    this.justificativa,
  });
}

class SolicitarAlteracaoCargoUseCase {
  final ISolicitacoesCargoRepository solicitacoesRepo;
  final IUsersRepository usersRepo;
  final IAuditLogRepository auditRepo;
  final INotificationsRepository notificationsRepo;

  SolicitarAlteracaoCargoUseCase(
    this.solicitacoesRepo,
    this.usersRepo,
    this.auditRepo,
    this.notificationsRepo,
  );

  Future<SolicitacaoCargo> execute(DadosSolicitacaoCargo dados) async {
    final justificativaLimpa = limparTexto(dados.justificativa, justificativaMax + 1);
    final pendente = dados.usuario != null
        ? await solicitacoesRepo.obterPendenteDoUsuario(dados.usuario!.uid)
        : null;
    final erro = validarNovaSolicitacaoCargo(
      dados.usuario,
      dados.perfilSolicitado,
      pendente,
      justificativaLimpa,
    );
    if (erro != null) throw ErroValidacao(erro);

    final agora = DateTime.now().toIso8601String();
    final solicitacao = SolicitacaoCargo(
      id: const Uuid().v4(),
      usuarioUid: dados.usuario!.uid,
      usuarioNome: dados.usuario!.nome,
      usuarioEmail: dados.usuario!.email,
      perfilAtual: dados.usuario!.perfil,
      perfilSolicitado: dados.perfilSolicitado,
      justificativa: justificativaLimpa.isNotEmpty ? justificativaLimpa : null,
      status: SolicitacaoCargoStatuses.pendente,
      dataSolicitacao: agora,
    );
    await solicitacoesRepo.criar(solicitacao);

    final notificados = await notificarAdministradores(
      usersRepo,
      notificationsRepo,
      (admin) => Notificacao(
        id: idNotificacao(NotificacaoTipos.cargoSolicitado, solicitacao.id, admin.uid),
        tipo: NotificacaoTipos.cargoSolicitado,
        destinatarioUid: admin.uid,
        remetenteUid: solicitacao.usuarioUid,
        titulo: 'Solicitação de alteração de cargo',
        descricao:
            '${solicitacao.usuarioNome} solicitou mudar de ${rolesConfig[solicitacao.perfilAtual]!.titulo} para ${rolesConfig[dados.perfilSolicitado]!.titulo}.',
        dataHora: solicitacao.dataSolicitacao,
        lida: false,
        entidadeId: solicitacao.id,
        perfilSolicitado: dados.perfilSolicitado,
      ),
      solicitacao.usuarioUid,
    );

    final autor = autorAuditoria(dados.usuario!);
    await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
      usuarioUid: autor.usuarioUid,
      usuarioNome: autor.usuarioNome,
      usuarioEmail: autor.usuarioEmail,
      usuarioPerfil: autor.usuarioPerfil,
      acao: AuditLogAcoes.solicitacaoCargo,
      categoria: AuditLogCategorias.usuarios,
      acaoDescricao: 'Solicitou alteração de cargo para ${rolesConfig[dados.perfilSolicitado]!.titulo}',
      tipoEntidade: 'solicitacao_cargo',
      entidadeId: solicitacao.id,
      entidadeNome: solicitacao.usuarioNome,
      conteudo: {
        'perfilAtual': solicitacao.perfilAtual,
        'perfilSolicitado': dados.perfilSolicitado,
        'justificativa': solicitacao.justificativa,
        'administradoresNotificados': notificados,
      },
    ));

    return solicitacao;
  }
}

