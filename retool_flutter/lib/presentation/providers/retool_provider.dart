import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dispositivo.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/familia.dart';
import '../../domain/entities/produto.dart';
import '../../domain/entities/reutilizacao.dart';
import '../../domain/entities/file_attachment.dart';
import '../../domain/services/busca_dispositivos.dart';
import '../../domain/repositories/i_dispositivos_repository.dart';
import '../../domain/repositories/i_classificacoes_repository.dart';
import '../../domain/repositories/i_reutilizacoes_repository.dart';
import '../../domain/repositories/i_storage_service.dart';
import '../../data/repositories/firestore_dispositivos_repository.dart';
import '../../data/repositories/firestore_classificacoes_repository.dart';
import '../../data/repositories/firestore_reutilizacoes_repository.dart';
import '../../data/services/firebase_storage_service.dart';
import '../../application/importacao/planilha_dispositivos.dart';

final dispositivosRepoProvider = Provider<IDispositivosRepository>((ref) => FirestoreDispositivosRepository());
final classificacoesRepoProvider = Provider<IClassificacoesRepository>((ref) => FirestoreClassificacoesRepository());
final reutilizacoesRepoProvider = Provider<IReutilizacoesRepository>((ref) => FirestoreReutilizacoesRepository());
final storageServiceProvider = Provider<IStorageService>((ref) => FirebaseStorageService());

class ToastMessage {
  final String id;
  final String message;
  const ToastMessage(this.id, this.message);
}

class ReToolState {
  final List<Dispositivo> dispositivos;
  final List<Categoria> categorias;
  final List<Tipo> tipos;
  final List<Familia> familias;
  final List<Produto> produtos;
  final List<Reutilizacao> reutilizacoes;
  final bool loading;
  final String? erro;
  final List<ToastMessage> toasts;

  // Busca e Filtros
  final String query;
  final String? filtroCategoriaId;
  final String? filtroFamiliaId;
  final String? filtroProdutoId;
  final String? filtroProcesso;

  const ReToolState({
    this.dispositivos = const [],
    this.categorias = const [],
    this.tipos = const [],
    this.familias = const [],
    this.produtos = const [],
    this.reutilizacoes = const [],
    this.loading = false,
    this.erro,
    this.toasts = const [],
    this.query = '',
    this.filtroCategoriaId,
    this.filtroFamiliaId,
    this.filtroProdutoId,
    this.filtroProcesso,
  });

  NomesClassificacao get nomesClassificacao => NomesClassificacao(
        categorias: {for (final c in categorias) c.id: c.nome ?? ''},
        familias: {for (final f in familias) f.id: f.nome},
        produtos: {for (final p in produtos) p.id: p.nome},
      );

  List<EntradaIndice> get entradasIndice => dispositivos.map((d) => EntradaIndice(
        id: d.id,
        codigo: d.codigo ?? '',
        nome: d.nome ?? '',
        descricao: d.descricao ?? '',
        categoriaId: d.categoriaId ?? '',
        familiaId: d.familiaId ?? '',
        produtoId: d.produtoId ?? '',
        peso: d.peso ?? '',
        palavrasChave: d.palavrasChave ?? [],
        ativo: d.ativo ?? true,
      )).toList();

  List<Dispositivo> get dispositivosFiltrados {
    if (query.isEmpty &&
        (filtroCategoriaId == null || filtroCategoriaId!.isEmpty) &&
        (filtroFamiliaId == null || filtroFamiliaId!.isEmpty) &&
        (filtroProdutoId == null || filtroProdutoId!.isEmpty) &&
        (filtroProcesso == null || filtroProcesso!.isEmpty)) {
      return dispositivos;
    }

    final preparadas = prepararEntradas(entradasIndice, nomesClassificacao);
    final filtradas = filtrarEntradas(
      preparadas,
      FiltroBusca(
        texto: query,
        categoriaId: filtroCategoriaId,
        familiaId: filtroFamiliaId,
        produtoId: filtroProdutoId,
        processo: filtroProcesso,
      ),
    );

    final idsEncontrados = {for (final f in filtradas) f.id};
    return dispositivos.where((d) => idsEncontrados.contains(d.id)).toList();
  }

