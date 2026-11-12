import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/retool_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/services/busca_dispositivos.dart';
import '../widgets/feedback/skeleton.dart';
import 'package:url_launcher/url_launcher.dart';

/// Partículas da explosão do botão de bug report.
class _BugParticle {
  final int id;
  final double x, y, size;
  final Color color;
  const _BugParticle(this.id, this.x, this.y, this.size, this.color);
}

const _bugParticles = [
  _BugParticle(1, -50, -25, 12, Color(0xFF1f2937)),
  _BugParticle(2, 40, -40, 10, AppColors.primary),
  _BugParticle(3, -60, 15, 14, Color(0xFF1f2937)),
  _BugParticle(4, 55, 25, 16, AppColors.primary),
  _BugParticle(5, 10, -60, 18, Color(0xFF1f2937)),
  _BugParticle(6, -30, 50, 10, AppColors.primary),
  _BugParticle(7, 35, 55, 12, Color(0xFF1f2937)),
  _BugParticle(8, -15, 35, 14, AppColors.primary),
  _BugParticle(9, 70, -15, 8, Color(0xFF1f2937)),
  _BugParticle(10, -70, -35, 12, AppColors.primary),
  _BugParticle(11, -20, -45, 14, Color(0xFF1f2937)),
  _BugParticle(12, 25, -25, 16, AppColors.primary),
];

const _maxSugestoes = 8;
const _bugReportUrl =
    'https://docs.google.com/forms/d/e/1FAIpQLSdjL1QGliGpivKDGh0F9frKXchfo5gdtF5kTEpKOBVS7VpuIw/viewform';

