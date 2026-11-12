import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notificacao.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import '../datasources/firebase_datasource.dart';

class FirestoreNotificationsRepository implements INotificationsRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotificationsRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseDataSource.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  @override
  Future<void> criar(Notificacao notificacao) async {
    await _collection.doc(notificacao.id).set(notificacao.toMap());
  }

  @override
  Future<void> marcarResolvida(String id, bool resolvida) async {
    await _collection.doc(id).update({'resolvida': resolvida});
  }

  @override
  Future<void> marcarLida(String id, bool lida) async {
    await _collection.doc(id).update({'lida': lida});
  }

  @override
  Stream<List<Notificacao>> watchNotifications(String destinatarioUid) {
    return _collection
        .where('destinatarioUid', isEqualTo: destinatarioUid)
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Notificacao.fromMap(d.data(), d.id)).toList());
  }
}

