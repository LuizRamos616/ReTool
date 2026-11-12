import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/retool_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/reutilizacao.dart';
import '../widgets/feedback/empty_state.dart';
import '../widgets/feedback/skeleton.dart';
import '../widgets/modals/solicitar_reutilizacao_modal.dart';
import '../widgets/modals/transicionar_reutilizacao_modal.dart';

const _porPagina = 25;
const _cartoesPorVez = 50;

final _filaProjetista = [
  ReutilizacaoStatuses.emAnaliseProjetista,
  ReutilizacaoStatuses.aguardandoNovoFiltroProjetista,
];
final _filaEngenharia = [
  ReutilizacaoStatuses.emAnaliseEngenharia,
  ReutilizacaoStatuses.reutilizacaoAprovada,
  ReutilizacaoStatuses.reutilizacaoNaoAprovada,
];

class ReutilizacoesPage extends ConsumerStatefulWidget {
  const ReutilizacoesPage({super.key});

  @override
  ConsumerState<ReutilizacoesPage> createState() => _ReutilizacoesPageState();
}

class _ReutilizacoesPageState extends ConsumerState<ReutilizacoesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filterStatus = 'todos';
  String _filterText = '';
  int _pagina = 1;
  String? _transicionandoId;
  bool _fluxoOpen = false;
  Reutilizacao? _hardSavingDe;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final rt = ref.watch(reToolProvider);
    final isProjetista = auth.currentRole == 'projetista';
    final isEngenharia = auth.currentRole == 'engenharia';
    final isAdmin = auth.currentRole == 'admin';
    final canExcluir = auth.canExcluir;

    final veFilaP = isProjetista || isAdmin;
    final veFilaE = isEngenharia || isAdmin;
    final podeHardSaving = isProjetista || isAdmin;

    final todas = rt.reutilizacoes;
    final filaP = todas
        .where((r) => _filaProjetista.contains(r.status))
        .toList();
    final filaE = todas
        .where((r) => _filaEngenharia.contains(r.status))
        .toList();

    // Histórico: filtra e pagina
    final q = _filterText.toLowerCase();
    var historico = todas.toList();
    if (_filterStatus != 'todos') {
      historico = historico.where((r) => r.status == _filterStatus).toList();
    }
    if (q.isNotEmpty) {
      historico = historico
          .where((r) =>
              (r.descricaoAlteracao ?? '').toLowerCase().contains(q) ||
              (r.responsavel ?? '').toLowerCase().contains(q) ||
              (r.solicitanteNome ?? '').toLowerCase().contains(q) ||
              (r.codigoPeca ?? '').toLowerCase().contains(q) ||
              (r.numeroOs ?? '').toLowerCase().contains(q))
          .toList();
    }
    historico.sort((a, b) {
      final da = a.dataCriacao ?? a.data ?? '';
      final db = b.dataCriacao ?? b.data ?? '';
      return db.compareTo(da);
    });

    final totalPaginas = (historico.length / _porPagina).ceil().clamp(1, 999999);
    final paginaAtual = _pagina.clamp(1, totalPaginas);
    final histPagina =
        historico.skip((paginaAtual - 1) * _porPagina).take(_porPagina).toList();

    // Tabs dinâmicas
    final tabs = <_TabInfo>[];
    if (veFilaP)
      tabs.add(_TabInfo('Fila do Projetista', filaP.length));
    if (veFilaE)
      tabs.add(_TabInfo('Fila da Engenharia', filaE.length));
    tabs.add(_TabInfo('Histórico geral', historico.length));

    // Ajustar tab controller se necessário
    if (_tabCtrl.length != tabs.length) {
      _tabCtrl.dispose();
      _tabCtrl = TabController(length: tabs.length, vsync: this);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reutilizações',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              Row(
                children: [
                  if (canExcluir)
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.checklist, size: 16),
                      label: const Text('Ações em massa'),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            isScrollable: true,
            tabs: tabs
                .map((t) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.label),
                          if (t.count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${t.count}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                            ),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Conteúdo
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              if (veFilaP)
                _FilaView(
                  items: filaP,
                  podeHardSaving: podeHardSaving,
                  auth: auth,
                  onTransicionar: (r) =>
                      setState(() => _transicionandoId = r.id),
                  onHardSaving: (r) =>
                      setState(() => _hardSavingDe = r),
                  nomes: rt.nomesClassificacao,
                ),
              if (veFilaE)
                _FilaView(
                  items: filaE,
                  podeHardSaving: false,
                  auth: auth,
                  onTransicionar: (r) =>
                      setState(() => _transicionandoId = r.id),
                  onHardSaving: (_) {},
                  nomes: rt.nomesClassificacao,
                ),
              // Histórico
              Column(
                children: [
                  // Filtros do histórico
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() {
                              _filterText = v;
                              _pagina = 1;
                            }),
                            decoration: const InputDecoration(
                              hintText: 'Buscar no histórico…',
                              prefixIcon: Icon(Icons.search, size: 18),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filterStatus,
                          underline: const SizedBox(),
                          isDense: true,
                          items: [
                            const DropdownMenuItem(
                                value: 'todos', child: Text('Todos')),
                            ...ReutilizacaoStatuses.todos
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s)))
                          ],
                          onChanged: (v) => setState(() {
                            _filterStatus = v ?? 'todos';
                            _pagina = 1;
                          }),
                        ),
                      ],
                    ),
                  ),
                  // Tabela do histórico
                  Expanded(
                    child: histPagina.isEmpty
                        ? const EmptyState(
                            titulo: 'Nenhuma reutilização',
                            descricao:
                                'Ainda não há registros de reutilização.',
                          )
                        : ListView.builder(
                            itemCount: histPagina.length,
                            itemBuilder: (ctx, idx) {
                              final r = histPagina[idx];
                              return _ReutRow(
                                reutilizacao: r,
                                onTransicionar: () => setState(
                                    () => _transicionandoId = r.id),
                              );
                            },
                          ),
                  ),
                  // Paginação
                  if (historico.length > _porPagina)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: paginaAtual > 1
                                ? () => setState(() => _pagina--)
                                : null,
                          ),
                          Text('$paginaAtual de $totalPaginas',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: paginaAtual < totalPaginas
                                ? () => setState(() => _pagina++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Modal de transição
        if (_transicionandoId != null)
          TransicionarReutilizacaoModal(
            reutilizacaoId: _transicionandoId!,
            onClose: () => setState(() => _transicionandoId = null),
          ),
      ],
    );
  }
}

