import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/services/order_service.dart';
import 'package:logistics_app/core/widgets/app_button.dart';
import 'package:logistics_app/features/orders/widgets/order_status_section.dart';
import 'package:logistics_app/features/orders/widgets/order_info_card.dart';
import 'package:logistics_app/features/orders/widgets/expeditor_card.dart';
import 'package:logistics_app/features/orders/widgets/comment_card.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await OrderService.getOrders();
      if (mounted) {
        setState(() {
          _order = orders.where((o) => o.id == widget.orderId).firstOrNull;
        });
      }
    } catch (e) {
      // Ignored for now
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _cancel() {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surfaceHigher : AppTheme.lSurface;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Отклонить заявку?',
            style: TextStyle(color: primaryText)),
        content: Text('Действие нельзя отменить.',
            style: TextStyle(color: secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Назад', style: TextStyle(color: secondaryText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_order != null) {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  await OrderService.updateOrderStatus(_order!.id, OrderStatus.cancelled);
                  if (mounted) {
                    Navigator.pop(context); // close dialog
                    _load();
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
            },
            child: Text('Отклонить', style: TextStyle(color: dangerColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.background : AppTheme.lBackground;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;

    if (_order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final o = _order!;
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: bgColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: primaryText, size: 18),
              onPressed: () => context.pop(),
            ),
            title: Text(o.number),
            actions: [
              if (o.status != OrderStatus.cancelled &&
                  o.status != OrderStatus.delivered) ...[
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: dangerColor, size: 22),
                  tooltip: 'Отклонить',
                  onPressed: _cancel,
                ),
              ],
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                OrderStatusSection(order: o),
                const SizedBox(height: 20),
                OrderInfoCard(order: o),
                const SizedBox(height: 16),
                if (o.expeditorName != null) ...[
                  ExpeditorCard(order: o, onCall: _call),
                  const SizedBox(height: 16),
                ],
                if (o.comment != null && o.comment!.isNotEmpty) ...[
                  CommentCard(comment: o.comment!),
                  const SizedBox(height: 16),
                ],
                AppButton(
                  label: 'Открыть маршрут на карте',
                  icon: Icons.map_outlined,
                  isPrimary: false,
                  width: double.infinity,
                  onPressed: () => context.push('/map/${o.id}'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
