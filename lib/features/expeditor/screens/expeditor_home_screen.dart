import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/core/services/chat_service.dart';
import 'package:logistics_app/core/services/order_service.dart';
import 'package:logistics_app/core/widgets/app_button.dart';
import 'package:logistics_app/features/expeditor/widgets/expeditor_empty_state.dart';
import 'package:logistics_app/features/expeditor/widgets/expeditor_order_card.dart' hide ExpeditorEmptyState;


class ExpeditorHomeScreen extends StatefulWidget {
  const ExpeditorHomeScreen({super.key});

  @override
  State<ExpeditorHomeScreen> createState() => _ExpeditorHomeScreenState();
}

class _ExpeditorHomeScreenState extends State<ExpeditorHomeScreen> {
  bool _refreshing = false;
  bool _loading = true;
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final orders = await OrderService.getOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _loadData();
    if (mounted) setState(() => _refreshing = false);
  }

  void _accept(Order o) async {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await OrderService.updateOrderStatus(
        o.id,
        OrderStatus.accepted,
        expeditorId: AuthState.currentUser!.id,
        expeditorName: AuthState.currentUser!.name,
        expeditorPhone: AuthState.currentUser!.phone ?? '',
      );
      if (mounted) {
        Navigator.pop(context); // close dialog
        await _loadData(); // reload
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заявка ${o.number} принята'),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              try {
                await OrderService.updateOrderStatus(o.id, OrderStatus.cancelled);
                if (mounted) {
                  Navigator.pop(context); // close loading
                  await _loadData();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.danger),
                  );
                }
              }
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

  Future<void> _openChat(Order o) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final room = await ChatService.createRoom(
        orderId: o.id,
        orderNumber: o.number,
        expeditorId: o.expeditorId ?? '',
      );
      if (mounted) {
        Navigator.pop(context); // close dialog
        context.push('/chat/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания чата: $e')),
        );
      }
    }
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
              child: _loading 
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : RefreshIndicator(
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
                          onConfirm: () async {
                            await context.push('/expeditor/confirm/${_orders[i].id}');
                            _loadData();
                          },
                          onChat: () => _openChat(_orders[i]),
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
