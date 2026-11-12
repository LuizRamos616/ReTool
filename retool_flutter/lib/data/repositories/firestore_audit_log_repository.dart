import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/i_acessos_repositories.dart';
import '../datasources/firebase_datasource.dart';

class FirestoreAuditLogRepository implements IAuditLogRepository {
  final FirebaseFirestore _firestore;

  FirestoreAuditLogRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseDataSource.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('audit_logs');

  @override
  Future<String> registrarLog(AuditLogInput logData) async {
    final agora = logData.dataHora ?? DateTime.now().toIso8601String();
    final docRef = _collection.doc();

    final data = <String, dynamic>{
      'id': docRef.id,
      'dataHora': agora,
      'dataHoraServidor': FieldValue.serverTimestamp(),
      'usuarioUid': logData.usuarioUid,
      'usuarioNome': logData.usuarioNome,
      'usuarioEmail': logData.usuarioEmail,
      'usuarioPerfil': logData.usuarioPerfil,
      'acao': logData.acao,
      'categoria': logData.categoria,
      'resultado': logData.resultado,
      if (logData.acaoDescricao != null) 'acaoDescricao': logData.acaoDescricao,
      'tipoEntidade': logData.tipoEntidade,
      'entidadeId': logData.entidadeId,
      if (logData.entidadeNome != null) 'entidadeNome': logData.entidadeNome,
      if (logData.detalhes != null) 'detalhes': logData.detalhes,
      if (logData.conteudo != null) 'conteudo': sanitizarDadosAuditoria(logData.conteudo),
      if (logData.dadosAnteriores != null)
        'dadosAnteriores': sanitizarDadosAuditoria(logData.dadosAnteriores),
    };

    await docRef.set(data);
    return docRef.id;
  }

  @override
  Future<List<AuditLog>> listarLogs({
    String? categoria,
    String? acao,
    String? usuarioUid,
    String? tipoEntidade,
    String? resultado,
    int limite = 50,
  }) async {
    Query<Map<String, dynamic>> query = _collection;

    if (categoria != null && categoria.isNotEmpty) {
      query = query.where('categoria', isEqualTo: categoria);
    }
    if (acao != null && acao.isNotEmpty) {
      query = query.where('acao', isEqualTo: acao);
    }
    if (usuarioUid != null && usuarioUid.isNotEmpty) {
      query = query.where('usuarioUid', isEqualTo: usuarioUid);
    }
    if (tipoEntidade != null && tipoEntidade.isNotEmpty) {
      query = query.where('tipoEntidade', isEqualTo: tipoEntidade);
    }
    if (resultado != null && resultado.isNotEmpty) {
      query = query.where('resultado', isEqualTo: resultado);
    }

    final snap = await query.orderBy('dataHora', descending: true).limit(limite).get();
    return snap.docs.map((d) => AuditLog.fromMap(d.data(), d.id)).toList();
  }
}

