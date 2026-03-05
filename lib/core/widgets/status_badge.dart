import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class OrderProgressBar extends StatelessWidget {
  final OrderStatus status;

  const OrderProgressBar({super.key, required this.status});

  static const steps = ['Новая', 'Принята', 'В пути', 'Доставлена'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lDivider;

    if (status == OrderStatus.cancelled) {
      return _CancelledBar(isDark: isDark);
    }
    final step = status.step;
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final filled = i ~/ 2 < step;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? accentColor : dividerColor,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx < step;
        final active = idx == step;
        return _StepDot(
          filled: done,
          active: active,
          label: steps[idx],
          accentColor: accentColor,
          accentLight: isDark ? AppTheme.accentLight : AppTheme.lAccentLight,
          secondaryText: isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary,
          dividerColor: dividerColor,
        );
      }),
    );
  }
}

class _CancelledBar extends StatelessWidget {
  final bool isDark;
  const _CancelledBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, size: 16, color: dangerColor),
          const SizedBox(width: 6),
          Text(
            'Заявка отклонена',
            style: TextStyle(
              color: dangerColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool filled;
  final bool active;
  final String label;
  final Color accentColor;
  final Color accentLight;
  final Color secondaryText;
  final Color dividerColor;

  const _StepDot({
    required this.filled,
    required this.active,
    required this.label,
    required this.accentColor,
    required this.accentLight,
    required this.secondaryText,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: active ? 14 : 10,
          height: active ? 14 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled || active ? accentColor : dividerColor,
            border: active
                ? Border.all(color: accentLight, width: 2)
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: active ? accentColor : secondaryText,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
