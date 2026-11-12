import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notificacao.dart';

class NotificationsMenu extends ConsumerStatefulWidget {
  final bool alignRight;
  const NotificationsMenu({super.key, this.alignRight = true});

  @override
  ConsumerState<NotificationsMenu> createState() => _NotificationsMenuState();
}

class _NotificationsMenuState extends ConsumerState<NotificationsMenu> {
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
    final notifications = ref.read(authProvider).notifications;

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
            width: 320,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(widget.alignRight ? -280 : 0, 44),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notificações',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            Text(
                              '${notifications.where((n) => !n.lida).length} não lidas',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (notifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhuma notificação recebida.',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final n = notifications[index];
                              return ListTile(
                                dense: true,
                                tileColor: n.lida ? Colors.transparent : AppColors.gray03.withOpacity(0.3),
                                title: Text(
                                  n.titulo,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: n.lida ? FontWeight.w500 : FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  n.descricao,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: n.lida
                                    ? null
                                    : Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                onTap: () async {
                                  await ref.read(authProvider.notifier).marcarNotificacaoLida(n.id, true);
                                  _closeDropdown();
                                  if (n.dispositivoId != null && n.dispositivoId!.isNotEmpty) {
                                    if (context.mounted) context.go('/dispositivos/${n.dispositivoId}');
                                  } else if (n.tipo.startsWith('reutilizacao')) {
                                    if (context.mounted) context.go('/reutilizacoes');
                                  } else if (n.tipo.startsWith('conta_') || n.tipo.startsWith('cargo_')) {
                                    if (context.mounted) context.go('/administracao');
                                  }
                                },
                              );
                            },
                          ),
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
    final notifications = ref.watch(authProvider.select((s) => s.notifications));
    final unread = notifications.where((n) => !n.lida).length;

    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.textDark),
            if (unread > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        onPressed: _toggleDropdown,
        tooltip: 'Notificações',
      ),
    );
  }
}

