import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reutilizacao.dart';
import '../../domain/repositories/i_reutilizacoes_repository.dart';
import '../datasources/firebase_datasource.dart';

class FirestoreReutilizacoesRepository implements IReutilizacoesRepository {
  final FirebaseFirestore _firestore;

  FirestoreReutilizacoesRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseDataSource.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('reutilizacoes');

  @override
  Future<String> add(Reutilizacao reutilizacao) async {
    final doc = _collection.doc();
    final item = reutilizacao.copyWith(
      id: doc.id,
      dataCriacao: reutilizacao.dataCriacao ?? DateTime.now().toIso8601String(),
    );
    await doc.set(item.toMap());
    return doc.id;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  @override
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<Reutilizacao?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Reutilizacao.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<List<Reutilizacao>> listarPorDispositivo(String dispositivoId) async {
    final snap = await _collection
        .where('dispositivoId', isEqualTo: dispositivoId)
        .orderBy('dataCriacao', descending: true)
        .get();
    return snap.docs.map((d) => Reutilizacao.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<List<Reutilizacao>> listarTodas() async {
    final snap = await _collection.orderBy('dataCriacao', descending: true).get();
    return snap.docs.map((d) => Reutilizacao.fromMap(d.data(), d.id)).toList();
  }

  @override
  Stream<List<Reutilizacao>> watchReutilizacoes() {
    return _collection.orderBy('dataCriacao', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => Reutilizacao.fromMap(d.data(), d.id)).toList(),
        );
  }
}

