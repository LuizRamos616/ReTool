import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/retool_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/familia.dart';
import '../../domain/entities/produto.dart';
import '../widgets/feedback/empty_state.dart';
import '../widgets/modals/accessible_modal.dart';

class CategoriasPage extends ConsumerStatefulWidget {
  const CategoriasPage({super.key});

  @override
  ConsumerState<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends ConsumerState<CategoriasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _editingId;
  final _nomeCtrl = TextEditingController();
  bool _salvando = false;
  String? _erro;
  String? _excluindo;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nomeCtrl.dispose();
    super.dispose();
  }

  void _iniciarEdicao(String? id, String nomeAtual) {
    setState(() {
      _editingId = id;
      _nomeCtrl.text = nomeAtual;
      _erro = null;
    });
  }

  Future<void> _salvar(int tabIndex) async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'O nome não pode estar vazio.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final notifier = ref.read(reToolProvider.notifier);
      if (tabIndex == 0) {
        if (_editingId != null) {
          await notifier.updateCategoria(_editingId!, nome);
        } else {
          await notifier.addCategoria(nome);
        }
      } else if (tabIndex == 1) {
        if (_editingId != null) {
          await notifier.updateFamilia(_editingId!, nome);
        } else {
          await notifier.addFamilia(nome);
        }
      } else {
        if (_editingId != null) {
          await notifier.updateProduto(_editingId!, nome);
        } else {
          await notifier.addProduto(nome);
        }
      }
      _nomeCtrl.clear();
      setState(() {
        _editingId = null;
        _salvando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _salvando = false;
      });
    }
  }

  Future<void> _excluir(int tabIndex, String id) async {
    setState(() => _excluindo = id);
    try {
      final notifier = ref.read(reToolProvider.notifier);
      if (tabIndex == 0) {
        await notifier.deleteCategoria(id);
      } else if (tabIndex == 1) {
        await notifier.deleteFamilia(id);
      } else {
        await notifier.deleteProduto(id);
      }
    } catch (_) {}
    if (mounted) setState(() => _excluindo = null);
  }

  @override
  Widget build(BuildContext context) {
    final rt = ref.watch(reToolProvider);
    final auth = ref.watch(authProvider);
    final canEditar = auth.canEditar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        const Padding(
          padding: EdgeInsets.only(bottom: AppTheme.spacingLg),
          child: Text('Classificações',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        ),

        // Tabs
        Container(
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                  text:
                      'Categorias (${rt.categorias.length})'),
              Tab(text: 'Famílias (${rt.familias.length})'),
              Tab(text: 'Produtos (${rt.produtos.length})'),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Form de adição/edição
        if (canEditar) ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nomeCtrl,
                    decoration: InputDecoration(
                      hintText: _editingId != null
                          ? 'Editar nome…'
                          : 'Novo nome…',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      errorText: _erro,
                    ),
                    onSubmitted: (_) => _salvar(_tabCtrl.index),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _salvando ? null : () => _salvar(_tabCtrl.index),
                  child: _salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_editingId != null ? 'Atualizar' : 'Adicionar'),
                ),
                if (_editingId != null) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => setState(() {
                      _editingId = null;
                      _nomeCtrl.clear();
                      _erro = null;
                    }),
                    child: const Text('Cancelar'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],

        // Conteúdo da aba
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ClassificacaoList<Categoria>(
                items: rt.categorias,
                getName: (c) => c.nome ?? 'Sem nome',
                getId: (c) => c.id,
                getAtivo: (c) => c.ativo ?? true,
                canEditar: canEditar,
                onEdit: (c) => _iniciarEdicao(c.id, c.nome ?? ''),
                onDelete: (c) => _excluir(0, c.id),
                excluindo: _excluindo,
              ),
              _ClassificacaoList<Familia>(
                items: rt.familias,
                getName: (f) => f.nome,
                getId: (f) => f.id,
                getAtivo: (f) => f.ativo ?? true,
                canEditar: canEditar,
                onEdit: (f) => _iniciarEdicao(f.id, f.nome),
                onDelete: (f) => _excluir(1, f.id),
                excluindo: _excluindo,
              ),
              _ClassificacaoList<Produto>(
                items: rt.produtos,
                getName: (p) => p.nome,
                getId: (p) => p.id,
                getAtivo: (p) => p.ativo ?? true,
                canEditar: canEditar,
                onEdit: (p) => _iniciarEdicao(p.id, p.nome),
                onDelete: (p) => _excluir(2, p.id),
                excluindo: _excluindo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClassificacaoList<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) getName;
  final String Function(T) getId;
  final bool Function(T) getAtivo;
  final bool canEditar;
  final void Function(T) onEdit;
  final void Function(T) onDelete;
  final String? excluindo;

  const _ClassificacaoList({
    super.key,
    required this.items,
    required this.getName,
    required this.getId,
    required this.getAtivo,
    required this.canEditar,
    required this.onEdit,
    required this.onDelete,
    this.excluindo,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        titulo: 'Nenhum item cadastrado',
        descricao: 'Adicione o primeiro item usando o campo acima.',
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        final id = getId(item);
        final nome = getName(item);
        final ativo = getAtivo(item);
        final deletando = excluindo == id;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(nome,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: ativo
                              ? AppColors.textDark
                              : AppColors.textMuted,
                          decoration:
                              ativo ? null : TextDecoration.lineThrough,
                        )),
                    if (!ativo) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.boxYellowBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Inativo',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.boxYellowText,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
              if (canEditar) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  color: AppColors.textMuted,
                  onPressed: () => onEdit(item),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: deletando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete_outline, size: 16),
                  color: AppColors.danger,
                  onPressed: deletando ? null : () => onDelete(item),
                  tooltip: 'Excluir',
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