  ReToolState copyWith({
    List<Dispositivo>? dispositivos,
    List<Categoria>? categorias,
    List<Tipo>? tipos,
    List<Familia>? familias,
    List<Produto>? produtos,
    List<Reutilizacao>? reutilizacoes,
    bool? loading,
    String? erro,
    List<ToastMessage>? toasts,
    String? query,
    String? filtroCategoriaId,
    String? filtroFamiliaId,
    String? filtroProdutoId,
    String? filtroProcesso,
  }) {
    return ReToolState(
      dispositivos: dispositivos ?? this.dispositivos,
      categorias: categorias ?? this.categorias,
      tipos: tipos ?? this.tipos,
      familias: familias ?? this.familias,
      produtos: produtos ?? this.produtos,
      reutilizacoes: reutilizacoes ?? this.reutilizacoes,
      loading: loading ?? this.loading,
      erro: erro,
      toasts: toasts ?? this.toasts,
      query: query ?? this.query,
      filtroCategoriaId: filtroCategoriaId ?? this.filtroCategoriaId,
      filtroFamiliaId: filtroFamiliaId ?? this.filtroFamiliaId,
      filtroProdutoId: filtroProdutoId ?? this.filtroProdutoId,
      filtroProcesso: filtroProcesso ?? this.filtroProcesso,
    );
  }
}

class ReToolNotifier extends StateNotifier<ReToolState> {
  final Ref ref;
  StreamSubscription? _dispSub;
  StreamSubscription? _catSub;
  StreamSubscription? _tipSub;
  StreamSubscription? _famSub;
  StreamSubscription? _prodSub;
  StreamSubscription? _reutSub;

  ReToolNotifier(this.ref) : super(const ReToolState()) {
    _initStreams();
  }

  void _initStreams() {
    try {
      final dispRepo = ref.read(dispositivosRepoProvider);
      final classRepo = ref.read(classificacoesRepoProvider);
      final reutRepo = ref.read(reutilizacoesRepoProvider);

      _dispSub = dispRepo.watchDispositivos().listen((lista) {
        state = state.copyWith(dispositivos: lista);
      });
      _catSub = classRepo.watchCategorias().listen((lista) {
        state = state.copyWith(categorias: lista);
      });
      _tipSub = classRepo.watchTipos().listen((lista) {
        state = state.copyWith(tipos: lista);
      });
      _famSub = classRepo.watchFamilias().listen((lista) {
        state = state.copyWith(familias: lista);
      });
      _prodSub = classRepo.watchProdutos().listen((lista) {
        state = state.copyWith(produtos: lista);
      });
      _reutSub = reutRepo.watchReutilizacoes().listen((lista) {
        state = state.copyWith(reutilizacoes: lista);
      });
    } catch (_) {
      // In offline/test mode
    }
  }

  void setDispositivosForTesting(List<Dispositivo> disps) {
    state = state.copyWith(dispositivos: disps);
  }

  void setCategoriasForTesting(List<Categoria> cats) {
    state = state.copyWith(categorias: cats);
  }

  void setReutilizacoesForTesting(List<Reutilizacao> reuts) {
    state = state.copyWith(reutilizacoes: reuts);
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setFiltroCategoria(String? catId) {
    state = state.copyWith(filtroCategoriaId: catId);
  }

  void setFiltroFamilia(String? famId) {
    state = state.copyWith(filtroFamiliaId: famId);
  }

  void setFiltroProduto(String? prodId) {
    state = state.copyWith(filtroProdutoId: prodId);
  }

  void setFiltroProcesso(String? proc) {
    state = state.copyWith(filtroProcesso: proc);
  }

  void showToast(String message) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    state = state.copyWith(toasts: [...state.toasts, ToastMessage(id, message)]);
    Future.delayed(const Duration(milliseconds: 3500), () {
      state = state.copyWith(toasts: state.toasts.where((t) => t.id != id).toList());
    });
  }

  // Dispositivos CRUD
  Future<void> saveDispositivo(Dispositivo dispositivo) async {
    final repo = ref.read(dispositivosRepoProvider);
    if (dispositivo.id.isEmpty) {
      await repo.add(dispositivo);
      showToast('Dispositivo cadastrado com sucesso!');
    } else {
      await repo.update(dispositivo.id, dispositivo.toMap());
      showToast('Dispositivo atualizado com sucesso!');
    }
  }

  Future<void> deleteDispositivo(String id) async {
    final repo = ref.read(dispositivosRepoProvider);
    await repo.delete(id);
    showToast('Dispositivo excluído!');
  }

  Future<void> excluirDispositivosEmLote(List<String> ids) async {
    final repo = ref.read(dispositivosRepoProvider);
    final res = await repo.excluirEmLote(ids);
    showToast('${res.excluidos} dispositivo(s) excluído(s).');
  }

  // Classificações CRUD
  Future<void> addCategoria(String nome) async {
    await ref.read(classificacoesRepoProvider).addCategoria(nome);
    showToast('Categoria adicionada!');
  }

