import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

typedef ReutilizacaoStatus = String;

class ReutilizacaoStatuses {
  static const String analiseEngenharia = 'Em análise (Engenharia)';
  static const String analiseProjetista = 'Em análise (Projetista)';
  static const String reutilizacaoAprovada = 'Reutilização aprovada';
  static const String reutilizacaoNaoAprovada = 'Reutilização não aprovada';
  static const String liberadoFabricacao = 'Liberado para fabricação (novo dispositivo)';
  static const String aguardandoNovoFiltro = 'Aguardando novo filtro (Projetista)';

  static const List<String> todos = [
    analiseEngenharia,
    analiseProjetista,
    reutilizacaoAprovada,
    reutilizacaoNaoAprovada,
    liberadoFabricacao,
    aguardandoNovoFiltro,
  ];
}

String normalizarStatusReutilizacao(String? status) {
  switch (status) {
    case 'pendente':
      return ReutilizacaoStatuses.analiseProjetista;
    case 'aprovado':
      return ReutilizacaoStatuses.reutilizacaoAprovada;
    case 'rejeitado':
      return ReutilizacaoStatuses.reutilizacaoNaoAprovada;
    case 'Em andamento - OS':
      return ReutilizacaoStatuses.reutilizacaoAprovada;
    default:
      if (status != null && ReutilizacaoStatuses.todos.contains(status)) {
        return status;
      }
      return ReutilizacaoStatuses.analiseProjetista;
  }
}

const Map<String, Map<String, List<String>>> transicoesReutilizacao = {
  'admin': {
    ReutilizacaoStatuses.analiseEngenharia: [ReutilizacaoStatuses.analiseProjetista],
    ReutilizacaoStatuses.analiseProjetista: [
      ReutilizacaoStatuses.reutilizacaoAprovada,
      ReutilizacaoStatuses.reutilizacaoNaoAprovada,
    ],
    ReutilizacaoStatuses.reutilizacaoNaoAprovada: [ReutilizacaoStatuses.aguardandoNovoFiltro],
    ReutilizacaoStatuses.aguardandoNovoFiltro: [
      ReutilizacaoStatuses.analiseProjetista,
      ReutilizacaoStatuses.liberadoFabricacao,
    ],
  },
  'projetista': {
    ReutilizacaoStatuses.analiseProjetista: [
      ReutilizacaoStatuses.reutilizacaoAprovada,
      ReutilizacaoStatuses.reutilizacaoNaoAprovada,
    ],
    ReutilizacaoStatuses.aguardandoNovoFiltro: [
      ReutilizacaoStatuses.analiseProjetista,
      ReutilizacaoStatuses.liberadoFabricacao,
    ],
  },
  'engenharia': {
    ReutilizacaoStatuses.analiseEngenharia: [ReutilizacaoStatuses.analiseProjetista],
    ReutilizacaoStatuses.reutilizacaoNaoAprovada: [ReutilizacaoStatuses.aguardandoNovoFiltro],
  },
  'gerencia': {},
};

bool transicaoReutilizacaoPermitida(String perfil, String de, String para) {
  final mapa = transicoesReutilizacao[perfil];
  if (mapa == null) return false;
  final destinos = mapa[de];
  return destinos != null && destinos.contains(para);
}

String rotuloCurtoStatusReutilizacao(String status) {
  switch (status) {
    case ReutilizacaoStatuses.analiseEngenharia:
      return 'Análise Engenharia';
    case ReutilizacaoStatuses.analiseProjetista:
      return 'Em análise';
    case ReutilizacaoStatuses.reutilizacaoAprovada:
      return 'Aprovada';
    case ReutilizacaoStatuses.reutilizacaoNaoAprovada:
      return 'Não aprovada';
    case ReutilizacaoStatuses.liberadoFabricacao:
      return 'Liberado p/ fabricação';
    case ReutilizacaoStatuses.aguardandoNovoFiltro:
      return 'Novo filtro';
    default:
      return status;
  }
}

class StatusCor {
  final Color fundo;
  final Color texto;
  const StatusCor({required this.fundo, required this.texto});
}

StatusCor corDoStatusReutilizacao(String status) {
  switch (status) {
    case ReutilizacaoStatuses.analiseEngenharia:
      return const StatusCor(fundo: Color(0xFFE0E7FF), texto: Color(0xFF3730A3));
    case ReutilizacaoStatuses.analiseProjetista:
      return const StatusCor(fundo: AppColors.boxYellowBg, texto: Color(0xFFB45309));
    case ReutilizacaoStatuses.aguardandoNovoFiltro:
      return const StatusCor(fundo: AppColors.boxBlueBg, texto: AppColors.boxBlueText);
    case ReutilizacaoStatuses.reutilizacaoAprovada:
    case ReutilizacaoStatuses.liberadoFabricacao:
      return const StatusCor(fundo: Color(0xFFDCFCE7), texto: AppColors.success00);
    case ReutilizacaoStatuses.reutilizacaoNaoAprovada:
      return const StatusCor(fundo: Color(0xFFFEE2E2), texto: AppColors.danger);
    default:
      return const StatusCor(fundo: AppColors.gray03, texto: AppColors.gray00);
  }
}

