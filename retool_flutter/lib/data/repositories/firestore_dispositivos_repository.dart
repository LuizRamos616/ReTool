import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dispositivo.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/familia.dart';
import '../../domain/entities/produto.dart';
import '../../domain/repositories/i_dispositivos_repository.dart';
import '../../application/importacao/gravacao_dispositivos.dart';
import '../datasources/firebase_datasource.dart';

class FirestoreDispositivosRepository implements IDispositivosRepository {
  final FirebaseFirestore _firestore;

  FirestoreDispositivosRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseDataSource.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('dispositivos');

  @override
  Future<String> add(Dispositivo dispositivo) async {
    final doc = dispositivo.id.isNotEmpty ? _collection.doc(dispositivo.id) : _collection.doc();
    final agora = DateTime.now().toIso8601String();
    final chaveCD = chaveCodigoDispositivo(dispositivo.codigo, dispositivo.nome);
    final item = dispositivo.copyWith(
      id: doc.id,
      dataCriacao: dispositivo.dataCriacao ?? agora,
      chaveCD: chaveCD,
      ativo: dispositivo.ativo ?? true,
    );

    // Salva o documento
    await doc.set(item.toMap());

    // Se tiver nome do dispositivo, propaga/herda imagens na linha
    if (item.nome != null && item.nome!.isNotEmpty) {
      await _propagarImagens(item, isNew: true);
    }

    return doc.id;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    final docRef = _collection.doc(id);
    final snap = await docRef.get();
    final original = snap.data() != null ? Dispositivo.fromMap(snap.data()!, snap.id) : null;

    final alteracoes = Map<String, dynamic>.from(data);
    if (data.containsKey('codigo') || data.containsKey('nome')) {
      final codigo = data['codigo'] ?? original?.codigo;
      final nome = data['nome'] ?? original?.nome;
      alteracoes['chaveCD'] = chaveCodigoDispositivo(codigo, nome);
    }

    await docRef.update(alteracoes);

    if (original != null && alteracoes.containsKey('imagemDispositivo')) {
      final atualizado = original.copyWith(
        nome: alteracoes['nome'] as String? ?? original.nome,
        imagemDispositivo: alteracoes['imagemDispositivo'] as String?,
      );
      await _propagarImagens(
        atualizado,
        isNew: false,
        anteriores: {'imagemDispositivo': original.imagemDispositivo},
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<Dispositivo?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Dispositivo.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<List<Dispositivo>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final out = <Dispositivo>[];
    // In chunks of 30 for whereIn
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, (i + 30 > ids.length) ? ids.length : i + 30);
      final snap = await _collection.where(FieldPath.documentId, whereIn: chunk).get();
      out.addAll(snap.docs.map((d) => Dispositivo.fromMap(d.data(), d.id)));
    }
    return out;
  }

  @override
  Future<int> count() async {
    final agg = await _collection.count().get();
    return agg.count ?? 0;
  }

  @override
  Future<List<Dispositivo>> listarTodos() async {
    final snap = await _collection.get();
    return snap.docs.map((d) => Dispositivo.fromMap(d.data(), d.id)).toList();
  }

