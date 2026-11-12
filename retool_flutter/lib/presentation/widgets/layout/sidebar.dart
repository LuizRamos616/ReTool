import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'user_nav_menu.dart';
import 'notifications_menu.dart';
import '../versao_sistema.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: AppTheme.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo ReTool
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
              children: [
                TextSpan(text: 'Re', style: TextStyle(color: AppColors.graySteel)),
                TextSpan(text: 'Tool', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // User Profile + Notifications
          const Row(
            children: [
              Expanded(child: UserNavMenu()),
              SizedBox(width: 6),
              NotificationsMenu(alignRight: false),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Menu de Navegação
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SidebarItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  shortcut: 'H',
                  selected: location == '/',
                  onTap: () => context.go('/'),
                ),
                _SidebarItem(
                  icon: Icons.widgets_outlined,
                  label: 'Dispositivos',
                  shortcut: 'D',
                  selected: location.startsWith('/dispositivos'),
                  onTap: () => context.go('/dispositivos'),
                ),
                _SidebarItem(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Reutilizações',
                  shortcut: 'U',
                  selected: location.startsWith('/reutilizacoes'),
                  onTap: () => context.go('/reutilizacoes'),
                ),
                if (auth.canCadastrar || auth.canEditar)
                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    label: 'Classificações',
                    shortcut: 'C',
                    selected: location.startsWith('/categorias'),
                    onTap: () => context.go('/categorias'),
                  ),
                if (auth.canGerenciarUsuarios)
                  _SidebarItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Administração',
                    shortcut: 'A',
                    selected: location.startsWith('/administracao'),
                    badge: auth.users.where((u) => u.statusAprovacao == 'pendente').length +
                        auth.solicitacoesCargo.where((s) => s.status == 'pendente').length,
                    onTap: () => context.go('/administracao'),
                  ),
              ],
            ),
          ),

          // Atalhos
          const _AtalhosTeclado(),
          const Divider(height: 1),
          const VersaoSistema(),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.shortcut,
    required this.selected,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.gray03 : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.textDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (shortcut != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gray03,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shortcut!,
                      style: const TextStyle(fontSize: 10, color: AppColors.gray01, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AtalhosTeclado extends StatelessWidget {
  const _AtalhosTeclado();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text(
          'Atalhos de teclado',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray01),
        ),
        children: const [
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                _LinhaAtalho(tecla: '/', descricao: 'Buscar'),
                _LinhaAtalho(tecla: 'E', descricao: 'Editar'),
                _LinhaAtalho(tecla: 'D', descricao: 'Excluir'),
                _LinhaAtalho(tecla: 'Esc', descricao: 'Fechar'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaAtalho extends StatelessWidget {
  final String tecla;
  final String descricao;
  const _LinhaAtalho({required this.tecla, required this.descricao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gray03,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(tecla, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(descricao, style: const TextStyle(fontSize: 12, color: AppColors.gray01)),
        ],
      ),
    );
  }
}

