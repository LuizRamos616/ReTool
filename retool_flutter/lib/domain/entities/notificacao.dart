typedef NotificacaoTipo = String;

class NotificacaoTipos {
  static const String reutilizacaoNova = 'reutilizacao_nova';
  static const String reutilizacaoDecidida = 'reutilizacao_decidida';
  static const String contaNova = 'conta_nova';
  static const String contaDecidida = 'conta_decidida';
  static const String cargoSolicitado = 'cargo_solicitado';
  static const String cargoDecidido = 'cargo_decidido';
}

/// Id determinístico: impede notificações duplicadas para o mesmo evento.
String idNotificacao(String tipo, String entidadeId, String destinatarioUid) {
  return '${tipo}_${entidadeId}_$destinatarioUid';
}

class Notificacao {
  final String id;
  final String tipo;
  final String destinatarioUid;
  final String remetenteUid;
  final String titulo;
  final String descricao;
  final String dataHora;
  final bool lida;
  final bool? resolvida;
  final String? entidadeId;
  final String? dispositivoId;
  final String? perfilSolicitado;
  final String? decisao;

  const Notificacao({
    required this.id,
    required this.tipo,
    required this.destinatarioUid,
    required this.remetenteUid,
    required this.titulo,
    required this.descricao,
    required this.dataHora,
    this.lida = false,
    this.resolvida,
    this.entidadeId,
    this.dispositivoId,
    this.perfilSolicitado,
    this.decisao,
  });

  Notificacao copyWith({
    String? id,
    String? tipo,
    String? destinatarioUid,
    String? remetenteUid,
    String? titulo,
    String? descricao,
    String? dataHora,
    bool? lida,
    bool? resolvida,
    String? entidadeId,
    String? dispositivoId,
    String? perfilSolicitado,
    String? decisao,
  }) {
    return Notificacao(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      destinatarioUid: destinatarioUid ?? this.destinatarioUid,
      remetenteUid: remetenteUid ?? this.remetenteUid,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataHora: dataHora ?? this.dataHora,
      lida: lida ?? this.lida,
      resolvida: resolvida ?? this.resolvida,
      entidadeId: entidadeId ?? this.entidadeId,
      dispositivoId: dispositivoId ?? this.dispositivoId,
      perfilSolicitado: perfilSolicitado ?? this.perfilSolicitado,
      decisao: decisao ?? this.decisao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'destinatarioUid': destinatarioUid,
      'remetenteUid': remetenteUid,
      'titulo': titulo,
      'descricao': descricao,
      'dataHora': dataHora,
      'lida': lida,
      if (resolvida != null) 'resolvida': resolvida,
      if (entidadeId != null) 'entidadeId': entidadeId,
      if (dispositivoId != null) 'dispositivoId': dispositivoId,
      if (perfilSolicitado != null) 'perfilSolicitado': perfilSolicitado,
      if (decisao != null) 'decisao': decisao,
    };
  }

  factory Notificacao.fromMap(Map<String, dynamic> map, [String? id]) {
    return Notificacao(
      id: id ?? (map['id'] as String? ?? ''),
      tipo: map['tipo'] as String? ?? NotificacaoTipos.contaNova,
      destinatarioUid: map['destinatarioUid'] as String? ?? '',
      remetenteUid: map['remetenteUid'] as String? ?? '',
      titulo: map['titulo'] as String? ?? '',
      descricao: map['descricao'] as String? ?? '',
      dataHora: map['dataHora'] as String? ?? '',
      lida: map['lida'] as bool? ?? false,
      resolvida: map['resolvida'] as bool?,
      entidadeId: map['entidadeId'] as String?,
      dispositivoId: map['dispositivoId'] as String?,
      perfilSolicitado: map['perfilSolicitado'] as String?,
      decisao: map['decisao'] as String?,
    );
  }
}

