import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'sidebar.dart';
import 'bottom_nav.dart';
import 'user_nav_menu.dart';
import 'notifications_menu.dart';
import '../feedback/toast_overlay.dart';

class AppLayout extends ConsumerWidget {
  final Widget child;
  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isFullScreenMode = location == '/' || location == '/sobre';
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isFullScreenMode) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: child),
            // Top Right Profile Badge in Fullscreen mode
            Positioned(
              top: 16,
              right: 24,
              child: SizedBox(
                width: 280,
                child: Row(
                  children: const [
                    Expanded(child: UserNavMenu()),
                    SizedBox(width: 8),
                    NotificationsMenu(alignRight: true),
                  ],
                ),
              ),
            ),
            const ToastOverlay(),
          ],
        ),
        bottomNavigationBar: isMobile ? const BottomNav() : null,
      );
    }

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
              children: [
                TextSpan(text: 'Re', style: TextStyle(color: Color(0xFF4A4A4A))),
                TextSpan(text: 'Tool', style: TextStyle(color: Color(0xFFE40D2C))),
              ],
            ),
          ),
          actions: const [
            NotificationsMenu(alignRight: true),
            SizedBox(width: 8),
            UserNavMenu(),
            SizedBox(width: 12),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(child: child),
            const ToastOverlay(),
          ],
        ),
        bottomNavigationBar: const BottomNav(),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              const Sidebar(),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: child,
                ),
              ),
            ],
          ),
          const ToastOverlay(),
        ],
      ),
    );
  }
}

