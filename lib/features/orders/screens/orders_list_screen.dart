import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/features/orders/widgets/order_card.dart';
import 'package:logistics_app/features/orders/widgets/orders_empty_state.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _refreshing = false;

  static const tabs = ['Все', 'Новые', 'Активные', 'Завершённые'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Order> _filtered(int tab) {
    final all = OrderStore.getAll();
    switch (tab) {
      case 1:
        return all.where((o) => o.status == OrderStatus.pending).toList();
      case 2:
        return all
            .where((o) =>
                o.status == OrderStatus.accepted ||
                o.status == OrderStatus.inTransit)
            .toList();
      case 3:
        return all
            .where((o) =>
                o.status == OrderStatus.delivered ||
                o.status == OrderStatus.cancelled)
            .toList();
      default:
        return all;
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.background : AppTheme.lBackground;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Заявки',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                          Text(
                            AuthState.currentUser?.name ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/orders/create'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Создать',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TabBar(
                  controller: _tabCtrl,
                  onTap: (_) => setState(() {}),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: accentColor,
                  unselectedLabelColor: secondaryText,
                  indicator: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: tabs
                      .map((t) => Tab(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Text(t),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
          body: AnimatedBuilder(
            animation: _tabCtrl,
            builder: (_, __) {
              final orders = _filtered(_tabCtrl.index);
              return RefreshIndicator(
                onRefresh: _refresh,
                color: accentColor,
                backgroundColor: surfaceColor,
                child: orders.isEmpty
                    ? const OrdersEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => OrderCard(
                          order: orders[i],
                          index: i,
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
