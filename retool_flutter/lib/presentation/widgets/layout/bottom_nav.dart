import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final location = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (location.startsWith('/dispositivos')) {
      currentIndex = 1;
    } else if (location.startsWith('/reutilizacoes')) {
      currentIndex = 2;
    } else if (location.startsWith('/categorias')) {
      currentIndex = 3;
    } else if (location.startsWith('/administracao')) {
      currentIndex = (auth.canCadastrar || auth.canEditar) ? 4 : 3;
    }

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.widgets_outlined),
        activeIcon: Icon(Icons.widgets_rounded),
        label: 'Dispositivos',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.format_list_bulleted_rounded),
        activeIcon: Icon(Icons.format_list_bulleted_rounded),
        label: 'Reutilizações',
      ),
      if (auth.canCadastrar || auth.canEditar)
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings_rounded),
          label: 'Classificações',
        ),
      if (auth.canGerenciarUsuarios)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Admin',
        ),
    ];

    if (currentIndex >= items.length) currentIndex = 0;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.gray01,
      backgroundColor: Colors.white,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        if (index == 0) context.go('/');
        if (index == 1) context.go('/dispositivos');
        if (index == 2) context.go('/reutilizacoes');
        if (index == 3) {
          if (auth.canCadastrar || auth.canEditar) {
            context.go('/categorias');
          } else if (auth.canGerenciarUsuarios) {
            context.go('/administracao');
          }
        }
        if (index == 4 && auth.canGerenciarUsuarios) {
          context.go('/administracao');
        }
      },
      items: items,
    );
  }
}

