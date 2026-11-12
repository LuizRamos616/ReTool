import '../../domain/entities/user.dart';
import '../../domain/entities/solicitacao_cargo.dart';
import '../../domain/entities/notificacao.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import 'acessos_comum.dart';

class DadosDecisaoCargo {
  final UserProfile? admin;
  final String solicitacaoId;
  final bool aprovar;
  final String? motivo;

  const DadosDecisaoCargo({
    required this.admin,
    required this.solicitacaoId,
    required this.aprovar,
    this.motivo,
  });
}

class DecidirSolicitacaoCargoUseCase {
  final ISolicitacoesCargoRepository solicitacoesRepo;
  final IUsersRepository usersRepo;
  final IAuditLogRepository auditRepo;
  final INotificationsRepository notificationsRepo;

  DecidirSolicitacaoCargoUseCase(
    this.solicitacoesRepo,
    this.usersRepo,
    this.auditRepo,
    this.notificationsRepo,
  );

  Future<SolicitacaoCargo> execute(DadosDecisaoCargo dados) async {
    final acao = dados.aprovar ? AuditLogAcoes.aprovacaoCargo : AuditLogAcoes.rejeicaoCargo;

    if (!isAdministrador(dados.admin)) {
      if (dados.admin != null) {
        final autor = autorAuditoria(dados.admin!);
        await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
          usuarioUid: autor.usuarioUid,
          usuarioNome: autor.usuarioNome,
          usuarioEmail: autor.usuarioEmail,
          usuarioPerfil: autor.usuarioPerfil,
          acao: acao,
          categoria: AuditLogCategorias.usuarios,
          resultado: 'negado',
          acaoDescricao: 'Tentativa de decidir solicitação de cargo sem permissão',
          tipoEntidade: 'solicitacao_cargo',
          entidadeId: dados.solicitacaoId,
        ));
      }
      throw ErroPermissao();
    }

    final solicitacao = await solicitacoesRepo.obter(dados.solicitacaoId);
    if (solicitacao == null) throw ErroValidacao('Solicitação não encontrada.');
    if (solicitacao.status != SolicitacaoCargoStatuses.pendente) {
      throw ErroValidacao('Esta solicitação já foi analisada.');
    }
    if (solicitacao.usuarioUid == dados.admin!.uid) {
      throw ErroPermissao('Uma solicitação não pode ser decidida pelo próprio solicitante.');
    }

    final alvo = await usersRepo.getProfile(solicitacao.usuarioUid);
    if (dados.aprovar && alvo == null) {
      throw ErroValidacao('O usuário desta solicitação não existe mais; apenas a rejeição é possível.');
    }

    final motivoLimpo = limparTexto(dados.motivo, 500);
    final agora = DateTime.now().toIso8601String();
    final decisao = DecisaoSolicitacaoCargo(
      status: dados.aprovar ? SolicitacaoCargoStatuses.aprovada : SolicitacaoCargoStatuses.rejeitada,
      decididoPorUid: dados.admin!.uid,
      decididoPorNome: dados.admin!.nome,
      dataDecisao: agora,
      motivoDecisao: motivoLimpo.isNotEmpty ? motivoLimpo : null,
    );

    try {
      await solicitacoesRepo.decidir(solicitacao, decisao);
    } catch (e) {
      final autor = autorAuditoria(dados.admin!);
      await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
        usuarioUid: autor.usuarioUid,
        usuarioNome: autor.usuarioNome,
        usuarioEmail: autor.usuarioEmail,
        usuarioPerfil: autor.usuarioPerfil,
        acao: acao,
        categoria: AuditLogCategorias.usuarios,
        resultado: 'falha',
        acaoDescricao: dados.aprovar
            ? 'Falha ao aprovar alteração de cargo'
            : 'Falha ao rejeitar alteração de cargo',
        tipoEntidade: 'solicitacao_cargo',
        entidadeId: solicitacao.id,
        entidadeNome: solicitacao.usuarioNome,
        conteudo: {'erro': e.toString()},
      ));
      rethrow;
    }

    final para = rolesConfig[solicitacao.perfilSolicitado]?.titulo ?? solicitacao.perfilSolicitado;

    if (alvo != null) {
      try {
        await notificationsRepo.criar(Notificacao(
          id: idNotificacao(NotificacaoTipos.cargoDecidido, solicitacao.id, solicitacao.usuarioUid),
          tipo: NotificacaoTipos.cargoDecidido,
          destinatarioUid: solicitacao.usuarioUid,
          remetenteUid: dados.admin!.uid,
          titulo: dados.aprovar ? 'Alteração de cargo aprovada' : 'Alteração de cargo rejeitada',
          descricao: dados.aprovar
              ? 'Seu cargo foi alterado para $para.'
              : 'Sua solicitação para $para foi rejeitada.${motivoLimpo.isNotEmpty ? " Motivo: $motivoLimpo" : ""}',
          dataHora: decisao.dataDecisao,
          lida: false,
          entidadeId: solicitacao.id,
          perfilSolicitado: solicitacao.perfilSolicitado,
          decisao: dados.aprovar ? 'aprovada' : 'rejeitada',
        ));
      } catch (_) {}
    }

    await notificationsRepo
        .marcarResolvida(idNotificacao(NotificacaoTipos.cargoSolicitado, solicitacao.id, dados.admin!.uid), true)
        .catchError((_) {});

    final autor = autorAuditoria(dados.admin!);
    await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
      usuarioUid: autor.usuarioUid,
      usuarioNome: autor.usuarioNome,
      usuarioEmail: autor.usuarioEmail,
      usuarioPerfil: autor.usuarioPerfil,
      acao: acao,
      categoria: AuditLogCategorias.usuarios,
      acaoDescricao: dados.aprovar
          ? 'Aprovou alteração de cargo de ${solicitacao.usuarioNome} para $para'
          : 'Rejeitou solicitação de alteração de cargo de ${solicitacao.usuarioNome}',
      tipoEntidade: 'solicitacao_cargo',
      entidadeId: solicitacao.id,
      entidadeNome: solicitacao.usuarioNome,
      conteudo: dados.aprovar
          ? {'perfilNovo': solicitacao.perfilSolicitado, 'perfilAnterior': solicitacao.perfilAtual}
          : {'motivo': motivoLimpo.isNotEmpty ? motivoLimpo : null},
      dadosAnteriores: {'perfil': solicitacao.perfilAtual},
    ));

    return solicitacao.copyWith(
      status: decisao.status,
      decididoPorUid: decisao.decididoPorUid,
      decididoPorNome: decisao.decididoPorNome,
      dataDecisao: decisao.dataDecisao,
      motivoDecisao: decisao.motivoDecisao,
    );
  }
}