enum _BugState { visible, exploding, hidden, reassembling }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  final _queryCtrl = TextEditingController();
  final _focusNode = FocusNode();

  String _query = '';
  String _consulta = '';
  int _activeIndex = -1;
  bool _showSuggestions = false;
  Timer? _debounce;
  _BugState _bugState = _BugState.visible;
  bool _bugHovered = false;
  AnimationController? _explosionCtrl;

  int? _totalReutilizacoes;
  bool _reutErro = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _explosionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _carregarTotais();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _explosionCtrl?.dispose();
    super.dispose();
  }

  Future<void> _carregarTotais() async {
    try {
      final repo = ref.read(reutilizacoesRepoProvider);
      final total = await repo.contar();
      if (mounted) setState(() => _totalReutilizacoes = total);
    } catch (_) {
      if (mounted) setState(() => _reutErro = true);
    }
  }

  void _onQueryChanged(String val) {
    setState(() {
      _query = val;
      _activeIndex = -1;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _consulta = val);
    });
  }

  List<EntradaIndice> _getSugestoes() {
    if (_consulta.trim().isEmpty) return [];
    final rt = ref.read(reToolProvider);
    final nomes = rt.nomesClassificacao;
    final preparadas = prepararEntradas(rt.entradasIndice, nomes);
    final filtradas = filtrarEntradas(
      preparadas,
      FiltroBusca(texto: _consulta),
    );
    return filtradas.take(_maxSugestoes).toList();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final sugestoes = _getSugestoes();
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _activeIndex = min(_activeIndex + 1, sugestoes.length - 1));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _activeIndex = max(_activeIndex - 1, -1));
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_activeIndex >= 0 && _activeIndex < sugestoes.length) {
        context.go('/dispositivos/${sugestoes[_activeIndex].id}');
      } else {
        context.go('/dispositivos?q=${Uri.encodeComponent(_query)}');
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _showSuggestions = false;
        _activeIndex = -1;
      });
    }
  }

  void _handleBugClick() {
    setState(() {
      _bugState = _BugState.exploding;
      _bugHovered = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      launchUrl(Uri.parse(_bugReportUrl), mode: LaunchMode.externalApplication);
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _bugState = _BugState.hidden);
      Future.delayed(const Duration(milliseconds: 4400), () {
        if (!mounted) return;
        setState(() => _bugState = _BugState.reassembling);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() => _bugState = _BugState.visible);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final rt = ref.watch(reToolProvider);
    final canCadastrar = auth.canCadastrar;
    final canEditar = auth.canEditar;
    final sugestoes = _getSugestoes();
    final totalDispositivos = rt.dispositivos.length;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        // Marca d'água
        Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.precision_manufacturing,
                  size: MediaQuery.of(context).size.width * 0.7,
                  color: AppColors.graySteel),
            ),
          ),
        ),

        // Conteúdo principal centralizado
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título ReTool
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: 'Re',
                        style: TextStyle(color: AppColors.graySteel),
                      ),
                      TextSpan(
                        text: 'Tool',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Campo de busca principal
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    children: [
                      KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: _handleKeyEvent,
                        child: TextField(
                          controller: _queryCtrl,
                          focusNode: _focusNode,
                          onChanged: _onQueryChanged,
                          onTap: () =>
                              setState(() => _showSuggestions = true),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nome, código ou descrição…',
                            prefixIcon: const Icon(Icons.search,
                                size: 20, color: Color(0xFF9ca3af)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),

                      // Dropdown de sugestões
                      if (_showSuggestions && sugestoes.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radius),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: sugestoes.length,
                            itemBuilder: (ctx, idx) {
                              final item = sugestoes[idx];
                              final isActive = _activeIndex == idx;
                              return InkWell(
                                onTap: () => context
                                    .go('/dispositivos/${item.id}'),
                                onHover: (_) =>
                                    setState(() => _activeIndex = idx),
                                child: Container(
                                  color: isActive
                                      ? AppColors.hover
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search,
                                          size: 14,
                                          color: Color(0xFF9ca3af)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.nome.isNotEmpty
                                              ? item.nome
                                              : 'Nome não informado',
                                          style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Text(item.codigo,
                                          style: const TextStyle(
                                              color: Color(0xFF6b7280),
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      if (_showSuggestions &&
                          sugestoes.isEmpty &&
                          _consulta.trim().isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radius),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Nenhum dispositivo encontrado para "$_consulta".',
                            style: const TextStyle(
                                color: Color(0xFF6b7280), fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Botão "Novo dispositivo"
                if (canCadastrar)
                  ElevatedButton.icon(
                    onPressed: () => context.go('/dispositivos'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Novo dispositivo'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                    ),
                  ),
                const SizedBox(height: AppTheme.spacing2Xl),

                // Cartões de atalho
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HomeCard(
                        count: totalDispositivos,
                        label: 'Dispositivos',
                        shortcut: 'D',
                        icon: Icons.inventory_2_outlined,
                        onTap: () => context.go('/dispositivos'),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      _HomeCard(
                        count: _reutErro ? -1 : _totalReutilizacoes,
                        label: 'Reutilizações',
                        shortcut: 'U',
                        icon: Icons.build_outlined,
                        onTap: () => context.go('/reutilizacoes'),
                      ),
                      if (canCadastrar || canEditar) ...[
                        const SizedBox(width: AppTheme.spacingMd),
                        _HomeCard(
                          count: rt.categorias.length,
                          label: 'Categorias',
                          shortcut: 'C',
                          icon: Icons.label_outline,
                          onTap: () => context.go('/categorias'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Botão "Sobre o projeto" - top left
        Positioned(
          top: AppTheme.spacingXl,
          left: AppTheme.spacingXl,
          child: TextButton.icon(
            onPressed: () => context.go('/sobre'),
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Sobre o projeto'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textBody,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),

        // Atalho "/" (footer)
        if (!isMobile)
          Positioned(
            bottom: AppTheme.spacingXl,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.hover,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('/',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF6b7280))),
                  ),
                  const SizedBox(width: 4),
                  const Text('busca em qualquer tela',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF6b7280))),
                ],
              ),
            ),
          ),

        // Bug report FAB
        Positioned(
          bottom: AppTheme.spacingXl,
          right: AppTheme.spacingXl,
          child: MouseRegion(
            onEnter: (_) => setState(() => _bugHovered = true),
            onExit: (_) => setState(() => _bugHovered = false),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Tooltip pill
                  if (_bugHovered && _bugState == _BugState.visible)
                    Positioned(
                      right: 60,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1f2937),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text('Encontrou algum bug?',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),

                  // Particles
                  if (_bugState == _BugState.exploding ||
                      _bugState == _BugState.reassembling)
                    ..._bugParticles.map((p) => TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: _bugState == _BugState.exploding ? 0.0 : 1.0,
                            end: _bugState == _BugState.exploding ? 1.0 : 0.0,
                          ),
                          duration: const Duration(milliseconds: 600),
                          builder: (_, progress, __) => Positioned(
                            left: 24 - p.size / 2 + p.x * progress,
                            top: 24 - p.size / 2 + p.y * progress,
                            child: Container(
                              width: p.size,
                              height: p.size,
                              decoration: BoxDecoration(
                                color: p.color.withOpacity(1 - progress * 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )),

                  // Actual button
                  if (_bugState == _BugState.visible)
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _handleBugClick,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.bug_report,
                              size: 22, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeCard extends StatelessWidget {
  final int? count;
  final String label;
  final String shortcut;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeCard({
    required this.count,
    required this.label,
    required this.shortcut,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.primary.withOpacity(0.1);
    const textColor = AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        height: 140,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: textColor),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24,
                  child: count == null
                      ? const SkeletonLine(width: 56, height: 22)
                      : count == -1
                          ? const Text('—',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: textColor))
                          : Text(
                              count.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1,
                              ),
                            ),
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

