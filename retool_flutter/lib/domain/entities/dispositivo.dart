import 'dart:convert';
import 'file_attachment.dart';

class Dispositivo {
  final String id;
  final String? nome;
  final String? codigo;
  final String? categoriaId;
  final String? peso;
  final String? familiaId;
  final String? descricao;
  final String? observacoes;
  final String? produtoId;
  final List<String>? palavrasChave;
  final String? imagemPeca;
  final String? imagemDispositivo;
  final List<FileAttachment>? anexos;
  final String? dataCriacao;
  final bool? ativo;
  final String? chaveCD;

  const Dispositivo({
    required this.id,
    this.nome,
    this.codigo,
    this.categoriaId,
    this.peso,
    this.familiaId,
    this.descricao,
    this.observacoes,
    this.produtoId,
    this.palavrasChave,
    this.imagemPeca,
    this.imagemDispositivo,
    this.anexos,
    this.dataCriacao,
    this.ativo,
    this.chaveCD,
  });

  Dispositivo copyWith({
    String? id,
    String? nome,
    String? codigo,
    String? categoriaId,
    String? peso,
    String? familiaId,
    String? descricao,
    String? observacoes,
    String? produtoId,
    List<String>? palavrasChave,
    String? imagemPeca,
    String? imagemDispositivo,
    List<FileAttachment>? anexos,
    String? dataCriacao,
    bool? ativo,
    String? chaveCD,
  }) {
    return Dispositivo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      codigo: codigo ?? this.codigo,
      categoriaId: categoriaId ?? this.categoriaId,
      peso: peso ?? this.peso,
      familiaId: familiaId ?? this.familiaId,
      descricao: descricao ?? this.descricao,
      observacoes: observacoes ?? this.observacoes,
      produtoId: produtoId ?? this.produtoId,
      palavrasChave: palavrasChave ?? this.palavrasChave,
      imagemPeca: imagemPeca ?? this.imagemPeca,
      imagemDispositivo: imagemDispositivo ?? this.imagemDispositivo,
      anexos: anexos ?? this.anexos,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ativo: ativo ?? this.ativo,
      chaveCD: chaveCD ?? this.chaveCD,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (nome != null) 'nome': nome,
      if (codigo != null) 'codigo': codigo,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (peso != null) 'peso': peso,
      if (familiaId != null) 'familiaId': familiaId,
      if (descricao != null) 'descricao': descricao,
      if (observacoes != null) 'observacoes': observacoes,
      if (produtoId != null) 'produtoId': produtoId,
      if (palavrasChave != null) 'palavrasChave': palavrasChave,
      if (imagemPeca != null) 'imagemPeca': imagemPeca,
      if (imagemDispositivo != null) 'imagemDispositivo': imagemDispositivo,
      if (anexos != null) 'anexos': anexos!.map((a) => a.toMap()).toList(),
      if (dataCriacao != null) 'dataCriacao': dataCriacao,
      if (ativo != null) 'ativo': ativo,
      if (chaveCD != null) 'chaveCD': chaveCD,
    };
  }

  factory Dispositivo.fromMap(Map<String, dynamic> map, [String? id]) {
    return Dispositivo(
      id: id ?? (map['id'] as String? ?? ''),
      nome: map['nome'] as String?,
      codigo: map['codigo'] as String?,
      categoriaId: map['categoriaId'] as String?,
      peso: map['peso'] as String?,
      familiaId: map['familiaId'] as String?,
      descricao: map['descricao'] as String?,
      observacoes: map['observacoes'] as String?,
      produtoId: map['produtoId'] as String?,
      palavrasChave: (map['palavrasChave'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      imagemPeca: map['imagemPeca'] as String?,
      imagemDispositivo: map['imagemDispositivo'] as String?,
      anexos: (map['anexos'] as List<dynamic>?)
          ?.map((e) => FileAttachment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      dataCriacao: map['dataCriacao'] as String?,
      ativo: map['ativo'] as bool?,
      chaveCD: map['chaveCD'] as String?,
    );
  }
}

typedef CampoImagemDispositivo = String;
const List<CampoImagemDispositivo> camposImagemDispositivo = ['imagemPeca', 'imagemDispositivo'];
const List<CampoImagemDispositivo> camposImagemPropagados = ['imagemDispositivo'];

/// Caracteres invisíveis comuns em planilhas: zero-width (U+200B–U+200D),
/// BOM/ZWNBSP (U+FEFF), soft hyphen (U+00AD), word joiner (U+2060) e controles C0/C1.
final RegExp regexInvisiveis = RegExp(
  r'[\u200B-\u200D\uFEFF\u00AD\u2060\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]',
);

/// Normaliza um valor de Código ou Dispositivo para compor a chave de unicidade.
String normalizarValorChave(dynamic valor) {
  if (valor == null) return '';
  return valor
      .toString()
      .replaceAll(regexInvisiveis, '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
}

/// Normaliza o Nº dispositivo (campo `nome`) usado como chave da linha de imagens.
String normalizarNumeroDispositivo(String? nome) {
  return normalizarValorChave(nome);
}

/// Identidade lógica de um dispositivo importado: Código + Dispositivo (`nome`).
String chaveCodigoDispositivo(dynamic codigo, dynamic nome) {
  return jsonEncode([normalizarValorChave(codigo), normalizarValorChave(nome)]);
}

class PatchPropagacaoImagem {
  final String id;
  final Map<String, dynamic> patch;
  final String origem; // 'propagacao' | 'heranca'
  final Map<String, String>? substitui;

  PatchPropagacaoImagem({
    required this.id,
    required this.patch,
    required this.origem,
    this.substitui,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchPropagacaoImagem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          origem == other.origem &&
          jsonEncode(patch) == jsonEncode(other.patch) &&
          jsonEncode(substitui ?? {}) == jsonEncode(other.substitui ?? {});

  @override
  int get hashCode => id.hashCode ^ origem.hashCode;
}

/// Imagem que representa a linha num campo: a mais usada entre os
/// dispositivos informados (empate: a do dispositivo de menor id).
String? imagemDaLinha(Iterable<Dispositivo> dispositivos, CampoImagemDispositivo campo) {
  final usos = <String, _UsoImagem>{};
  for (final d in dispositivos) {
    final url = campo == 'imagemPeca' ? d.imagemPeca : d.imagemDispositivo;
    if (url == null || url.isEmpty) continue;
    final id = d.id;
    final u = usos[url];
    if (u != null) {
      u.n++;
      if (id.compareTo(u.primeiroId) < 0) {
        u.primeiroId = id;
      }
    } else {
      usos[url] = _UsoImagem(1, id);
    }
  }

  String? melhorUrl;
  _UsoImagem? melhorUso;
  for (final entry in usos.entries) {
    final u = entry.value;
    if (melhorUso == null ||
        u.n > melhorUso.n ||
        (u.n == melhorUso.n && u.primeiroId.compareTo(melhorUso.primeiroId) < 0)) {
      melhorUrl = entry.key;
      melhorUso = u;
    }
  }
  return melhorUrl;
}

class _UsoImagem {
  int n;
  String primeiroId;
  _UsoImagem(this.n, this.primeiroId);
}

/// Propagação automática da imagem do dispositivo por Nº dispositivo (`nome`).
List<PatchPropagacaoImagem> calcularPropagacaoImagens(
  List<Dispositivo> linha,
  String origemId,
  String? numeroOrigem,
  Map<String, dynamic> payload,
  bool isNew, [
  Map<String, dynamic> anteriores = const {},
]) {
  final chave = normalizarNumeroDispositivo(numeroOrigem);
  if (chave.isEmpty) return [];

  final outros = linha.where((d) => d.id != origemId && normalizarNumeroDispositivo(d.nome) == chave).toList();
  final porAlvo = <String, PatchPropagacaoImagem>{};

  void incluir(String id, String campo, String url, String origem, [String? substitui]) {
    final p = porAlvo[id] ?? PatchPropagacaoImagem(id: id, patch: {}, origem: origem, substitui: {});
    p.patch[campo] = url;
    if (substitui != null) {
      final sub = Map<String, String>.from(p.substitui ?? {});
      sub[campo] = substitui;
      porAlvo[id] = PatchPropagacaoImagem(id: id, patch: p.patch, origem: origem, substitui: sub);
    } else {
      porAlvo[id] = p;
    }
  }

  for (final campo in camposImagemPropagados) {
    final novaImagem = payload[campo] as String?;

    if (novaImagem != null && novaImagem.isNotEmpty) {
      final antiga = (anteriores[campo] != null && anteriores[campo] != novaImagem)
          ? anteriores[campo] as String
          : null;
      for (final alvo in outros) {
        final atual = campo == 'imagemPeca' ? alvo.imagemPeca : alvo.imagemDispositivo;
        if (atual == null || atual.isEmpty) {
          incluir(alvo.id, campo, novaImagem, 'propagacao');
        } else if (antiga != null && atual == antiga) {
          incluir(alvo.id, campo, novaImagem, 'propagacao', antiga);
        }
      }
    } else if (isNew) {
      final daLinha = imagemDaLinha(outros, campo);
      if (daLinha != null && daLinha.isNotEmpty) {
        incluir(origemId, campo, daLinha, 'heranca');
      }
    }
  }

  return porAlvo.values.toList();
}

Map<String, dynamic>? patchAindaAplicavel(
  Dispositivo? atual,
  PatchPropagacaoImagem p,
  String numeroNormalizado,
) {
  if (atual == null || normalizarNumeroDispositivo(atual.nome) != numeroNormalizado) {
    return null;
  }
  final aplicavel = <String, dynamic>{};
  for (final campo in camposImagemPropagados) {
    final nova = p.patch[campo] as String?;
    if (nova == null || nova.isEmpty) continue;
    final valor = campo == 'imagemPeca' ? atual.imagemPeca : atual.imagemDispositivo;
    if (valor == nova) continue;
    if (valor == null ||
        valor.isEmpty ||
        (p.substitui != null && valor == p.substitui![campo])) {
      aplicavel[campo] = nova;
    }
  }
  return aplicavel.isNotEmpty ? aplicavel : null;
}

int herdarImagensDaLinha(List<Dispositivo> novos, Iterable<Dispositivo> fontes) {
  final porLinha = <String, List<Dispositivo>>{};
  for (final f in fontes) {
    final temImagem = (f.imagemDispositivo != null && f.imagemDispositivo!.isNotEmpty);
    if (!temImagem) continue;
    final chave = normalizarNumeroDispositivo(f.nome);
    if (chave.isEmpty) continue;
    porLinha.putIfAbsent(chave, () => []).add(f);
  }

  int herdaram = 0;
  for (var i = 0; i < novos.length; i++) {
    final novo = novos[i];
    final chave = normalizarNumeroDispositivo(novo.nome);
    final linha = porLinha[chave];
    if (linha == null) continue;
    bool mudou = false;
    String? novaImagemDisp = novo.imagemDispositivo;
    for (final campo in camposImagemPropagados) {
      if (campo == 'imagemDispositivo' && (novaImagemDisp != null && novaImagemDisp.isNotEmpty)) {
        continue;
      }
      final url = imagemDaLinha(linha, campo);
      if (url != null && url.isNotEmpty) {
        novaImagemDisp = url;
        mudou = true;
      }
    }
    if (mudou) {
      novos[i] = novo.copyWith(imagemDispositivo: novaImagemDisp);
      herdaram++;
    }
  }
  return herdaram;
}

bool ehCaminhoDeImagem(String caminhoStorage) {
  return RegExp(r'/(imagem_peca|imagem_dispositivo)/').hasMatch(caminhoStorage);
}

String urlSemToken(String url) {
  final i = url.indexOf('?');
  return i < 0 ? url : url.substring(0, i);
}

class GrupoDuplicado {
  final String chave;
  final String? codigo;
  final String? nome;
  final Dispositivo manter;
  final List<Dispositivo> remover;
  final List<Dispositivo> revisar;

  const GrupoDuplicado({
    required this.chave,
    this.codigo,
    this.nome,
    required this.manter,
    required this.remover,
    required this.revisar,
  });
}

class PlanoLimpezaDuplicados {
  final List<GrupoDuplicado> grupos;
  final int totalDocumentos;
  final int combinacoesDistintas;
  final int totalRemover;
  final int totalRevisar;

  const PlanoLimpezaDuplicados({
    required this.grupos,
    required this.totalDocumentos,
    required this.combinacoesDistintas,
    required this.totalRemover,
    required this.totalRevisar,
  });
}

PlanoLimpezaDuplicados planejarLimpezaDuplicados(
  List<Dispositivo> dispositivos,
  Set<String> idsComReutilizacao,
) {
  bool temVinculo(Dispositivo d) =>
      idsComReutilizacao.contains(d.id) ||
      (d.imagemPeca != null && d.imagemPeca!.isNotEmpty) ||
      (d.imagemDispositivo != null && d.imagemDispositivo!.isNotEmpty) ||
      (d.anexos != null && d.anexos!.isNotEmpty) ||
      (d.observacoes != null && d.observacoes!.trim().isNotEmpty);

  final porChave = <String, List<Dispositivo>>{};
  for (final d in dispositivos) {
    final chave = chaveCodigoDispositivo(d.codigo, d.nome);
    porChave.putIfAbsent(chave, () => []).add(d);
  }

  final grupos = <GrupoDuplicado>[];
  for (final entry in porChave.entries) {
    final chave = entry.key;
    final lista = entry.value;
    if (lista.length < 2) continue;

    final ordenada = List<Dispositivo>.from(lista)
      ..sort((a, b) {
        final cmpData = (a.dataCriacao ?? '').compareTo(b.dataCriacao ?? '');
        if (cmpData != 0) return cmpData;
        return a.id.compareTo(b.id);
      });

    final manter = ordenada.firstWhere(temVinculo, orElse: () => ordenada.first);
    final outros = ordenada.where((d) => d != manter).toList();

    grupos.add(GrupoDuplicado(
      chave: chave,
      codigo: manter.codigo,
      nome: manter.nome,
      manter: manter,
      remover: outros.where((d) => !temVinculo(d)).toList(),
      revisar: outros.where(temVinculo).toList(),
    ));
  }

  return PlanoLimpezaDuplicados(
    grupos: grupos,
    totalDocumentos: dispositivos.length,
    combinacoesDistintas: porChave.length,
    totalRemover: grupos.fold(0, (acc, g) => acc + g.remover.length),
    totalRevisar: grupos.fold(0, (acc, g) => acc + g.revisar.length),
  );
}

