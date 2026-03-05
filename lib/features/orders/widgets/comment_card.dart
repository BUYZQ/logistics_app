import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';

class CommentCard extends StatelessWidget {
  final String comment;
  const CommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
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
              Icon(Icons.comment_outlined, size: 16, color: secondaryText),
              const SizedBox(width: 8),
              Text('Комментарий экспедитора',
                  style: TextStyle(fontSize: 12, color: secondaryText)),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment,
              style: TextStyle(fontSize: 14, color: primaryText)),
        ],
      ),
    );
  }
}
