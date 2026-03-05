import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';

class OrderInfoCard extends StatelessWidget {
  final Order order;
  const OrderInfoCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;

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
          Text('Детали заявки',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: primaryText)),
          const SizedBox(height: 14),
          OrderInfoRow(Icons.inventory_2_outlined, 'Груз',
              '${order.cargoName} · ${order.cargoWeight}'),
          const SizedBox(height: 10),
          OrderInfoRow(Icons.location_on_outlined, 'Откуда', order.fromAddress),
          const SizedBox(height: 10),
          OrderInfoRow(Icons.flag_outlined, 'Куда', order.toAddress),
          const SizedBox(height: 10),
          OrderInfoRow(Icons.calendar_today_outlined, 'Дата',
              DateFormat('dd.MM.yyyy, HH:mm').format(order.date)),
          if (order.operatorName != null) ...[
            const SizedBox(height: 10),
            OrderInfoRow(Icons.person_outline, 'Оператор', order.operatorName!),
          ],
        ],
      ),
    );
  }
}

class OrderInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const OrderInfoRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: secondaryText),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: secondaryText)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: primaryText,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
