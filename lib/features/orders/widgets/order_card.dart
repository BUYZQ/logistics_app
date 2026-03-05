import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/widgets/status_badge.dart';
import 'package:logistics_app/features/orders/widgets/route_row.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final int index;

  const OrderCard({super.key, required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => context.push('/orders/${order.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.number,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: primaryText,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(status: order.status, small: true),
                ],
              ),
              const SizedBox(height: 10),
              RouteRow(from: order.fromAddress, to: order.toAddress),
              const SizedBox(height: 10),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 14, color: secondaryText),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      order.cargoName,
                      style: TextStyle(fontSize: 12, color: secondaryText),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.scale_outlined,
                      size: 14, color: secondaryText),
                  const SizedBox(width: 5),
                  Text(
                    order.cargoWeight,
                    style: TextStyle(fontSize: 12, color: secondaryText),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time_rounded,
                      size: 14, color: secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd.MM HH:mm').format(order.date),
                    style: TextStyle(fontSize: 12, color: secondaryText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
