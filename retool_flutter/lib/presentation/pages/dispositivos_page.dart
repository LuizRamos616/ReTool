import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/retool_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/dispositivo.dart';
import '../widgets/feedback/skeleton.dart';
import '../widgets/feedback/empty_state.dart';
import '../widgets/modals/accessible_modal.dart';
import '../widgets/modals/import_modal.dart';
import '../widgets/modals/duplicados_modal.dart';

const _tamanhosPagina = [25, 50, 100];

class DispositivosPage extends ConsumerStatefulWidget {
  const DispositivosPage({super.key});

  @override
  ConsumerState<DispositivosPage> createState() => _DispositivosPageState();
}

class _DispositivosPageState extends ConsumerState<DispositivosPage> {
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();

  // Filtros
  String _filterCategoria = '';
  String _filterFamilia = '';
  String _filterProduto = '';
  String _filterProcesso = '';
  String _filterCodigo = '';
  String _filterDescricao = '';
  bool _showFilters = false;

  // Paginação
  int _itemsPerPage = 25;
  int _pagina = 1;

  // Modais
  String? _dispToDelete;
  bool _isDeleting = false;
  bool _isImportOpen = false;
  bool _isDuplicadosOpen = false;
  bool _isBulkOpen = false;

  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(reToolProvider.notifier).setQuery(val);
        setState(() => _pagina = 1);
      }
    });
  }

  List<Dispositivo> _applyExtraFilters(List<Dispositivo> items) {
    var result = items;
    if (_filterCategoria.isNotEmpty) {
      result = result.where((d) => d.categoriaId == _filterCategoria).toList();
    }
    if (_filterFamilia.isNotEmpty) {
      result = result.where((d) => d.familiaId == _filterFamilia).toList();
    }
    if (_filterProduto.isNotEmpty) {
      result = result.where((d) => d.produtoId == _filterProduto).toList();
    }
    if (_filterProcesso.isNotEmpty) {
      result = result
          .where((d) => (d.processo ?? '') == _filterProcesso)
          .toList();
    }
    if (_filterCodigo.isNotEmpty) {
      final q = _filterCodigo.toLowerCase();
      result = result
          .where((d) => (d.codigo ?? '').toLowerCase().contains(q))
          .toList();
    }
    if (_filterDescricao.isNotEmpty) {
      final q = _filterDescricao.toLowerCase();
      result = result
          .where((d) => (d.descricao ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  Future<void> _handleDelete() async {
    if (_dispToDelete == null) return;
    setState(() => _isDeleting = true);
    try {
      await ref.read(reToolProvider.notifier).deleteDispositivo(_dispToDelete!);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isDeleting = false;
        _dispToDelete = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final rt = ref.watch(reToolProvider);
    final canCadastrar = auth.canCadastrar;
    final canEditar = auth.canEditar;
    final canExcluir = auth.canExcluir;
    final isAdmin = auth.currentRole == 'admin';

    final filteredItems = _applyExtraFilters(rt.dispositivosFiltrados);
    final totalItems = filteredItems.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999999);
    final currentPage = _pagina.clamp(1, totalPages);
    final startIdx = (currentPage - 1) * _itemsPerPage;
    final pageItems = filteredItems.skip(startIdx).take(_itemsPerPage).toList();
    final filtrando = rt.query.isNotEmpty ||
        _filterCategoria.isNotEmpty ||
        _filterFamilia.isNotEmpty ||
        _filterProduto.isNotEmpty ||
        _filterProcesso.isNotEmpty ||
        _filterCodigo.isNotEmpty ||
        _filterDescricao.isNotEmpty;

    final subtitulo = '$totalItems dispositivo${totalItems == 1 ? '' : 's'} '
        '${filtrando ? 'encontrado${totalItems == 1 ? '' : 's'}' : 'cadastrado${totalItems == 1 ? '' : 's'}'}';

    final nomesCat = rt.nomesClassificacao;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dispositivos',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800)),
                      Text(subtitulo,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canCadastrar)
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _isImportOpen = true),
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('Importar'),
                        ),
                      const SizedBox(width: 8),
                      if (isAdmin)
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _isDuplicadosOpen = true),
                          icon: const Icon(Icons.copy_all, size: 18),
                          label: const Text('Duplicados'),
                        ),
                      const SizedBox(width: 8),
                      if (canCadastrar)
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(10),
                          ),
                          child: const Icon(Icons.add, size: 20),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Search bar + filtros
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingXl),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome, código ou descrição…',
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: Color(0xFF9ca3af)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    icon: const Icon(Icons.filter_list, size: 16),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Filtros'),
                        const SizedBox(width: 4),
                        Icon(
                          _showFilters
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 14,
                        ),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      fixedSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),

            // Painel de filtros
            if (_showFilters)
              Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterDropdown(
                      label: 'Categoria',
                      value: _filterCategoria,
                      items: rt.categorias
                          .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.nome ?? 'Sem nome')))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _filterCategoria = v ?? ''),
                    ),
                    const SizedBox(height: 8),
                    _FilterDropdown(
                      label: 'Família',
                      value: _filterFamilia,
                      items: rt.familias
                          .map((f) => DropdownMenuItem(
                              value: f.id, child: Text(f.nome)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _filterFamilia = v ?? ''),
                    ),
                    const SizedBox(height: 8),
                    _FilterDropdown(
                      label: 'Produto',
                      value: _filterProduto,
                      items: rt.produtos
                          .map((p) => DropdownMenuItem(
                              value: p.id, child: Text(p.nome)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _filterProduto = v ?? ''),
                    ),
                    const SizedBox(height: 8),
                    _FilterField(
                      label: 'Código da peça',
                      value: _filterCodigo,
                      onChanged: (v) =>
                          setState(() => _filterCodigo = v),
                    ),
                    const SizedBox(height: 8),
                    _FilterField(
                      label: 'Descrição da peça',
                      value: _filterDescricao,
                      onChanged: (v) =>
                          setState(() => _filterDescricao = v),
                    ),
                    const SizedBox(height: 8),
                    _FilterDropdown(
                      label: 'Processo industrial',
                      value: _filterProcesso,
                      items: const [
                        DropdownMenuItem(
                            value: 'Shotblaster',
                            child: Text('Shotblaster')),
                        DropdownMenuItem(
                            value: 'Coping', child: Text('Coping')),
                        DropdownMenuItem(
                            value: 'Sawing', child: Text('Sawing')),
                        DropdownMenuItem(
                            value: 'Drilling',
                            child: Text('Drilling')),
                      ],
                      onChanged: (v) =>
                          setState(() => _filterProcesso = v ?? ''),
                    ),
                  ],
                ),
              ),

            // Lista de dispositivos
            Expanded(
              child: rt.loading
                  ? const SkeletonList(lines: 6)
                  : filteredItems.isEmpty
                      ? EmptyState(
                          titulo: filtrando
                              ? 'Nenhum dispositivo encontrado'
                              : 'Nenhum dispositivo cadastrado',
                          descricao: filtrando
                              ? 'Nenhum dispositivo corresponde à busca ou aos filtros.'
                              : 'Cadastre um dispositivo ou importe uma planilha.',
                        )
                      : ListView.builder(
                          itemCount: pageItems.length,
                          itemBuilder: (ctx, idx) {
                            final disp = pageItems[idx];
                            final catNome = nomesCat
                                .categorias[disp.categoriaId ?? ''];
                            final famNome = nomesCat
                                .familias[disp.familiaId ?? ''];
                            final prodNome = nomesCat
                                .produtos[disp.produtoId ?? ''];

                            return InkWell(
                              onTap: () =>
                                  context.go('/dispositivos/${disp.id}'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: AppColors.border,
                                        width: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Ícone
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.hover,
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppTheme.radiusSm),
                                      ),
                                      child: const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 20,
                                          color: Color(0xFF6b7280)),
                                    ),
                                    const SizedBox(width: 16),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            crossAxisAlignment:
                                                WrapCrossAlignment
                                                    .center,
                                            children: [
                                              Text(
                                                disp.nome ??
                                                    'Nome não informado',
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color:
                                                      AppColors.textDark,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if (disp.codigo != null &&
                                                  disp.codigo!
                                                      .isNotEmpty)
                                                Text(
                                                  disp.codigo!,
                                                  style: const TextStyle(
                                                      color: Color(
                                                          0xFF6b7280),
                                                      fontSize: 13),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              if (catNome != null &&
                                                  catNome.isNotEmpty)
                                                _Badge(
                                                    text: catNome,
                                                    bgColor:
                                                        AppColors
                                                            .boxPinkBg,
                                                    textColor: AppColors
                                                        .boxPinkText),
                                              if (famNome != null &&
                                                  famNome.isNotEmpty)
                                                _Badge(
                                                    text: famNome,
                                                    bgColor:
                                                        AppColors
                                                            .boxTealBg,
                                                    textColor: AppColors
                                                        .boxTealText),
                                              if (prodNome != null &&
                                                  prodNome.isNotEmpty)
                                                _Badge(
                                                    text: prodNome,
                                                    bgColor:
                                                        AppColors
                                                            .boxBlueBg,
                                                    textColor: AppColors
                                                        .boxBlueText),
                                              if (disp.peso != null &&
                                                  disp.peso!
                                                      .isNotEmpty)
                                                Text('${disp.peso} g',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(
                                                            0xFF6b7280),
                                                        fontWeight:
                                                            FontWeight
                                                                .w500)),
                                              ...(disp.palavrasChave ??
                                                      [])
                                                  .map((tag) => _Badge(
                                                      text: tag,
                                                      bgColor: AppColors
                                                          .boxPinkBg,
                                                      textColor:
                                                          AppColors
                                                              .boxPinkText)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Ações
                                    if (canEditar)
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 18),
                                        color: AppColors.textMuted,
                                        onPressed: () {},
                                        tooltip: 'Editar',
                                      ),
                                    if (canExcluir)
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18),
                                        color: AppColors.danger,
                                        onPressed: () => setState(
                                            () => _dispToDelete = disp.id),
                                        tooltip: 'Excluir',
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Paginação
            if (filteredItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Itens por página:',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textBody)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _itemsPerPage,
                          underline: const SizedBox(),
                          isDense: true,
                          items: _tamanhosPagina
                              .map((n) => DropdownMenuItem(
                                  value: n, child: Text('$n')))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _itemsPerPage = v!;
                            _pagina = 1;
                          }),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          onPressed: currentPage > 1
                              ? () => setState(() => _pagina--)
                              : null,
                        ),
                        Text('$currentPage de $totalPages',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          onPressed: currentPage < totalPages
                              ? () => setState(() => _pagina++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),

        // Delete confirmation modal
        if (_dispToDelete != null)
          AccessibleModal(
            title: 'Confirmar exclusão',
            onClose: _isDeleting ? null : () => setState(() => _dispToDelete = null),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tem certeza que deseja remover este dispositivo?'),
                const SizedBox(height: AppTheme.spacingLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isDeleting
                          ? null
                          : () => setState(() => _dispToDelete = null),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    ElevatedButton(
                      onPressed: _isDeleting ? null : _handleDelete,
                      child: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirmar'),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Import modal
        if (_isImportOpen)
          ImportModal(
            onClose: () => setState(() => _isImportOpen = false),
          ),

        // Duplicados modal
        if (_isDuplicadosOpen)
          DuplicadosModal(
            onClose: () => setState(() => _isDuplicadosOpen = false),
          ),

        // FAB
        if (canCadastrar)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () {},
              child: const Icon(Icons.add, size: 24),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  const _Badge(
      {required this.text, required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.textBody)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Todos'),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FilterField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.textBody)),
        const SizedBox(height: 4),
        TextField(
          onChanged: onChanged,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: 'Contém…',
          ),
        ),
      ],
    );
  }
}

