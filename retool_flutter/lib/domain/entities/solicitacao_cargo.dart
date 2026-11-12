import 'user.dart';

typedef SolicitacaoCargoStatus = String;

class SolicitacaoCargoStatuses {
  static const String pendente = 'pendente';
  static const String aprovada = 'aprovada';
  static const String rejeitada = 'rejeitada';
}

const int justificativaMax = 500;

const Map<String, String> rotuloStatusSolicitacao = {
  SolicitacaoCargoStatuses.pendente: 'Pendente',
  SolicitacaoCargoStatuses.aprovada: 'Aprovada',
  SolicitacaoCargoStatuses.rejeitada: 'Rejeitada',
};

bool podeSolicitarAlteracaoCargo(UserProfile? usuario) {
  return isContaOperacional(usuario) && usuario!.perfil != 'admin';
}

String? validarNovaSolicitacaoCargo(
  UserProfile? usuario,
  String? perfilSolicitado,
  SolicitacaoCargo? pendenteExistente, [
  String? justificativa,
]) {
  if (!podeSolicitarAlteracaoCargo(usuario)) {
    return 'Sua conta não pode solicitar alteração de cargo.';
  }
  if (!isPerfilAtribuivel(perfilSolicitado)) {
    return 'Selecione um cargo válido.';
  }
  if (perfilSolicitado == usuario!.perfil) {
    return 'O cargo solicitado deve ser diferente do cargo atual.';
  }
  if (pendenteExistente != null) {
    return 'Você já possui uma solicitação de alteração de cargo pendente.';
  }
  if (justificativa != null && justificativa.length > justificativaMax) {
    return 'A justificativa deve ter no máximo $justificativaMax caracteres.';
  }
  return null;
}

class SolicitacaoCargo {
  final String id;
  final String usuarioUid;
  final String usuarioNome;
  final String usuarioEmail;
  final String perfilAtual;
  final String perfilSolicitado;
  final String? justificativa;
  final String status;
  final String dataSolicitacao;
  final String? decididoPorUid;
  final String? decididoPorNome;
  final String? dataDecisao;
  final String? motivoDecisao;

  const SolicitacaoCargo({
    required this.id,
    required this.usuarioUid,
    required this.usuarioNome,
    required this.usuarioEmail,
    required this.perfilAtual,
    required this.perfilSolicitado,
    this.justificativa,
    required this.status,
    required this.dataSolicitacao,
    this.decididoPorUid,
    this.decididoPorNome,
    this.dataDecisao,
    this.motivoDecisao,
  });

  SolicitacaoCargo copyWith({
    String? id,
    String? usuarioUid,
    String? usuarioNome,
    String? usuarioEmail,
    String? perfilAtual,
    String? perfilSolicitado,
    String? justificativa,
    String? status,
    String? dataSolicitacao,
    String? decididoPorUid,
    String? decididoPorNome,
    String? dataDecisao,
    String? motivoDecisao,
  }) {
    return SolicitacaoCargo(
      id: id ?? this.id,
      usuarioUid: usuarioUid ?? this.usuarioUid,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      usuarioEmail: usuarioEmail ?? this.usuarioEmail,
      perfilAtual: perfilAtual ?? this.perfilAtual,
      perfilSolicitado: perfilSolicitado ?? this.perfilSolicitado,
      justificativa: justificativa ?? this.justificativa,
      status: status ?? this.status,
      dataSolicitacao: dataSolicitacao ?? this.dataSolicitacao,
      decididoPorUid: decididoPorUid ?? this.decididoPorUid,
      decididoPorNome: decididoPorNome ?? this.decididoPorNome,
      dataDecisao: dataDecisao ?? this.dataDecisao,
      motivoDecisao: motivoDecisao ?? this.motivoDecisao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioUid': usuarioUid,
      'usuarioNome': usuarioNome,
      'usuarioEmail': usuarioEmail,
      'perfilAtual': perfilAtual,
      'perfilSolicitado': perfilSolicitado,
      if (justificativa != null) 'justificativa': justificativa,
      'status': status,
      'dataSolicitacao': dataSolicitacao,
      if (decididoPorUid != null) 'decididoPorUid': decididoPorUid,
      if (decididoPorNome != null) 'decididoPorNome': decididoPorNome,
      if (dataDecisao != null) 'dataDecisao': dataDecisao,
      if (motivoDecisao != null) 'motivoDecisao': motivoDecisao,
    };
  }

  factory SolicitacaoCargo.fromMap(Map<String, dynamic> map, [String? id]) {
    return SolicitacaoCargo(
      id: id ?? (map['id'] as String? ?? ''),
      usuarioUid: map['usuarioUid'] as String? ?? '',
      usuarioNome: map['usuarioNome'] as String? ?? '',
      usuarioEmail: map['usuarioEmail'] as String? ?? '',
      perfilAtual: map['perfilAtual'] as String? ?? 'convidado',
      perfilSolicitado: map['perfilSolicitado'] as String? ?? 'engenharia',
      justificativa: map['justificativa'] as String?,
      status: map['status'] as String? ?? SolicitacaoCargoStatuses.pendente,
      dataSolicitacao: map['dataSolicitacao'] as String? ?? '',
      decididoPorUid: map['decididoPorUid'] as String?,
      decididoPorNome: map['decididoPorNome'] as String?,
      dataDecisao: map['dataDecisao'] as String?,
      motivoDecisao: map['motivoDecisao'] as String?,
    );
  }
}