class Reutilizacao {
  final String id;
  final String dispositivoId;
  final String data;
  final String codigoPeca;
  final String descricaoPeca;
  final String produtoId;
  final double pesoPeca;
  final double hardSaving;
  final String responsavel;
  final String numeroOs;
  final String descricaoAlteracao;
  final String? dataCriacao;
  final String? status;
  final String? solicitanteId;
  final String? solicitanteNome;
  final String? aprovadorId;
  final String? aprovadorNome;
  final String? dataAprovacao;
  final String? motivoRejeicao;

  const Reutilizacao({
    required this.id,
    required this.dispositivoId,
    required this.data,
    required this.codigoPeca,
    required this.descricaoPeca,
    required this.produtoId,
    required this.pesoPeca,
    required this.hardSaving,
    required this.responsavel,
    required this.numeroOs,
    required this.descricaoAlteracao,
    this.dataCriacao,
    this.status,
    this.solicitanteId,
    this.solicitanteNome,
    this.aprovadorId,
    this.aprovadorNome,
    this.dataAprovacao,
    this.motivoRejeicao,
  });

  Reutilizacao copyWith({
    String? id,
    String? dispositivoId,
    String? data,
    String? codigoPeca,
    String? descricaoPeca,
    String? produtoId,
    double? pesoPeca,
    double? hardSaving,
    String? responsavel,
    String? numeroOs,
    String? descricaoAlteracao,
    String? dataCriacao,
    String? status,
    String? solicitanteId,
    String? solicitanteNome,
    String? aprovadorId,
    String? aprovadorNome,
    String? dataAprovacao,
    String? motivoRejeicao,
  }) {
    return Reutilizacao(
      id: id ?? this.id,
      dispositivoId: dispositivoId ?? this.dispositivoId,
      data: data ?? this.data,
      codigoPeca: codigoPeca ?? this.codigoPeca,
      descricaoPeca: descricaoPeca ?? this.descricaoPeca,
      produtoId: produtoId ?? this.produtoId,
      pesoPeca: pesoPeca ?? this.pesoPeca,
      hardSaving: hardSaving ?? this.hardSaving,
      responsavel: responsavel ?? this.responsavel,
      numeroOs: numeroOs ?? this.numeroOs,
      descricaoAlteracao: descricaoAlteracao ?? this.descricaoAlteracao,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      status: status ?? this.status,
      solicitanteId: solicitanteId ?? this.solicitanteId,
      solicitanteNome: solicitanteNome ?? this.solicitanteNome,
      aprovadorId: aprovadorId ?? this.aprovadorId,
      aprovadorNome: aprovadorNome ?? this.aprovadorNome,
      dataAprovacao: dataAprovacao ?? this.dataAprovacao,
      motivoRejeicao: motivoRejeicao ?? this.motivoRejeicao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dispositivoId': dispositivoId,
      'data': data,
      'codigoPeca': codigoPeca,
      'descricaoPeca': descricaoPeca,
      'produtoId': produtoId,
      'pesoPeca': pesoPeca,
      'hardSaving': hardSaving,
      'responsavel': responsavel,
      'numeroOs': numeroOs,
      'descricaoAlteracao': descricaoAlteracao,
      if (dataCriacao != null) 'dataCriacao': dataCriacao,
      if (status != null) 'status': status,
      if (solicitanteId != null) 'solicitanteId': solicitanteId,
      if (solicitanteNome != null) 'solicitanteNome': solicitanteNome,
      if (aprovadorId != null) 'aprovadorId': aprovadorId,
      if (aprovadorNome != null) 'aprovadorNome': aprovadorNome,
      if (dataAprovacao != null) 'dataAprovacao': dataAprovacao,
      if (motivoRejeicao != null) 'motivoRejeicao': motivoRejeicao,
    };
  }

  factory Reutilizacao.fromMap(Map<String, dynamic> map, [String? id]) {
    return Reutilizacao(
      id: id ?? (map['id'] as String? ?? ''),
      dispositivoId: map['dispositivoId'] as String? ?? '',
      data: map['data'] as String? ?? '',
      codigoPeca: map['codigoPeca'] as String? ?? '',
      descricaoPeca: map['descricaoPeca'] as String? ?? '',
      produtoId: map['produtoId'] as String? ?? '',
      pesoPeca: (map['pesoPeca'] as num?)?.toDouble() ?? 0.0,
      hardSaving: (map['hardSaving'] as num?)?.toDouble() ?? 0.0,
      responsavel: map['responsavel'] as String? ?? '',
      numeroOs: map['numeroOs'] as String? ?? '',
      descricaoAlteracao: map['descricaoAlteracao'] as String? ?? '',
      dataCriacao: map['dataCriacao'] as String?,
      status: map['status'] as String?,
      solicitanteId: map['solicitanteId'] as String?,
      solicitanteNome: map['solicitanteNome'] as String?,
      aprovadorId: map['aprovadorId'] as String?,
      aprovadorNome: map['aprovadorNome'] as String?,
      dataAprovacao: map['dataAprovacao'] as String?,
      motivoRejeicao: map['motivoRejeicao'] as String?,
    );
  }
}

