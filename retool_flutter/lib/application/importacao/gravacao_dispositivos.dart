import 'dart:convert';
import 'dart:math';
import '../../domain/entities/dispositivo.dart';

const int tamanhoLoteDispositivos = 500;
const int tamanhoPaginaLeitura = 1000;

const Set<String> _camposIgnoradosNaComparacao = {'id', 'dataCriacao', 'chaveCD'};

String _comparavel(dynamic valor) {
  if (valor == null) return '';
  if (valor is List) {
    return valor.isEmpty ? '' : jsonEncode(valor.map((v) => v?.toString() ?? '').toList());
  }
  if (valor is Map) return jsonEncode(valor);
  return valor.toString();
}

Map<String, dynamic> dadosParaGravar(
  Dispositivo disp,
  bool existente,
  String id,
  String agora,
) {
  final chaveCD = chaveCodigoDispositivo(disp.codigo, disp.nome);
  final map = disp.toMap();
  map['chaveCD'] = chaveCD;

  if (existente) {
    for (final campo in camposImagemDispositivo) {
      if (map[campo] == null || (map[campo] as String).isEmpty) {
        map.remove(campo);
      }
    }
    return map;
  }

  map['id'] = id;
  map['dataCriacao'] = agora;
  return map;
}

bool alteraDocumento(Map<String, dynamic> dados, Map<String, dynamic> atual) {
  for (final campo in dados.keys) {
    if (_camposIgnoradosNaComparacao.contains(campo)) continue;
    if (_comparavel(dados[campo]) != _comparavel(atual[campo])) return true;
  }
  return false;
}

class OperacaoGravacao {
  final String id;
  Map<String, dynamic> dados;
  final bool novo;
  int registros;

  OperacaoGravacao({
    required this.id,
    required this.dados,
    required this.novo,
    required this.registros,
  });
}

class PlanoGravacao {
  final List<OperacaoGravacao> operacoes;
  final int ignoradosSemAlteracao;
  final int registrosAGravar;

  const PlanoGravacao({
    required this.operacoes,
    required this.ignoradosSemAlteracao,
    required this.registrosAGravar,
  });
}

PlanoGravacao planejarGravacao(
  List<Dispositivo> novos,
  Iterable<Dispositivo> existentes,
  String Function() gerarId, [
  String? agora,
]) {
  final moment = agora ?? DateTime.now().toIso8601String();
  final idPorChave = <String, String>{};
  final estado = <String, Map<String, dynamic>>{};

  for (final d in existentes) {
    final chave = chaveCodigoDispositivo(d.codigo, d.nome);
    if (!idPorChave.containsKey(chave)) {
      idPorChave[chave] = d.id;
    }
    estado[d.id] = d.toMap();
  }

  final operacoes = <String, OperacaoGravacao>{};
  int ignoradosSemAlteracao = 0;
  int registrosAGravar = 0;

  for (final disp in novos) {
    final chave = chaveCodigoDispositivo(disp.codigo, disp.nome);
    final existenteId = idPorChave[chave];
    final id = existenteId ?? gerarId();
    if (existenteId == null) {
      idPorChave[chave] = id;
    }

    final op = operacoes[id];
    final jaExistia = existenteId != null && (op == null || !op.novo);
    final dados = dadosParaGravar(disp, existenteId != null, id, moment);
    final atual = estado[id];

    if (atual != null && !alteraDocumento(dados, atual)) {
      ignoradosSemAlteracao++;
      continue;
    }
    registrosAGravar++;

    if (op != null) {
      op.dados.addAll(dados);
      if (op.novo) {
        op.dados['id'] = id;
        op.dados['dataCriacao'] = moment;
      }
      op.registros++;
    } else {
      operacoes[id] = OperacaoGravacao(
        id: id,
        dados: dados,
        novo: !jaExistia,
        registros: 1,
      );
    }
    estado[id] = {...(atual ?? {}), ...dados};
  }

  return PlanoGravacao(
    operacoes: operacoes.values.toList(),
    ignoradosSemAlteracao: ignoradosSemAlteracao,
    registrosAGravar: registrosAGravar,
  );
}

List<List<T>> emLotes<T>(List<T> itens, [int tamanho = tamanhoLoteDispositivos]) {
  final out = <List<T>>[];
  for (var i = 0; i < itens.length; i += tamanho) {
    out.add(itens.sublist(i, min(i + tamanho, itens.length)));
  }
  return out;
}

bool ehErroDeCota(dynamic erro) {
  if (erro == null) return false;
  final str = erro.toString().toLowerCase();
  return str.contains('resource-exhausted') ||
      str.contains('resource_exhausted') ||
      str.contains('quota exceeded');
}

class EstimativaGravacao {
  final int novos;
  final int alterados;
  final int semAlteracao;

  const EstimativaGravacao({
    required this.novos,
    required this.alterados,
    required this.semAlteracao,
  });
}

EstimativaGravacao estimarGravacao(List<Dispositivo> novos, List<Dispositivo> existentes) {
  int seq = 0;
  final plano = planejarGravacao(novos, existentes, () => '__estimativa-${seq++}', '');
  int novosDocs = 0;
  int alterados = 0;
  for (final op of plano.operacoes) {
    if (op.novo) {
      novosDocs += op.registros;
    } else {
      alterados += op.registros;
    }
  }
  return EstimativaGravacao(
    novos: novosDocs,
    alterados: alterados,
    semAlteracao: plano.ignoradosSemAlteracao,
  );
}

