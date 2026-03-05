import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logistics_app/app/theme.dart';

/// Заголовок секции в верхнем регистре
class ConfirmLabel extends StatelessWidget {
  final String text;
  const ConfirmLabel(this.text, {super.key});

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
          letterSpacing: 1.1),
    );
  }
}

/// Кнопка добавления фото
class AddPhotoBtn extends StatelessWidget {
  final VoidCallback onTap;
  const AddPhotoBtn({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final fillColor = isDark ? AppTheme.surfaceHigher : AppTheme.lSurfaceHigher;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: accentColor, size: 24),
            const SizedBox(height: 4),
            Text('Добавить',
                style: TextStyle(color: accentColor, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

/// Миниатюра выбранного фото с кнопкой удаления
class PhotoThumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const PhotoThumb({super.key, required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(file.path),
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: dangerColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