  @override
  Stream<List<Dispositivo>> watchDispositivos() {
    return _collection.snapshots().map(
          (snap) => snap.docs.map((d) => Dispositivo.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> _propagarImagens(
    Dispositivo origem, {
    required bool isNew,
    Map<String, dynamic> anteriores = const {},
  }) async {
    final chave = normalizarNumeroDispositivo(origem.nome);
    if (chave.isEmpty) return;

    // Busca dispositivos da mesma linha (chunked or simple limit)
    final snap = await _collection.limit(500).get();
    final todos = snap.docs.map((d) => Dispositivo.fromMap(d.data(), d.id)).toList();
    final linha = todos.where((d) => normalizarNumeroDispositivo(d.nome) == chave).toList();

    final patches = calcularPropagacaoImagens(
      linha,
      origem.id,
      origem.nome,
      origem.toMap(),
      isNew,
      anteriores,
    );

    if (patches.isEmpty) return;

    final batch = _firestore.batch();
    for (final p in patches) {
      final alvo = linha.firstWhere((d) => d.id == p.id, orElse: () => origem);
      final aplicavel = patchAindaAplicavel(alvo, p, chave);
      if (aplicavel != null && aplicavel.isNotEmpty) {
        batch.update(_collection.doc(p.id), aplicavel);
      }
    }
    await batch.commit();
  }

  @override
  Future<ResultadoImportacaoLote> importarLote(
    List<Dispositivo> novosDispositivos,
    List<String> newCategoriasNomes,
    List<String> newFamiliasNomes,
    List<String> newProdutosNomes,
    List<Categoria> categoriasExistentes,
    List<Familia> familiasExistentes,
    List<Produto> produtosExistentes, [
    OpcoesImportacaoLote? opcoes,
  ]) async {
    opcoes?.onProgresso?.call(const ProgressoImportacao(
      etapa: 'classificacoes',
      feitos: 0,
      total: 1,
    ));

    // 1. Grava classificações novas se houver
    final catMap = {for (final c in categoriasExistentes) c.nome?.toLowerCase().trim(): c.id};
    final famMap = {for (final f in familiasExistentes) f.nome.toLowerCase().trim(): f.id};
    final prodMap = {for (final p in produtosExistentes) p.nome.toLowerCase().trim(): p.id};

    for (final nome in newCategoriasNomes) {
      final k = nome.toLowerCase().trim();
      if (!catMap.containsKey(k)) {
        final doc = _firestore.collection('categorias').doc();
        await doc.set({'id': doc.id, 'nome': nome, 'ativo': true});
        catMap[k] = doc.id;
      }
    }
    for (final nome in newFamiliasNomes) {
      final k = nome.toLowerCase().trim();
      if (!famMap.containsKey(k)) {
        final doc = _firestore.collection('familias').doc();
        await doc.set({'id': doc.id, 'nome': nome, 'ativo': true});
        famMap[k] = doc.id;
      }
    }
    for (final nome in newProdutosNomes) {
      final k = nome.toLowerCase().trim();
      if (!prodMap.containsKey(k)) {
        final doc = _firestore.collection('produtos').doc();
        await doc.set({'id': doc.id, 'nome': nome, 'ativo': true});
        prodMap[k] = doc.id;
      }
    }

    opcoes?.onProgresso?.call(const ProgressoImportacao(
      etapa: 'lendo-existentes',
      feitos: 0,
      total: 1,
    ));

    // 2. Lê existentes se não foram fornecidos
    final existentes = opcoes?.existentesConhecidos ?? await listarTodos();

    // 3. Herança de imagens da linha para novos dispositivos
    final herdadas = herdarImagensDaLinha(novosDispositivos, existentes);

    // 4. Planeja a gravação com descarte de sem alteração
    final plano = planejarGravacao(
      novosDispositivos,
      existentes,
      () => _collection.doc().id,
    );

    final lotes = emLotes(plano.operacoes, tamanhoLoteDispositivos);
    int sucesso = 0;
    int erros = 0;
    int inseridos = 0;
    int atualizados = 0;
    final falhas = <String>[];
    String? interrompido;

    for (var i = 0; i < lotes.length; i++) {
      if (opcoes?.cancelado?.call() == true) {
        interrompido = 'cancelado';
        break;
      }
      final lote = lotes[i];
      final batch = _firestore.batch();
      for (final op in lote) {
        final docRef = _collection.doc(op.id);
        if (op.novo) {
          batch.set(docRef, op.dados);
        } else {
          batch.update(docRef, op.dados);
        }
      }

      try {
        await batch.commit();
        sucesso += lote.fold(0, (acc, op) => acc + op.registros);
        for (final op in lote) {
          if (op.novo) {
            inseridos += op.registros;
          } else {
            atualizados += op.registros;
          }
        }
      } catch (e) {
        erros += lote.fold(0, (acc, op) => acc + op.registros);
        falhas.add(e.toString());
        if (ehErroDeCota(e)) {
          interrompido = 'cota';
          break;
        }
      }

      opcoes?.onProgresso?.call(ProgressoImportacao(
        etapa: 'gravando',
        feitos: sucesso + erros,
        total: plano.registrosAGravar,
        lote: i + 1,
        totalLotes: lotes.length,
      ));
    }

    opcoes?.onProgresso?.call(ProgressoImportacao(
      etapa: 'concluido',
      feitos: sucesso + erros,
      total: plano.registrosAGravar,
    ));

    return ResultadoImportacaoLote(
      sucesso: sucesso,
      erros: erros,
      inseridos: inseridos,
      atualizados: atualizados,
      ignoradosSemAlteracao: plano.ignoradosSemAlteracao,
      documentosGravados: sucesso,
      documentosLidos: existentes.length,
      imagensHerdadas: herdadas,
      falhas: falhas.isNotEmpty ? falhas : null,
      interrompido: interrompido,
    );
  }

  @override
  Future<ResultadoExclusaoLote> excluirEmLote(
    List<String> ids, {
    int? partesIndice,
    void Function(int feitos, int total)? onProgresso,
    bool Function()? cancelado,
  }) async {
    final lotes = emLotes(ids, tamanhoLoteDispositivos);
    int excluidos = 0;
    int erros = 0;
    final falhas = <String>[];
    bool foiCancelado = false;

    for (var i = 0; i < lotes.length; i++) {
      if (cancelado?.call() == true) {
        foiCancelado = true;
        break;
      }
      final lote = lotes[i];
      final batch = _firestore.batch();
      for (final id in lote) {
        batch.delete(_collection.doc(id));
      }
      try {
        await batch.commit();
        excluidos += lote.length;
      } catch (e) {
        erros += lote.length;
        falhas.add(e.toString());
      }
      onProgresso?.call(excluidos + erros, ids.length);
    }

    return ResultadoExclusaoLote(
      excluidos: excluidos,
      erros: erros,
      falhas: falhas,
      cancelado: foiCancelado,
    );
  }
}