  Future<void> updateCategoria(String id, String nome) async {
    await ref.read(classificacoesRepoProvider).updateCategoria(id, nome);
    showToast('Categoria atualizada!');
  }

  Future<void> deleteCategoria(String id) async {
    await ref.read(classificacoesRepoProvider).deleteCategoria(id);
    showToast('Categoria removida!');
  }

  Future<void> addFamilia(String nome) async {
    await ref.read(classificacoesRepoProvider).addFamilia(nome);
    showToast('Família adicionada!');
  }

  Future<void> updateFamilia(String id, String nome) async {
    await ref.read(classificacoesRepoProvider).updateFamilia(id, nome);
    showToast('Família atualizada!');
  }

  Future<void> deleteFamilia(String id) async {
    await ref.read(classificacoesRepoProvider).deleteFamilia(id);
    showToast('Família removida!');
  }

  Future<void> addProduto(String nome) async {
    await ref.read(classificacoesRepoProvider).addProduto(nome);
    showToast('Produto adicionado!');
  }

  Future<void> updateProduto(String id, String nome) async {
    await ref.read(classificacoesRepoProvider).updateProduto(id, nome);
    showToast('Produto atualizado!');
  }

  Future<void> deleteProduto(String id) async {
    await ref.read(classificacoesRepoProvider).deleteProduto(id);
    showToast('Produto removido!');
  }

  // Reutilizações CRUD
  Future<void> addReutilizacao(Reutilizacao reut) async {
    await ref.read(reutilizacoesRepoProvider).add(reut);
    showToast('Solicitação de reutilização enviada!');
  }

  Future<void> transicionarReutilizacao(
    String id,
    String novoStatus, {
    String? motivo,
    String? numeroOs,
    String? aprovadorId,
    String? aprovadorNome,
  }) async {
    final data = <String, dynamic>{
      'status': novoStatus,
      if (motivo != null) 'motivoRejeicao': motivo,
      if (numeroOs != null) 'numeroOs': numeroOs,
      if (aprovadorId != null) 'aprovadorId': aprovadorId,
      if (aprovadorNome != null) 'aprovadorNome': aprovadorNome,
      if (novoStatus == ReutilizacaoStatuses.reutilizacaoAprovada)
        'dataAprovacao': DateTime.now().toIso8601String(),
    };
    await ref.read(reutilizacoesRepoProvider).update(id, data);
    showToast('Status atualizado para: ${rotuloCurtoStatusReutilizacao(novoStatus)}');
  }

  Future<void> definirHardSaving(String id, double valor) async {
    await ref.read(reutilizacoesRepoProvider).update(id, {'hardSaving': valor});
    showToast('Hard Saving atualizado!');
  }

  // Storage / Uploads
  Future<FileAttachment> uploadAnexo({
    required String dispositivoId,
    required String categoria,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    return ref.read(storageServiceProvider).uploadFile(
          dispositivoId: dispositivoId,
          categoria: categoria,
          fileName: fileName,
          bytes: bytes,
          contentType: contentType,
        );
  }

  // Importação Planilha
  Future<ResultadoImportacaoLote> importarPlanilha({
    required List<int> fileBytes,
    required String fileName,
    void Function(ProgressoPlanilha)? onProgressoLeitura,
    void Function(ProgressoImportacao)? onProgressoGravacao,
    bool Function()? cancelado,
  }) async {
    final abas = lerPlanilhaBytes(fileBytes, fileName, onProgressoLeitura);
    final proc = processarPlanilhaDispositivos(
      abas,
      ContextoProcessamento(
        categorias: state.categorias,
        familias: state.familias,
        produtos: state.produtos,
      ),
      onProgressoLeitura,
    );

    final res = await ref.read(dispositivosRepoProvider).importarLote(
      proc.dispositivos,
      proc.novasCategorias,
      proc.novasFamilias,
      proc.novosProdutos,
      state.categorias,
      state.familias,
      state.produtos,
      OpcoesImportacaoLote(
        onProgresso: onProgressoGravacao,
        cancelado: cancelado,
        existentesConhecidos: state.dispositivos,
      ),
    );

    showToast('Importação concluída: ${res.sucesso} registros gravados.');
    return res;
  }

  @override
  void dispose() {
    _dispSub?.cancel();
    _catSub?.cancel();
    _tipSub?.cancel();
    _famSub?.cancel();
    _prodSub?.cancel();
    _reutSub?.cancel();
    super.dispose();
  }
}

final reToolProvider = StateNotifierProvider<ReToolNotifier, ReToolState>((ref) {
  return ReToolNotifier(ref);
});

