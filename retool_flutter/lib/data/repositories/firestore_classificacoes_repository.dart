import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/familia.dart';
import '../../domain/entities/produto.dart';
import '../../domain/repositories/i_classificacoes_repository.dart';
import '../datasources/firebase_datasource.dart';

class FirestoreClassificacoesRepository implements IClassificacoesRepository {
  final FirebaseFirestore _firestore;

  FirestoreClassificacoesRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseDataSource.firestore;

  CollectionReference<Map<String, dynamic>> get _categorias => _firestore.collection('categorias');
  CollectionReference<Map<String, dynamic>> get _tipos => _firestore.collection('tipos');
  CollectionReference<Map<String, dynamic>> get _familias => _firestore.collection('familias');
  CollectionReference<Map<String, dynamic>> get _produtos => _firestore.collection('produtos');

  @override
  Future<List<Categoria>> getCategorias() async {
    final snap = await _categorias.get();
    return snap.docs.map((d) => Categoria.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<String> addCategoria(String nome) async {
    final doc = _categorias.doc();
    await doc.set({'id': doc.id, 'nome': nome, 'ativo': true});
    return doc.id;
  }

  @override
  Future<void> updateCategoria(String id, String nome, [bool? ativo]) async {
    await _categorias.doc(id).update({
      'nome': nome,
      if (ativo != null) 'ativo': ativo,
    });
  }

  @override
  Future<void> deleteCategoria(String id) async {
    await _categorias.doc(id).delete();
  }

  @override
  Future<List<Tipo>> getTipos() async {
    final snap = await _tipos.get();
    return snap.docs.map((d) => Tipo.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<String> addTipo(String nome) async {
    final doc = _tipos.doc();
    await doc.set({'id': doc.id, 'nome': nome, 'ativo': true});
    return doc.id;
  }

  @override
  Future<void> updateTipo(String id, String nome, [bool? ativo]) async {
    await _tipos.doc(id).update({
      'nome': nome,
      if (ativo != null) 'ativo': ativo,
    });
  }

  @override
  Future<void> deleteTipo(String id) async {
    await _tipos.doc(id).delete();
  }

  @override
  Future<List<Familia>> getFamilias() async {
    final snap = await _familias.get();
    return snap.docs.map((d) => Familia.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<String> addFamilia(String nome) async {
    final doc = _familias.doc();
    await doc.set({'id': doc.id, 'nome': nome, 'ativo': true});
    return doc.id;
  }

  @override
  Future<void> updateFamilia(String id, String nome, [bool? ativo]) async {
    await _familias.doc(id).update({
      'nome': nome,
      if (ativo != null) 'ativo': ativo,
    });
  }

  @override
  Future<void> deleteFamilia(String id) async {
    await _familias.doc(id).delete();
  }

  @override
  Future<List<Produto>> getProdutos() async {
    final snap = await _produtos.get();
    return snap.docs.map((d) => Produto.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<String> addProduto(String nome) async {
    final doc = _produtos.doc();
    await doc.set({'id': doc.id, 'nome': nome, 'ativo': true});
    return doc.id;
  }

  @override
  Future<void> updateProduto(String id, String nome, [bool? ativo]) async {
    await _produtos.doc(id).update({
      'nome': nome,
      if (ativo != null) 'ativo': ativo,
    });
  }

  @override
  Future<void> deleteProduto(String id) async {
    await _produtos.doc(id).delete();
  }

  @override
  Stream<List<Categoria>> watchCategorias() {
    return _categorias.snapshots().map((snap) =>
        snap.docs.map((d) => Categoria.fromMap(d.data(), d.id)).toList());
  }

  @override
  Stream<List<Tipo>> watchTipos() {
    return _tipos.snapshots().map((snap) =>
        snap.docs.map((d) => Tipo.fromMap(d.data(), d.id)).toList());
  }

  @override
  Stream<List<Familia>> watchFamilias() {
    return _familias.snapshots().map((snap) =>
        snap.docs.map((d) => Familia.fromMap(d.data(), d.id)).toList());
  }

  @override
  Stream<List<Produto>> watchProdutos() {
    return _produtos.snapshots().map((snap) =>
        snap.docs.map((d) => Produto.fromMap(d.data(), d.id)).toList());
  }
}

