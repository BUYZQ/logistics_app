import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/core/services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthState.currentUser!;
    final isOperator = user.role == UserRole.operator;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.background : AppTheme.lBackground;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accentColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      user.name.substring(0, 1),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOperator
                              ? accentColor.withValues(alpha: 0.1)
                              : successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOperator ? 'Оператор' : 'Экспедитор',
                          style: TextStyle(
                            color: isOperator ? accentColor : successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle('Контакты'),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Телефон',
              value: user.displayContact,
            ),
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.badge_outlined,
              label: 'ID сотрудника',
              value: user.id.toUpperCase(),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Приложение'),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.notifications_outlined,
              label: 'Уведомления',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.info_outline_rounded,
              label: 'О приложении',
              onTap: () => _showAbout(context),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () async {
                await ApiService.clearToken();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_data');
                
                AuthState.currentUser = null;
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: dangerColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: dangerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: dangerColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Выйти из аккаунта',
                      style: TextStyle(
                          color: dangerColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'v1.0.0 · ООО «Некст» · 2026',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surfaceHigher : AppTheme.lSurface;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text('Некст',
                style: TextStyle(color: primaryText, fontSize: 16)),
          ],
        ),
        content: Text(
          'Система управления логистикой пищевых товаров.\nВерсия 1.0.0 · 2026 г.',
          style: TextStyle(color: secondaryText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('OK', style: TextStyle(color: accentColor)),
          )
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: secondaryText),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: secondaryText)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      color: primaryText,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: secondaryText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: primaryText)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: secondaryText, size: 18),
          ],
        ),
      ),
    );
  }
}
