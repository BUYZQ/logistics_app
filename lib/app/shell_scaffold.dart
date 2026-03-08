import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/core/services/chat_service.dart';

class ShellScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ShellScaffold({super.key, required this.navigationShell});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    ChatService.unreadCountNotifier.addListener(_onUnreadChanged);
  }

  void _onUnreadChanged() {
    if (mounted) {
      setState(() {
        _unreadCount = ChatService.unreadCountNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    ChatService.unreadCountNotifier.removeListener(_onUnreadChanged);
    super.dispose();
  }

  Future<void> _loadUnread() async {
    try {
      final rooms = await ChatService.getRooms();
      if (mounted) {
        setState(() {
          _unreadCount = rooms.fold(0, (sum, r) => sum + r.unreadCount);
        });
      }
    } catch (_) {}
  }

  List<_NavItem> get _items {
    final isOperator = AuthState.currentUser?.role == UserRole.operator;
    final unread = _unreadCount;

    if (isOperator) {
      return [
        _NavItem(icon: Icons.list_alt_rounded, label: 'Заявки'),
        _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Чат', badge: unread),
        _NavItem(icon: Icons.person_outline_rounded, label: 'Профиль'),
      ];
    } else {
      return [
        _NavItem(icon: Icons.inventory_2_outlined, label: 'Заявки'),
        _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Чат', badge: unread),
        _NavItem(icon: Icons.person_outline_rounded, label: 'Профиль'),
      ];
    }
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lDivider;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: dividerColor, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final selected = widget.navigationShell.currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? accentColor.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: selected ? accentColor : secondaryText,
                                  size: 22,
                                ),
                              ),
                              if (item.badge > 0)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: dangerColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${item.badge}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: selected ? accentColor : secondaryText,
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.label,
    this.badge = 0,
  });
}
