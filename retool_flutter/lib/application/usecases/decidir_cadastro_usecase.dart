import '../../domain/entities/user.dart';
import '../../domain/entities/notificacao.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import 'acessos_comum.dart';

class DecisaoCadastro {
  final UserProfile? admin;
  final String alvoUid;
  final bool aprovar;
  final String? perfil;
  final String? motivo;

  const DecisaoCadastro({
    required this.admin,
    required this.alvoUid,
    required this.aprovar,
    this.perfil,
    this.motivo,
  });
}

class DecidirCadastroUseCase {
  final IUsersRepository usersRepo;
  final IAuditLogRepository auditRepo;
  final INotificationsRepository notificationsRepo;

  DecidirCadastroUseCase(this.usersRepo, this.auditRepo, this.notificationsRepo);

  Future<UserProfile> execute(DecisaoCadastro param) async {
    final acao = param.aprovar ? AuditLogAcoes.aprovacaoUsuario : AuditLogAcoes.rejeicaoUsuario;

    if (!isAdministrador(param.admin)) {
      if (param.admin != null) {
        final autor = autorAuditoria(param.admin!);
        await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
          usuarioUid: autor.usuarioUid,
          usuarioNome: autor.usuarioNome,
          usuarioEmail: autor.usuarioEmail,
          usuarioPerfil: autor.usuarioPerfil,
          acao: acao,
          categoria: AuditLogCategorias.usuarios,
          resultado: 'negado',
          acaoDescricao: 'Tentativa de decidir cadastro sem permissão',
          tipoEntidade: 'usuario',
          entidadeId: param.alvoUid,
        ));
      }
      throw ErroPermissao();
    }

    final alvo = await usersRepo.getProfile(param.alvoUid);
    if (alvo == null) throw ErroValidacao('Cadastro não encontrado.');
    if (situacaoDoUsuario(alvo) != SituacaoUsuario.pendente) {
      throw ErroValidacao('Este cadastro já foi analisado.');
    }
    if (param.aprovar && !isPerfilAtribuivel(param.perfil)) {
      throw ErroValidacao('Defina o cargo do usuário para aprovar o cadastro.');
    }

    final agora = DateTime.now().toIso8601String();
    final motivoLimpo = limparTexto(param.motivo, 500);
    final alteracoes = <String, dynamic>{
      'ativo': param.aprovar,
      'statusAprovacao': param.aprovar ? 'aprovado' : 'rejeitado',
      'atualizadoEm': agora,
      if (param.aprovar) ...{
        'perfil': param.perfil!,
        'aprovadoPorUid': param.admin!.uid,
        'aprovadoEm': agora,
      } else ...{
        'rejeitadoPorUid': param.admin!.uid,
        'rejeitadoEm': agora,
        if (motivoLimpo.isNotEmpty) 'motivoRejeicao': motivoLimpo,
      }
    };

    try {
      await usersRepo.updateProfile(param.alvoUid, alteracoes);
    } catch (e) {
      final autor = autorAuditoria(param.admin!);
      await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
        usuarioUid: autor.usuarioUid,
        usuarioNome: autor.usuarioNome,
        usuarioEmail: autor.usuarioEmail,
        usuarioPerfil: autor.usuarioPerfil,
        acao: acao,
        categoria: AuditLogCategorias.usuarios,
        resultado: 'falha',
        acaoDescricao: param.aprovar ? 'Falha ao aprovar cadastro' : 'Falha ao rejeitar cadastro',
        tipoEntidade: 'usuario',
        entidadeId: param.alvoUid,
        entidadeNome: alvo.nome,
        conteudo: {'erro': e.toString()},
      ));
      rethrow;
    }

    try {
      await notificationsRepo.criar(Notificacao(
        id: idNotificacao(NotificacaoTipos.contaDecidida, param.alvoUid, param.alvoUid),
        tipo: NotificacaoTipos.contaDecidida,
        destinatarioUid: param.alvoUid,
        remetenteUid: param.admin!.uid,
        titulo: param.aprovar ? 'Cadastro aprovado' : 'Cadastro recusado',
        descricao: param.aprovar
            ? 'Seu acesso foi liberado com o cargo ${rolesConfig[param.perfil!]!.titulo}.'
            : 'Sua solicitação de cadastro foi recusada pela Administração.${motivoLimpo.isNotEmpty ? " Motivo: $motivoLimpo" : ""}',
        dataHora: agora,
        lida: false,
        entidadeId: param.alvoUid,
        perfilSolicitado: param.aprovar ? param.perfil : null,
        decisao: param.aprovar ? 'aprovada' : 'recusada',
      ));
    } catch (_) {}

    await notificationsRepo
        .marcarResolvida(idNotificacao(NotificacaoTipos.contaNova, param.alvoUid, param.admin!.uid), true)
        .catchError((_) {});

    final autor = autorAuditoria(param.admin!);
    await registrarAuditoriaSemFalhar(auditRepo, AuditLogInput(
      usuarioUid: autor.usuarioUid,
      usuarioNome: autor.usuarioNome,
      usuarioEmail: autor.usuarioEmail,
      usuarioPerfil: autor.usuarioPerfil,
      acao: acao,
      categoria: AuditLogCategorias.usuarios,
      acaoDescricao: param.aprovar
          ? 'Aprovou o cadastro de ${alvo.nome} com o cargo ${rolesConfig[param.perfil!]!.titulo}'
          : 'Rejeitou o cadastro de ${alvo.nome}',
      tipoEntidade: 'usuario',
      entidadeId: param.alvoUid,
      entidadeNome: alvo.nome,
      conteudo: param.aprovar
          ? {'perfilDefinido': param.perfil, 'email': alvo.email}
          : {'motivo': motivoLimpo.isNotEmpty ? motivoLimpo : null, 'email': alvo.email},
      dadosAnteriores: {
        'perfil': alvo.perfil,
        'ativo': alvo.ativo,
        'statusAprovacao': alvo.statusAprovacao ?? 'pendente',
      },
    ));

    return alvo.copyWith(
      perfil: param.aprovar ? param.perfil : alvo.perfil,
      ativo: param.aprovar,
      statusAprovacao: param.aprovar ? 'aprovado' : 'rejeitado',
      atualizadoEm: agora,
      aprovadoPorUid: param.aprovar ? param.admin!.uid : alvo.aprovadoPorUid,
      aprovadoEm: param.aprovar ? agora : alvo.aprovadoEm,
      rejeitadoPorUid: !param.aprovar ? param.admin!.uid : alvo.rejeitadoPorUid,
      rejeitadoEm: !param.aprovar ? agora : alvo.rejeitadoEm,
      motivoRejeicao: !param.aprovar ? motivoLimpo : alvo.motivoRejeicao,
    );
  }
}