class _TabInfo {
  final String label;
  final int count;
  const _TabInfo(this.label, this.count);
}

class _FilaView extends StatelessWidget {
  final List<Reutilizacao> items;
  final bool podeHardSaving;
  final AuthState auth;
  final void Function(Reutilizacao) onTransicionar;
  final void Function(Reutilizacao) onHardSaving;
  final NomesClassificacao nomes;

  const _FilaView({
    required this.items,
    required this.podeHardSaving,
    required this.auth,
    required this.onTransicionar,
    required this.onHardSaving,
    required this.nomes,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        titulo: 'Fila vazia',
        descricao: 'Não há reutilizações pendentes nesta fila.',
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final r = items[idx];
        final status = r.status ?? '';
        final cor = corDoStatusReutilizacao(status);
        final rotulo = rotuloCurtoStatusReutilizacao(status);

        // Verificar transições permitidas
        final transicoesDisponiveis = transicoesReutilizacao[status] ?? [];
        final permicoesPermitidas = transicoesDisponiveis
            .where((t) =>
                transicaoReutilizacaoPermitida(status, t, auth.currentRole))
            .toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.descricaoAlteracao ?? 'Sem descrição',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.solicitanteNome ?? 'Desconhecido'} · ${r.dataCriacao ?? r.data ?? ''}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6b7280)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(rotulo,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cor)),
                    ),
                  ],
                ),
                if (r.hardSaving != null && r.hardSaving! > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Hard Saving: R\$ ${r.hardSaving!.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success),
                      ),
                    ],
                  ),
                ],
                if (permicoesPermitidas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: permicoesPermitidas.map((transicao) {
                      return OutlinedButton(
                        onPressed: () => onTransicionar(r),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: Text(rotuloCurtoStatusReutilizacao(transicao)),
                      );
                    }).toList(),
                  ),
                ],
                if (podeHardSaving) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => onHardSaving(r),
                    icon:
                        const Icon(Icons.monetization_on_outlined, size: 14),
                    label: const Text('Definir Hard Saving',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReutRow extends StatelessWidget {
  final Reutilizacao reutilizacao;
  final VoidCallback onTransicionar;

  const _ReutRow({required this.reutilizacao, required this.onTransicionar});

  @override
  Widget build(BuildContext context) {
    final r = reutilizacao;
    final cor = corDoStatusReutilizacao(r.status ?? '');
    final rotulo = rotuloCurtoStatusReutilizacao(r.status ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.descricaoAlteracao ?? 'Sem descrição',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                Text(
                  '${r.solicitanteNome ?? '—'} · ${r.dataCriacao ?? r.data ?? '—'}${r.numeroOs != null ? ' · OS: ${r.numeroOs}' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6b7280)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(rotulo,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cor)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 16),
            color: AppColors.textMuted,
            onPressed: onTransicionar,
            tooltip: 'Transicionar',
          ),
        ],
      ),
    );
  }
}

class NomesClassificacao {
  final Map<String, String> categorias;
  final Map<String, String> familias;
  final Map<String, String> produtos;

  const NomesClassificacao({
    this.categorias = const {},
    this.familias = const {},
    this.produtos = const {},
  });
}

