import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/core/services/chat_service.dart';

class ShellScaffold extends StatefulWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  int _selectedIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
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
        _NavItem(icon: Icons.list_alt_rounded, label: 'Заявки', path: '/orders'),
        _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Чат', path: '/chat', badge: unread),
        _NavItem(icon: Icons.person_outline_rounded, label: 'Профиль', path: '/profile'),
      ];
    } else {
      return [
        _NavItem(icon: Icons.inventory_2_outlined, label: 'Заявки', path: '/expeditor'),
        _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Чат', path: '/chat', badge: unread),
        _NavItem(icon: Icons.person_outline_rounded, label: 'Профиль', path: '/profile'),
      ];
    }
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(_items[index].path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _items.indexWhere((i) => i.path == location);
    if (idx != -1) _selectedIndex = idx;
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
      body: widget.child,
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
                final selected = _selectedIndex == i;
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
  final String path;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    this.badge = 0,
  });
}
