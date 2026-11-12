import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as x;
import '../../domain/entities/dispositivo.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/familia.dart';
import '../../domain/entities/produto.dart';

class CelulaPlanilha {
  final String texto;
  final double? numero;

  const CelulaPlanilha({required this.texto, this.numero});
}

class AbaPlanilha {
  final String nome;
  final List<String> cabecalhos;
  final List<List<CelulaPlanilha>> linhas;

  const AbaPlanilha({
    required this.nome,
    required this.cabecalhos,
    required this.linhas,
  });
}

class ResumoAba {
  final String nome;
  int linhas;
  final String? colunaCodigo;
  final String? colunaDispositivo;
  final bool ignorada;

  ResumoAba({
    required this.nome,
    required this.linhas,
    this.colunaCodigo,
    this.colunaDispositivo,
    required this.ignorada,
  });
}

class ResumoImportacao {
  int linhasLidas;
  int combinacoesUnicas;
  int duplicadasRemovidas;
  int linhasSemChave;
  int linhasSemCodigo;
  int linhasSemDispositivo;
  final List<ResumoAba> abas;
  final List<String> avisos;

  ResumoImportacao({
    this.linhasLidas = 0,
    this.combinacoesUnicas = 0,
    this.duplicadasRemovidas = 0,
    this.linhasSemChave = 0,
    this.linhasSemCodigo = 0,
    this.linhasSemDispositivo = 0,
    required this.abas,
    required this.avisos,
  });
}

class ResultadoProcessamento {
  final List<Dispositivo> dispositivos;
  final List<String> novasCategorias;
  final List<String> novasFamilias;
  final List<String> novosProdutos;
  final ResumoImportacao resumo;

  const ResultadoProcessamento({
    required this.dispositivos,
    required this.novasCategorias,
    required this.novasFamilias,
    required this.novosProdutos,
    required this.resumo,
  });
}

class ProgressoPlanilha {
  final String etapa; // 'lendo-arquivo' | 'convertendo' | 'processando'
  final int feitos;
  final int total;
  final String? aba;

  const ProgressoPlanilha({
    required this.etapa,
    required this.feitos,
    required this.total,
    this.aba,
  });
}

typedef OuvinteProgressoPlanilha = void Function(ProgressoPlanilha p);

const int intervaloProgressoLinhas = 5000;

class ContextoProcessamento {
  final List<Categoria> categorias;
  final List<Familia> familias;
  final List<Produto> produtos;
  final String? defaultCategoriaId;

  const ContextoProcessamento({
    required this.categorias,
    required this.familias,
    required this.produtos,
    this.defaultCategoriaId,
  });
}

String decodificarTexto(List<int> bytes) {
  try {
    return const Utf8Decoder(allowMalformed: false).convert(bytes).replaceFirst('\uFEFF', '');
  } catch (_) {
    return latin1.decode(bytes);
  }
}

bool ehCsv(String nomeArquivo) {
  return RegExp(r'\.(csv|txt)$', caseSensitive: false).hasMatch(nomeArquivo);
}

