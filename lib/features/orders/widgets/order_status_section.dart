import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/widgets/status_badge.dart';

class OrderStatusSection extends StatelessWidget {
  final Order order;
  const OrderStatusSection({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Container(
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
              Text('Статус',
                  style: TextStyle(color: secondaryText, fontSize: 12)),
              const Spacer(),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          OrderProgressBar(status: order.status),
        ],
      ),
    );
  }
}
