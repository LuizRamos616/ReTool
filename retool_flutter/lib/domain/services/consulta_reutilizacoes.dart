import 'dart:math';
import '../entities/reutilizacao.dart';

enum ModoReutilizacoes { servidor, legado }

class ContagensProntidao {
  final int total;
  final int comStatusCanonico;
  final int comDataCriacao;

  const ContagensProntidao({
    required this.total,
    required this.comStatusCanonico,
    required this.comDataCriacao,
  });
}

ModoReutilizacoes decidirModoReutilizacoes(ContagensProntidao c) {
  return (c.comStatusCanonico == c.total && c.comDataCriacao == c.total)
      ? ModoReutilizacoes.servidor
      : ModoReutilizacoes.legado;
}

int documentosLegados(ContagensProntidao c) {
  return max(c.total - c.comStatusCanonico, max(c.total - c.comDataCriacao, 0));
}

class AlteracaoNormalizacao {
  final String? status;
  final String? dataCriacao;

  const AlteracaoNormalizacao({this.status, this.dataCriacao});
}

class ItemNormalizacao {
  final String id;
  final AlteracaoNormalizacao alteracoes;

  const ItemNormalizacao({required this.id, required this.alteracoes});
}

class PlanoNormalizacao {
  final List<ItemNormalizacao> itens;
  final int analisados;
  final int comStatusAlterado;
  final int comDataCriacaoAlterada;
  final int comDataCriacaoAtual;

  const PlanoNormalizacao({
    required this.itens,
    required this.analisados,
    required this.comStatusAlterado,
    required this.comDataCriacaoAlterada,
    required this.comDataCriacaoAtual,
  });
}

final RegExp _isoDia = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String? _paraIso(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor.toIso8601String();
  // Se for Timestamp do Firestore ou objeto com toDate
  if (valor is Map && valor.containsKey('toDate')) {
    try {
      final d = (valor['toDate'] as Function).call();
      if (d is DateTime) return d.toIso8601String();
    } catch (_) {}
  }
  if (valor is String && valor.trim().isNotEmpty) {
    final s = valor.trim();
    if (_isoDia.hasMatch(s)) {
      return '${s}T12:00:00.000Z';
    }
    final d = DateTime.tryParse(s);
    if (d != null) return d.toIso8601String();
  }
  if (valor is num && valor.isFinite) {
    final d = DateTime.fromMillisecondsSinceEpoch(valor.toInt());
    return d.toIso8601String();
  }
  return null;
}

class DataCriacaoDerivada {
  final String valor;
  final bool atual;

  const DataCriacaoDerivada({required this.valor, required this.atual});
}

DataCriacaoDerivada derivarDataCriacao(Map<String, dynamic> doc, DateTime agora) {
  final derivada = _paraIso(doc['dataCriacao']) ?? _paraIso(doc['data']);
  return derivada != null
      ? DataCriacaoDerivada(valor: derivada, atual: false)
      : DataCriacaoDerivada(valor: agora.toIso8601String(), atual: true);
}

class DocParaNormalizar {
  final String id;
  final Map<String, dynamic> dados;

  const DocParaNormalizar({required this.id, required this.dados});
}

PlanoNormalizacao planejarNormalizacaoReutilizacoes(
  List<DocParaNormalizar> docs, [
  DateTime? agora,
]) {
  final moment = agora ?? DateTime.now();
  final itens = <ItemNormalizacao>[];
  int comStatusAlterado = 0;
  int comDataCriacaoAlterada = 0;
  int comDataCriacaoAtual = 0;

  for (final doc in docs) {
    final dados = doc.dados;
    String? novoStatus;
    String? novaDataCriacao;

    final status = dados['status'];
    if (status is! String || !ReutilizacaoStatuses.todos.contains(status)) {
      novoStatus = normalizarStatusReutilizacao(status is String ? status : null);
      comStatusAlterado++;
    }

    final dc = dados['dataCriacao'];
    if (dc is! String || dc.trim().isEmpty) {
      final derivada = derivarDataCriacao(dados, moment);
      novaDataCriacao = derivada.valor;
      comDataCriacaoAlterada++;
      if (derivada.atual) comDataCriacaoAtual++;
    }

    if (novoStatus != null || novaDataCriacao != null) {
      itens.add(ItemNormalizacao(
        id: doc.id,
        alteracoes: AlteracaoNormalizacao(status: novoStatus, dataCriacao: novaDataCriacao),
      ));
    }
  }

  return PlanoNormalizacao(
    itens: itens,
    analisados: docs.length,
    comStatusAlterado: comStatusAlterado,
    comDataCriacaoAlterada: comDataCriacaoAlterada,
    comDataCriacaoAtual: comDataCriacaoAtual,
  );
}

List<List<T>> emLotes<T>(List<T> itens, [int tamanho = 500]) {
  final out = <List<T>>[];
  for (var i = 0; i < itens.length; i += tamanho) {
    out.add(itens.sublist(i, min(i + tamanho, itens.length)));
  }
  return out;
}

