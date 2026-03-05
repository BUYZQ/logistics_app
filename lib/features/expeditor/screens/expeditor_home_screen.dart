import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/features/expeditor/widgets/expeditor_order_card.dart';

class ExpeditorHomeScreen extends StatefulWidget {
  const ExpeditorHomeScreen({super.key});

  @override
  State<ExpeditorHomeScreen> createState() => _ExpeditorHomeScreenState();
}

class _ExpeditorHomeScreenState extends State<ExpeditorHomeScreen> {
  bool _refreshing = false;

  List<Order> get _orders =>
      OrderStore.getForExpeditor(AuthState.currentUser!.id);

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _refreshing = false);
  }

  void _accept(Order o) {
    final updated = o.copyWith(
      status: OrderStatus.accepted,
      expeditorId: AuthState.currentUser!.id,
      expeditorName: AuthState.currentUser!.name,
      expeditorPhone: AuthState.currentUser!.phone ?? '',
    );
    OrderStore.updateOrder(updated);
    setState(() {});
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Заявка ${o.number} принята'),
        backgroundColor: successColor,
      ),
    );
  }

  void _reject(Order o) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surfaceHigher : AppTheme.lSurface;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Отклонить заявку?',
            style: TextStyle(color: primaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Назад', style: TextStyle(color: secondaryText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              OrderStore.updateOrder(
                  o.copyWith(status: OrderStatus.cancelled));
              setState(() {});
            },
            child: Text('Отклонить', style: TextStyle(color: dangerColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.background : AppTheme.lBackground;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Мои заявки',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: primaryText)),
                  Text(AuthState.currentUser?.name ?? '',
                      style: TextStyle(fontSize: 13, color: secondaryText)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: accentColor,
                backgroundColor: surfaceColor,
                child: _orders.isEmpty
                    ? const ExpeditorEmptyState()
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => ExpeditorOrderCard(
                          order: _orders[i],
                          index: i,
                          onAccept: () => _accept(_orders[i]),
                          onReject: () => _reject(_orders[i]),
                          onCall: () {
                            final phone = _orders[i].expeditorPhone ?? '';
                            if (phone.isNotEmpty) _call(phone);
                          },
                          onMap: () =>
                              context.push('/map/${_orders[i].id}'),
                          onConfirm: () => context.push(
                              '/expeditor/confirm/${_orders[i].id}'),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
