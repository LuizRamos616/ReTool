import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/solicitacao_cargo.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import '../datasources/firebase_datasource.dart';

class FirestoreSolicitacoesCargoRepository implements ISolicitacoesCargoRepository {
  final FirebaseFirestore _firestore;

  FirestoreSolicitacoesCargoRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseDataSource.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('solicitacoes_cargo');
  CollectionReference<Map<String, dynamic>> get _pendencias =>
      _firestore.collection('pendencias_cargo');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<SolicitacaoCargo?> obter(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SolicitacaoCargo.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<SolicitacaoCargo?> obterPendenteDoUsuario(String uid) async {
    final snap = await _collection
        .where('usuarioUid', isEqualTo: uid)
        .where('status', isEqualTo: SolicitacaoCargoStatuses.pendente)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SolicitacaoCargo.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  @override
  Future<void> criar(SolicitacaoCargo solicitacao) async {
    final batch = _firestore.batch();
    batch.set(_collection.doc(solicitacao.id), solicitacao.toMap());
    batch.set(_pendencias.doc(solicitacao.usuarioUid), {
      'solicitacaoId': solicitacao.id,
      'data': solicitacao.dataSolicitacao,
    });
    await batch.commit();
  }

  @override
  Future<void> decidir(SolicitacaoCargo solicitacao, DecisaoSolicitacaoCargo decisao) async {
    final batch = _firestore.batch();
    batch.update(_collection.doc(solicitacao.id), {
      'status': decisao.status,
      'decididoPorUid': decisao.decididoPorUid,
      'decididoPorNome': decisao.decididoPorNome,
      'dataDecisao': decisao.dataDecisao,
      if (decisao.motivoDecisao != null) 'motivoDecisao': decisao.motivoDecisao,
    });

    if (decisao.status == SolicitacaoCargoStatuses.aprovada) {
      batch.update(_users.doc(solicitacao.usuarioUid), {
        'perfil': solicitacao.perfilSolicitado,
        'atualizadoEm': decisao.dataDecisao,
      });
    }

    batch.delete(_pendencias.doc(solicitacao.usuarioUid));
    await batch.commit();
  }

  @override
  Stream<List<SolicitacaoCargo>> watchSolicitacoes({String? usuarioUid}) {
    Query<Map<String, dynamic>> query = _collection;
    if (usuarioUid != null) {
      query = query.where('usuarioUid', isEqualTo: usuarioUid);
    }
    return query
        .orderBy('dataSolicitacao', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SolicitacaoCargo.fromMap(d.data(), d.id)).toList());
  }
}

