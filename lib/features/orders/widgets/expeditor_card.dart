import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';

class ExpeditorCard extends StatelessWidget {
  final Order order;
  final Function(String) onCall;
  const ExpeditorCard({super.key, required this.order, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delivery_dining_rounded,
                color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.expeditorName!,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: primaryText)),
                Text('Экспедитор',
                    style: TextStyle(fontSize: 12, color: secondaryText)),
              ],
            ),
          ),
          if (order.expeditorPhone != null)
            GestureDetector(
              onTap: () => onCall(order.expeditorPhone!),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: successColor.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.call_rounded, color: successColor, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
