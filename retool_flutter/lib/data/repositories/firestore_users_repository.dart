import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import '../datasources/firebase_datasource.dart';

class FirestoreUsersRepository implements IUsersRepository {
  final FirebaseFirestore _firestore;

  FirestoreUsersRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseDataSource.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> setProfile(UserProfile profile) async {
    await _collection.doc(profile.uid).set(profile.toMap());
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _collection.doc(uid).update(data);
  }

  @override
  Future<List<UserProfile>> listarAdministradoresAtivos() async {
    final snap = await _collection
        .where('perfil', isEqualTo: 'admin')
        .where('ativo', isEqualTo: true)
        .get();
    return snap.docs.map((d) => UserProfile.fromMap(d.data(), d.id)).toList();
  }

  @override
  Stream<List<UserProfile>> watchUsers() {
    return _collection.snapshots().map((snap) =>
        snap.docs.map((d) => UserProfile.fromMap(d.data(), d.id)).toList());
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!, doc.id);
    });
  }
}