List<AbaPlanilha> lerPlanilhaBytes(
  List<int> bytes,
  String nomeArquivo, [
  OuvinteProgressoPlanilha? onProgresso,
]) {
  onProgresso?.call(const ProgressoPlanilha(etapa: 'lendo-arquivo', feitos: 0, total: 0));

  if (ehCsv(nomeArquivo)) {
    final texto = decodificarTexto(bytes);
    // Detecta delimitador: vírgula, ponto-e-vírgula ou tab
    String delimitador = ',';
    final primeiraLinha = texto.split('\n').first;
    if (primeiraLinha.contains(';') && !primeiraLinha.contains(',')) {
      delimitador = ';';
    } else if (primeiraLinha.contains('\t')) {
      delimitador = '\t';
    }

    final csvConverter = CsvToListConverter(fieldDelimiter: delimitador, shouldParseNumbers: false);
    final linhasBrutas = csvConverter.convert(texto);
    if (linhasBrutas.isEmpty) {
      return [const AbaPlanilha(nome: 'CSV', cabecalhos: [], linhas: [])];
    }

    final cabecalhos = linhasBrutas.first.map((c) => c?.toString() ?? '').toList();
    final linhas = <List<CelulaPlanilha>>[];
    for (var i = 1; i < linhasBrutas.length; i++) {
      final r = linhasBrutas[i];
      linhas.add(r.map((c) {
        final s = c?.toString() ?? '';
        final n = double.tryParse(s.replaceAll(',', '.'));
        return CelulaPlanilha(texto: s, numero: n);
      }).toList());
    }

    onProgresso?.call(ProgressoPlanilha(etapa: 'convertendo', feitos: linhas.length, total: linhas.length, aba: 'CSV'));
    return [AbaPlanilha(nome: 'CSV', cabecalhos: cabecalhos, linhas: linhas)];
  }

  // Arquivo Excel .xlsx
  final excel = x.Excel.decodeBytes(bytes);
  final abas = <AbaPlanilha>[];

  for (final sheetName in excel.tables.keys) {
    final table = excel.tables[sheetName]!;
    if (table.rows.isEmpty) {
      abas.add(AbaPlanilha(nome: sheetName, cabecalhos: [], linhas: []));
      continue;
    }

    final cabecalhos = table.rows.first.map((cell) => cell?.value?.toString() ?? '').toList();
    final linhas = <List<CelulaPlanilha>>[];

    for (var r = 1; r < table.rows.length; r++) {
      final row = table.rows[r];
      final celulas = row.map((cell) {
        if (cell == null || cell.value == null) {
          return const CelulaPlanilha(texto: '');
        }
        final val = cell.value;
        if (val is num) {
          return CelulaPlanilha(texto: val.toString(), numero: val.toDouble());
        }
        final str = val.toString();
        final parsedNum = double.tryParse(str.replaceAll(',', '.'));
        return CelulaPlanilha(texto: str, numero: parsedNum);
      }).toList();

      linhas.add(celulas);
      if (onProgresso != null && linhas.length % intervaloProgressoLinhas == 0) {
        onProgresso(ProgressoPlanilha(
          etapa: 'convertendo',
          feitos: linhas.length,
          total: table.rows.length - 1,
          aba: sheetName,
        ));
      }
    }

    onProgresso?.call(ProgressoPlanilha(
      etapa: 'convertendo',
      feitos: linhas.length,
      total: linhas.length,
      aba: sheetName,
    ));

    abas.add(AbaPlanilha(nome: sheetName, cabecalhos: cabecalhos, linhas: linhas));
  }

  return abas;
}

