import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';

class RouteRow extends StatelessWidget {
  final String from;
  final String to;

  const RouteRow({super.key, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lDivider;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 1, height: 24, color: dividerColor),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: successColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from,
                  style: TextStyle(fontSize: 13, color: primaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              Text(to,
                  style: TextStyle(fontSize: 13, color: primaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
