import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool loading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
    this.loading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;
    final fillColor = isDark ? AppTheme.surfaceHigher : AppTheme.lSurfaceHigher;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;

    final Color bg = isDestructive
        ? dangerColor
        : isPrimary
            ? accentColor
            : fillColor;
    final Color fg = isPrimary || isDestructive ? Colors.white : primaryText;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: onPressed == null ? bg.withValues(alpha: 0.4) : bg,
              borderRadius: BorderRadius.circular(12),
              border: isPrimary || isDestructive
                  ? null
                  : Border.all(color: borderColor),
            ),
            child: loading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: fg,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? bgColor;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.bgColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final defaultBg = isDark ? AppTheme.surfaceHigher : AppTheme.lSurfaceHigher;
    final defaultBorder = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final defaultIcon = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;

    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor ?? defaultBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: defaultBorder),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? defaultIcon,
          ),
        ),
      ),
    );
  }
}
