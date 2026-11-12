import '../entities/categoria.dart';
import '../entities/familia.dart';
import '../entities/produto.dart';

abstract class IClassificacoesRepository {
  Future<List<Categoria>> getCategorias();
  Future<String> addCategoria(String nome);
  Future<void> updateCategoria(String id, String nome, [bool? ativo]);
  Future<void> deleteCategoria(String id);

  Future<List<Tipo>> getTipos();
  Future<String> addTipo(String nome);
  Future<void> updateTipo(String id, String nome, [bool? ativo]);
  Future<void> deleteTipo(String id);

  Future<List<Familia>> getFamilias();
  Future<String> addFamilia(String nome);
  Future<void> updateFamilia(String id, String nome, [bool? ativo]);
  Future<void> deleteFamilia(String id);

  Future<List<Produto>> getProdutos();
  Future<String> addProduto(String nome);
  Future<void> updateProduto(String id, String nome, [bool? ativo]);
  Future<void> deleteProduto(String id);

  Stream<List<Categoria>> watchCategorias();
  Stream<List<Tipo>> watchTipos();
  Stream<List<Familia>> watchFamilias();
  Stream<List<Produto>> watchProdutos();
}

