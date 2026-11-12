import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dispositivo.dart';
import '../../domain/services/busca_dispositivos.dart';
import '../datasources/firebase_datasource.dart';

class MetaIndice {
  final int partes;
  final int total;
  final String atualizadoEm;

  const MetaIndice({
    required this.partes,
    required this.total,
    required this.atualizadoEm,
  });

  factory MetaIndice.fromMap(Map<String, dynamic> map) {
    return MetaIndice(
      partes: (map['partes'] as num?)?.toInt() ?? 4,
      total: (map['total'] as num?)?.toInt() ?? 0,
      atualizadoEm: map['atualizadoEm'] as String? ?? '',
    );
  }
}

class FirestoreIndiceDispositivos {
  final FirebaseFirestore _firestore;

  FirestoreIndiceDispositivos([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseDataSource.firestore;

  DocumentReference<Map<String, dynamic>> get _metaRef =>
      _firestore.collection('indices').doc('dispositivos');

  CollectionReference<Map<String, dynamic>> get _partesCol =>
      _firestore.collection('indices').doc('dispositivos').collection('partes');

  Future<MetaIndice?> lerMeta() async {
    final doc = await _metaRef.get();
    if (!doc.exists || doc.data() == null) return null;
    return MetaIndice.fromMap(doc.data()!);
  }

  Future<List<EntradaIndice>> baixarCatalogoCompleto(int totalPartes) async {
    final entradas = <EntradaIndice>[];
    for (var p = 0; p < totalPartes; p++) {
      final doc = await _partesCol.doc(p.toString()).get();
      if (!doc.exists || doc.data() == null) continue;
      final dados = doc.data()!;
      for (final entry in dados.entries) {
        if (entry.value is String) {
          entradas.add(desserializarEntrada(entry.key, entry.value as String));
        }
      }
    }
    return entradas;
  }

  Future<int> reconstruirIndice(List<Dispositivo> todosDispositivos) async {
    final total = todosDispositivos.length;
    final numPartes = partesParaTotal(total);

    final shards = List.generate(numPartes, (_) => <String, String>{});
    for (final d in todosDispositivos) {
      final parte = parteDoId(d.id, numPartes);
      shards[parte][d.id] = serializarEntrada(d);
    }

    final batch = _firestore.batch();
    for (var i = 0; i < numPartes; i++) {
      batch.set(_partesCol.doc(i.toString()), shards[i]);
    }

    final agora = DateTime.now().toIso8601String();
    batch.set(_metaRef, {
      'partes': numPartes,
      'total': total,
      'atualizadoEm': agora,
    });

    await batch.commit();
    return total;
  }
}

