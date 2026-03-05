import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';

/// Заголовок секции формы в верхнем регистре
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Поле ввода с иконкой для формы заявки
class AppFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const AppFormField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;

    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(color: primaryText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: secondaryText),
      ),
    );
  }
}
