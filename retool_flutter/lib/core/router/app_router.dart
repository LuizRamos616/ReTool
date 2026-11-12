import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/user.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/dispositivos_page.dart';
import '../../presentation/pages/dispositivo_details_page.dart';
import '../../presentation/pages/categorias_page.dart';
import '../../presentation/pages/reutilizacoes_page.dart';
import '../../presentation/pages/administracao_page.dart';
import '../../presentation/pages/sobre_page.dart';
import '../../presentation/pages/aguardando_aprovacao_page.dart';
import '../../presentation/pages/troca_senha_obrigatoria_page.dart';
import '../../presentation/widgets/layout/app_layout.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RiverpodRefreshListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.loading) return null;

      final tela = auth.tela;
      final path = state.uri.path;

      if (tela == TelaDaSessao.login) {
        if (path != '/login') return '/login';
        return null;
      }

      if (tela == TelaDaSessao.aguardandoAprovacao) {
        if (path != '/aguardando-aprovacao') return '/aguardando-aprovacao';
        return null;
      }

      if (tela == TelaDaSessao.trocaSenha) {
        if (path != '/troca-senha') return '/troca-senha';
        return null;
      }

      // Sistema autenticado
      if (path == '/login' || path == '/aguardando-aprovacao' || path == '/troca-senha') {
        return '/dispositivos';
      }

      // Guardas de Cargo (RBAC)
      if (path == '/categorias' && !['admin', 'projetista'].contains(auth.currentRole)) {
        return '/dispositivos';
      }

      if (path.startsWith('/administracao') && auth.currentRole != 'admin') {
        return '/dispositivos';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/aguardando-aprovacao',
        builder: (context, state) => const AguardandoAprovacaoPage(),
      ),
      GoRoute(
        path: '/troca-senha',
        builder: (context, state) => const TrocaSenhaObrigatoriaPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppLayout(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/sobre',
            builder: (context, state) => const SobrePage(),
          ),
          GoRoute(
            path: '/dispositivos',
            builder: (context, state) => const DispositivosPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => DispositivoDetailsPage(
                  id: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/categorias',
            builder: (context, state) => const CategoriasPage(),
          ),
          GoRoute(
            path: '/reutilizacoes',
            builder: (context, state) => const ReutilizacoesPage(),
          ),
          GoRoute(
            path: '/administracao',
            builder: (context, state) => AdministracaoPage(
              aba: state.uri.queryParameters['aba'],
            ),
          ),
        ],
      ),
    ],
  );
});

class _RiverpodRefreshListenable extends ChangeNotifier {
  _RiverpodRefreshListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

