import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/solicitacao_cargo.dart';
import '../modals/alterar_cargo_modal.dart';

class UserNavMenu extends ConsumerStatefulWidget {
  const UserNavMenu({super.key});

  @override
  ConsumerState<UserNavMenu> createState() => _UserNavMenuState();
}

class _UserNavMenuState extends ConsumerState<UserNavMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    final auth = ref.read(authProvider);
    final user = auth.userProfile;
    final role = auth.roleConfig;
    final temPendente = auth.solicitacoesCargo.any(
      (s) => s.usuarioUid == user?.uid && s.status == SolicitacaoCargoStatuses.pendente,
    );
    final podePedirCargo = podeSolicitarAlteracaoCargo(user);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
            ),
          ),
          Positioned(
            width: 260,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 48),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.nome ?? 'Usuário',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(int.parse(role.badgeBg.replaceFirst('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                role.tituloCurto,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(int.parse(role.badgeText.replaceFirst('#', '0xFF'))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (podePedirCargo)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.swap_horiz_rounded, size: 18),
                          title: Text(
                            temPendente ? 'Alteração de cargo (pendente)' : 'Solicitar alteração de cargo',
                            style: const TextStyle(fontSize: 13),
                          ),
                          enabled: !temPendente,
                          onTap: () {
                            _closeDropdown();
                            showDialog(
                              context: context,
                              builder: (_) => const AlterarCargoModal(),
                            );
                          },
                        ),
                      if (auth.canGerenciarUsuarios)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                          title: const Text('Administração', style: TextStyle(fontSize: 13)),
                          onTap: () {
                            _closeDropdown();
                            context.go('/administracao');
                          },
                        ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                        title: const Text(
                          'Sair do sistema',
                          style: TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w500),
                        ),
                        onTap: () async {
                          _closeDropdown();
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.userProfile;
    final role = auth.roleConfig;

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    try {
      badgeBg = Color(int.parse(role.badgeBg.replaceFirst('#', '0xFF')));
      badgeBorder = Color(int.parse(role.borderColor.replaceFirst('#', '0xFF')));
      badgeText = Color(int.parse(role.badgeText.replaceFirst('#', '0xFF')));
    } catch (_) {
      badgeBg = AppColors.gray03;
      badgeBorder = AppColors.border;
      badgeText = AppColors.textDark;
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: badgeBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: Text(
                  (user?.nome.isNotEmpty == true ? user!.nome[0] : 'U').toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeText),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.nome ?? 'Convidado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      role.tituloCurto,
                      style: TextStyle(
                        fontSize: 10,
                        color: badgeText.withOpacity(0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: badgeText),
            ],
          ),
        ),
      ),
    );
  }
}

