import '../entities/dispositivo.dart';
import '../entities/categoria.dart';
import '../entities/familia.dart';
import '../entities/produto.dart';

class ResultadoImportacaoLote {
  final int sucesso;
  final int erros;
  final int? inseridos;
  final int? atualizados;
  final List<String>? falhas;
  final int? ignoradosSemAlteracao;
  final String? interrompido; // 'cancelado' | 'cota'
  final int? naoGravados;
  final int? documentosLidos;
  final List<Dispositivo>? documentosFinais;
  final bool? leituraParcial;
  final int? documentosGravados;
  final int? imagensHerdadas;

  const ResultadoImportacaoLote({
    required this.sucesso,
    required this.erros,
    this.inseridos,
    this.atualizados,
    this.falhas,
    this.ignoradosSemAlteracao,
    this.interrompido,
    this.naoGravados,
    this.documentosLidos,
    this.documentosFinais,
    this.leituraParcial,
    this.documentosGravados,
    this.imagensHerdadas,
  });
}

class ProgressoImportacao {
  final String etapa; // 'classificacoes' | 'lendo-existentes' | 'gravando' | 'concluido'
  final int feitos;
  final int total;
  final int? lote;
  final int? totalLotes;

  const ProgressoImportacao({
    required this.etapa,
    required this.feitos,
    required this.total,
    this.lote,
    this.totalLotes,
  });
}

class OpcoesImportacaoLote {
  final void Function(ProgressoImportacao p)? onProgresso;
  final bool Function()? cancelado;
  final List<Dispositivo>? existentesConhecidos;
  final int? partesIndice;
  final bool? catalogoClassificacoes;

  const OpcoesImportacaoLote({
    this.onProgresso,
    this.cancelado,
    this.existentesConhecidos,
    this.partesIndice,
    this.catalogoClassificacoes,
  });
}

class ResultadoExclusaoLote {
  final int excluidos;
  final int erros;
  final List<String> falhas;
  final bool cancelado;

  const ResultadoExclusaoLote({
    required this.excluidos,
    required this.erros,
    required this.falhas,
    this.cancelado = false,
  });
}

abstract class IDispositivosRepository {
  Future<String> add(Dispositivo dispositivo);
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<Dispositivo?> getById(String id);
  Future<List<Dispositivo>> getByIds(List<String> ids);
  Future<int> count();
  Future<List<Dispositivo>> listarTodos();
  Stream<List<Dispositivo>> watchDispositivos();
  Future<ResultadoImportacaoLote> importarLote(
    List<Dispositivo> novosDispositivos,
    List<String> newCategoriasNomes,
    List<String> newFamiliasNomes,
    List<String> newProdutosNomes,
    List<Categoria> categoriasExistentes,
    List<Familia> familiasExistentes,
    List<Produto> produtosExistentes, [
    OpcoesImportacaoLote? opcoes,
  ]);
  Future<ResultadoExclusaoLote> excluirEmLote(
    List<String> ids, {
    int? partesIndice,
    void Function(int feitos, int total)? onProgresso,
    bool Function()? cancelado,
  });
}

