import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';

class OrdersEmptyState extends StatelessWidget {
  const OrdersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: secondaryText),
              const SizedBox(height: 12),
              Text(
                'Заявок нет',
                style: TextStyle(color: secondaryText, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
