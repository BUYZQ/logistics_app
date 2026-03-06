import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';

class ExpeditorEmptyState extends StatelessWidget {
  const ExpeditorEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: secondaryText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Нет доступных заявок',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
