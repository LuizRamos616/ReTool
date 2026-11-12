import '../entities/user.dart';
import '../entities/audit_log.dart';
import '../entities/notificacao.dart';
import '../entities/solicitacao_cargo.dart';

abstract class IUsersRepository {
  Future<UserProfile?> getProfile(String uid);
  Future<void> setProfile(UserProfile profile);
  Future<void> updateProfile(String uid, Map<String, dynamic> data);
  Future<List<UserProfile>> listarAdministradoresAtivos();
  Stream<List<UserProfile>> watchUsers();
  Stream<UserProfile?> watchProfile(String uid);
}

class AuditLogInput {
  final String usuarioUid;
  final String usuarioNome;
  final String usuarioEmail;
  final String usuarioPerfil;
  final String acao;
  final String categoria;
  final String resultado;
  final String? acaoDescricao;
  final String tipoEntidade;
  final String entidadeId;
  final String? entidadeNome;
  final String? detalhes;
  final Map<String, dynamic>? conteudo;
  final Map<String, dynamic>? dadosAnteriores;
  final String? dataHora;

  const AuditLogInput({
    required this.usuarioUid,
    required this.usuarioNome,
    required this.usuarioEmail,
    required this.usuarioPerfil,
    required this.acao,
    required this.categoria,
    this.resultado = 'sucesso',
    this.acaoDescricao,
    required this.tipoEntidade,
    required this.entidadeId,
    this.entidadeNome,
    this.detalhes,
    this.conteudo,
    this.dadosAnteriores,
    this.dataHora,
  });
}

abstract class IAuditLogRepository {
  Future<String> registrarLog(AuditLogInput logData);
  Future<List<AuditLog>> listarLogs({
    String? categoria,
    String? acao,
    String? usuarioUid,
    String? tipoEntidade,
    String? resultado,
    int limite = 50,
  });
}

abstract class INotificationsRepository {
  Future<void> criar(Notificacao notificacao);
  Future<void> marcarResolvida(String id, bool resolvida);
  Future<void> marcarLida(String id, bool lida);
  Stream<List<Notificacao>> watchNotifications(String destinatarioUid);
}

class DecisaoSolicitacaoCargo {
  final String status; // 'aprovada' | 'rejeitada'
  final String decididoPorUid;
  final String decididoPorNome;
  final String dataDecisao;
  final String? motivoDecisao;

  const DecisaoSolicitacaoCargo({
    required this.status,
    required this.decididoPorUid,
    required this.decididoPorNome,
    required this.dataDecisao,
    this.motivoDecisao,
  });
}

abstract class ISolicitacoesCargoRepository {
  Future<SolicitacaoCargo?> obter(String id);
  Future<SolicitacaoCargo?> obterPendenteDoUsuario(String uid);
  Future<void> criar(SolicitacaoCargo solicitacao);
  Future<void> decidir(SolicitacaoCargo solicitacao, DecisaoSolicitacaoCargo decisao);
  Stream<List<SolicitacaoCargo>> watchSolicitacoes({String? usuarioUid});
}

