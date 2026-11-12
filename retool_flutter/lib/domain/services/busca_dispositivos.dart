import 'dart:math';
import '../entities/dispositivo.dart';

class EntradaIndice {
  final String id;
  final String codigo;
  final String nome;
  final String descricao;
  final String categoriaId;
  final String familiaId;
  final String produtoId;
  final String peso;
  final List<String> palavrasChave;
  final bool ativo;

  const EntradaIndice({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.descricao,
    required this.categoriaId,
    required this.familiaId,
    required this.produtoId,
    required this.peso,
    required this.palavrasChave,
    required this.ativo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntradaIndice &&
          id == other.id &&
          codigo == other.codigo &&
          nome == other.nome &&
          descricao == other.descricao &&
          categoriaId == other.categoriaId &&
          familiaId == other.familiaId &&
          produtoId == other.produtoId &&
          peso == other.peso &&
          ativo == other.ativo &&
          palavrasChave.join(',') == other.palavrasChave.join(',');

  @override
  int get hashCode => id.hashCode;
}

const String sep = '\u001f';
const int maxCampo = 2000;
const String sepTag = '\u001e';

String serializarEntrada(Dispositivo d) {
  final campos = [
    d.codigo ?? '',
    d.nome ?? '',
    d.descricao ?? '',
    d.categoriaId ?? '',
    d.familiaId ?? '',
    d.produtoId ?? '',
    d.peso ?? '',
    (d.palavrasChave ?? []).join(sepTag),
    d.ativo == false ? '0' : '1',
  ];

  return campos.map((v) {
    var s = v.replaceAll(sep, ' ');
    if (s.length > maxCampo) s = s.substring(0, maxCampo);
    return s;
  }).join(sep);
}

EntradaIndice desserializarEntrada(String id, String valor) {
  final p = valor.split(sep);
  return EntradaIndice(
    id: id,
    codigo: p.isNotEmpty ? p[0] : '',
    nome: p.length > 1 ? p[1] : '',
    descricao: p.length > 2 ? p[2] : '',
    categoriaId: p.length > 3 ? p[3] : '',
    familiaId: p.length > 4 ? p[4] : '',
    produtoId: p.length > 5 ? p[5] : '',
    peso: p.length > 6 ? p[6] : '',
    palavrasChave: (p.length > 7 && p[7].isNotEmpty) ? p[7].split(sepTag) : [],
    ativo: p.length > 8 ? p[8] != '0' : true,
  );
}

/// Normalização usada pela busca desde a primeira versão do ReTool
/// (Home e lista de dispositivos): sem acento, minúsculas, vírgula vira
/// ponto e "avula" vira "avola".
String normalizarBusca(String? str) {
  if (str == null || str.isEmpty) return '';
  var res = str
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .toLowerCase();

  // Caso contenha acentos sem decompor, remove mapeando explicitamente
  const comAcento = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucn';
  for (var i = 0; i < comAcento.length; i++) {
    res = res.replaceAll(comAcento[i], semAcento[i]);
  }

  res = res.replaceAll(',', '.');
  if (res.contains('avula')) {
    res = res.replaceAll('avula', 'avola');
  }
  return res;
}

int contarNumerosDispositivoUnicos(List<EntradaIndice> entradas) {
  final vistos = <String>{};
  for (final e in entradas) {
    final n = normalizarNumeroDispositivo(e.nome);
    if (n.isNotEmpty) vistos.add(n);
  }
  return vistos.size;
}

String normalizarCodigoLinha(String? codigo) => (codigo ?? '').trim().toLowerCase();

class NomesClassificacao {
  final Map<String, String> categorias;
  final Map<String, String> familias;
  final Map<String, String> produtos;

  const NomesClassificacao({
    required this.categorias,
    required this.familias,
    required this.produtos,
  });
}

class EntradaPreparada {
  final EntradaIndice entrada;
  final String texto;
  final String processo;
  final String textoHome;
  final String codigo;
  final String descricao;

  const EntradaPreparada({
    required this.entrada,
    required this.texto,
    required this.processo,
    required this.textoHome,
    required this.codigo,
    required this.descricao,
  });
}

const String _j = '\u0001';

List<EntradaPreparada> prepararEntradas(List<EntradaIndice> entradas, NomesClassificacao nomes) {
  final out = List<EntradaPreparada>.filled(
    entradas.length,
    const EntradaPreparada(
      entrada: EntradaIndice(
        id: '',
        codigo: '',
        nome: '',
        descricao: '',
        categoriaId: '',
        familiaId: '',
        produtoId: '',
        peso: '',
        palavrasChave: [],
        ativo: true,
      ),
      texto: '',
      processo: '',
      textoHome: '',
      codigo: '',
      descricao: '',
    ),
  );

  for (var i = 0; i < entradas.length; i++) {
    final e = entradas[i];
    final tags = e.palavrasChave.map(normalizarBusca).toList();
    final nome = normalizarBusca(e.nome);
    final descricao = normalizarBusca(e.descricao);
    final codigo = normalizarBusca(e.codigo);
    final base = [
      nome,
      codigo,
      descricao,
      normalizarBusca(nomes.familias[e.familiaId]),
      normalizarBusca(nomes.produtos[e.produtoId]),
      normalizarBusca(nomes.categorias[e.categoriaId]),
      ...tags,
    ].join(_j);

    out[i] = EntradaPreparada(
      entrada: e,
      texto: base,
      processo: [descricao, nome, ...tags].join(_j),
      textoHome: '$base$_j${normalizarBusca(e.peso)}',
      codigo: codigo,
      descricao: descricao.replaceAll(RegExp(r'\s+'), ' '),
    );
  }
  return out;
}

class FiltroBusca {
  final String? texto;
  final String? categoriaId;
  final String? familiaId;
  final String? produtoId;
  final String? processo;
  final String? codigo;
  final String? descricao;
  final bool? incluirPeso;

  const FiltroBusca({
    this.texto,
    this.categoriaId,
    this.familiaId,
    this.produtoId,
    this.processo,
    this.codigo,
    this.descricao,
    this.incluirPeso,
  });
}

List<EntradaIndice> filtrarEntradas(
  List<EntradaPreparada> preparadas,
  FiltroBusca filtro, [
  int limite = 1000000000,
]) {
  final q = normalizarBusca(filtro.texto).replaceAll(RegExp(r'\s+'), ' ').trim();
  final proc = normalizarBusca(filtro.processo).trim();
  final cod = normalizarBusca(filtro.codigo).trim();
  final desc = normalizarBusca(filtro.descricao).replaceAll(RegExp(r'\s+'), ' ').trim();
  final cat = filtro.categoriaId ?? '';
  final fam = filtro.familiaId ?? '';
  final prod = filtro.produtoId ?? '';
  final incluirPeso = filtro.incluirPeso ?? false;

  final out = <EntradaIndice>[];
  for (var i = 0; i < preparadas.length; i++) {
    final p = preparadas[i];
    if (cat.isNotEmpty && p.entrada.categoriaId != cat) continue;
    if (fam.isNotEmpty && p.entrada.familiaId != fam) continue;
    if (prod.isNotEmpty && p.entrada.produtoId != prod) continue;
    if (q.isNotEmpty) {
      final campoTexto = incluirPeso ? p.textoHome : p.texto;
      if (!campoTexto.contains(q)) continue;
    }
    if (proc.isNotEmpty && !p.processo.contains(proc)) continue;
    if (cod.isNotEmpty && !p.codigo.contains(cod)) continue;
    if (desc.isNotEmpty && !p.descricao.contains(desc)) continue;

    out.add(p.entrada);
    if (out.length >= limite) break;
  }
  return out;
}

/// Shard (parte) do catálogo de um documento: hash estável FNV-1a de 32 bits do id.
int parteDoId(String id, int partes) {
  int h = 2166136261;
  for (var i = 0; i < id.length; i++) {
    h ^= id.codeUnitAt(i);
    // Math.imul(h, 16777619) em 32 bits sem sinal
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  return h % partes;
}

const int itensPorParte = 750;
const int maxPartes = 200;

int partesParaTotal(int total) {
  return min(maxPartes, max(4, (total / itensPorParte).ceil()));
}

double bytesDoItem(String id, String valor) => id.length + valor.length * 1.2 + 16;