String normalizarCabecalho(String cabecalho) {
  var s = cabecalho
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .toLowerCase();

  const comAcento = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucn';
  for (var i = 0; i < comAcento.length; i++) {
    s = s.replaceAll(comAcento[i], semAcento[i]);
  }

  return s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

const Map<String, List<String>> colunasConfig = {
  'codigo': ['codigo', 'codigo da peca', 'codigo peca'],
  'nome': ['dispositivo', 'n dispositivo', 'nome'],
  'peso': ['peso', 'peso kg', 'peso dispositivo kg'],
  'familia': ['familia', 'familia do produto'],
  'produto': ['produto'],
  'categoria': ['categoria', 'tipo de dispositivo', 'tipo dispositivo', 'tipo'],
  'descricao': ['descricao', 'descricao da peca'],
  'palavrasChave': ['palavra chave', 'palavras chaves', 'palavras chave'],
};

Map<String, int> mapearColunas(List<String> cabecalhos) {
  final normalizados = cabecalhos.map(normalizarCabecalho).toList();
  final mapa = <String, int>{};

  for (final entry in colunasConfig.entries) {
    mapa[entry.key] = -1;
    for (final alias in entry.value) {
      final idx = normalizados.indexOf(alias);
      if (idx >= 0) {
        mapa[entry.key] = idx;
        break;
      }
    }
  }
  return mapa;
}

class _Resolvedor {
  final Map<String, String> _porNome = {};
  final Map<String, String> _novos = {};

  _Resolvedor(List<dynamic> existentes) {
    for (final e in existentes) {
      final nome = e.nome as String?;
      final id = e.id as String;
      if (nome != null && nome.isNotEmpty) {
        _porNome[nome.toLowerCase().trim()] = id;
      }
    }
  }

  String resolver(String nome) {
    final k = nome.toLowerCase().trim();
    final existente = _porNome[k];
    if (existente != null) return existente;
    if (!_novos.containsKey(k)) {
      _novos[k] = nome;
    }
    return _novos[k]!;
  }

  List<String> novos() => _novos.values.toList();
}

ResultadoProcessamento processarPlanilhaDispositivos(
  List<AbaPlanilha> abas,
  ContextoProcessamento ctx, [
  OuvinteProgressoPlanilha? onProgresso,
]) {
  final totalLinhas = abas.fold<int>(0, (acc, a) => acc + a.linhas.length);
  int percorridas = 0;

  final categorias = _Resolvedor(ctx.categorias);
  final familias = _Resolvedor(ctx.familias);
  final produtos = _Resolvedor(ctx.produtos);

  final porChave = <String, Dispositivo>{};
  final resumo = ResumoImportacao(abas: [], avisos: []);

  for (final aba in abas) {
    final col = mapearColunas(aba.cabecalhos);
    final colCodigo = col['codigo'] ?? -1;
    final colNome = col['nome'] ?? -1;
    final colPeso = col['peso'] ?? -1;
    final colFamilia = col['familia'] ?? -1;
    final colProduto = col['produto'] ?? -1;
    final colCategoria = col['categoria'] ?? -1;
    final colDescricao = col['descricao'] ?? -1;
    final colPalavras = col['palavrasChave'] ?? -1;

    final resumoAba = ResumoAba(
      nome: aba.nome,
      linhas: 0,
      colunaCodigo: colCodigo >= 0 ? aba.cabecalhos[colCodigo] : null,
      colunaDispositivo: colNome >= 0 ? aba.cabecalhos[colNome] : null,
      ignorada: colCodigo < 0 && colNome < 0,
    );
    resumo.abas.add(resumoAba);

    if (resumoAba.ignorada) {
      percorridas += aba.linhas.length;
      continue;
    }

    if (colCodigo < 0) {
      resumo.avisos.add('Aba "${aba.nome}": coluna Código não encontrada — os registros dessa aba ficarão sem Código.');
    }
    if (colNome < 0) {
      resumo.avisos.add('Aba "${aba.nome}": coluna Dispositivo não encontrada — os registros dessa aba ficarão sem Dispositivo.');
    }

    String valor(List<CelulaPlanilha> linha, int idx) {
      if (idx >= 0 && idx < linha.length) {
        return linha[idx].texto.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
      return '';
    }

    for (final linha in aba.linhas) {
      percorridas++;
      if (onProgresso != null && percorridas % intervaloProgressoLinhas == 0) {
        onProgresso(ProgressoPlanilha(
          etapa: 'processando',
          feitos: percorridas,
          total: totalLinhas,
          aba: aba.nome,
        ));
      }

      if (linha.every((c) => c.texto.trim().isEmpty)) continue;
      resumoAba.linhas++;
      resumo.linhasLidas++;

      final codigo = valor(linha, colCodigo);
      final nome = valor(linha, colNome);
      if (codigo.isEmpty && nome.isEmpty) {
        resumo.linhasSemChave++;
        continue;
      }
      if (codigo.isEmpty) resumo.linhasSemCodigo++;
      if (nome.isEmpty) resumo.linhasSemDispositivo++;

      final celulaPeso = (colPeso >= 0 && colPeso < linha.length) ? linha[colPeso] : null;
      final rawPeso = valor(linha, colPeso);
      final pesoConvertido = celulaPeso?.numero ??
          (rawPeso.isNotEmpty ? double.tryParse(rawPeso.replaceAll(',', '.')) ?? 0.0 : 0.0);

      final categoriaNome = valor(linha, colCategoria);
      final familiaNome = valor(linha, colFamilia);
      final produtoNome = valor(linha, colProduto);
      final palavrasRaw = valor(linha, colPalavras);

      final dispositivo = Dispositivo(
        id: '',
        familiaId: familiaNome.isNotEmpty ? familias.resolver(familiaNome) : '',
        produtoId: produtoNome.isNotEmpty ? produtos.resolver(produtoNome) : '',
        categoriaId: categoriaNome.isNotEmpty
            ? categorias.resolver(categoriaNome)
            : (ctx.defaultCategoriaId ?? ''),
        codigo: codigo,
        descricao: valor(linha, colDescricao),
        nome: nome,
        peso: pesoConvertido.isNaN || rawPeso.isEmpty ? '' : pesoConvertido.toString(),
        palavrasChave: palavrasRaw.isNotEmpty
            ? palavrasRaw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList()
            : [],
        imagemPeca: '',
        imagemDispositivo: '',
      );

      final chave = chaveCodigoDispositivo(codigo, nome);
      final anterior = porChave[chave];
      if (anterior != null) {
        resumo.duplicadasRemovidas++;
        porChave[chave] = dispositivo.copyWith(
          codigo: anterior.codigo,
          nome: anterior.nome,
        );
      } else {
        porChave[chave] = dispositivo;
      }
    }
  }

  onProgresso?.call(ProgressoPlanilha(etapa: 'processando', feitos: totalLinhas, total: totalLinhas));
  final dispositivos = porChave.values.toList();
  resumo.combinacoesUnicas = dispositivos.length;
  if (resumo.linhasSemChave > 0) {
    resumo.avisos.add('${resumo.linhasSemChave} linha(s) sem Código e sem Dispositivo foram ignoradas.');
  }

  return ResultadoProcessamento(
    dispositivos: dispositivos,
    novasCategorias: categorias.novos(),
    novasFamilias: familias.novos(),
    novosProdutos: produtos.novos(),
    resumo: resumo,
  );
}

