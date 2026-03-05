import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/core/services/api_service.dart';
import 'package:logistics_app/core/widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Состояние ─────────────────────────────────────────────
  final _contactCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _contactFocus = FocusNode();
  final _codeFocus = FocusNode();

  bool _step2 = false;   // false = ввод контакта, true = ввод OTP
  bool _loading = false;
  String _error = '';
  int _resendCountdown = 0;
  Timer? _timer;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _contactCtrl.dispose();
    _codeCtrl.dispose();
    _contactFocus.dispose();
    _codeFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Отправить OTP ─────────────────────────────────────────
  Future<void> _sendOtp() async {
    final contact = _contactCtrl.text.trim();
    if (contact.isEmpty) {
      setState(() => _error = 'Введите номер телефона или email');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      await ApiService.sendOtp(contact);
      setState(() {
        _step2 = true;
        _loading = false;
      });
      _startResendTimer();
      // Небольшая задержка, затем фокус на поле кода
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _codeFocus.requestFocus();
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() {
        _error = 'Не удалось подключиться к серверу.\nПроверьте интернет-соединение.';
        _loading = false;
      });
    }
  }

  // ── Подтвердить OTP ───────────────────────────────────────
  Future<void> _verifyOtp() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Введите 6-значный код');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final result = await ApiService.verifyOtp(_contactCtrl.text.trim(), code);
      final token = result['access_token'] as String;
      await ApiService.saveToken(token);
      final userJson = result['user'] as Map<String, dynamic>;
      AuthState.currentUser = AppUser.fromJson(userJson);
      if (mounted) {
        context.go(AuthState.currentUser!.role == UserRole.operator
            ? '/orders'
            : '/expeditor');
      }
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() {
        _error = 'Ошибка соединения. Проверьте подключение.';
        _loading = false;
      });
    }
  }

  void _startResendTimer({int seconds = 60}) {
    _timer?.cancel();
    setState(() => _resendCountdown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendCountdown = 0);
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  void _back() {
    _timer?.cancel();
    setState(() {
      _step2 = false;
      _error = '';
      _codeCtrl.clear();
      _resendCountdown = 0;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _contactFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.background : AppTheme.lBackground;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                _LogoBrand(),
                const SizedBox(height: 48),

                // ── Шаг 1: телефон / email ───────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _step2
                      ? _OtpStep(
                          key: const ValueKey('otp'),
                          contact: _contactCtrl.text.trim(),
                          ctrl: _codeCtrl,
                          focusNode: _codeFocus,
                          error: _error,
                          loading: _loading,
                          resendCountdown: _resendCountdown,
                          onVerify: _verifyOtp,
                          onResend: _sendOtp,
                          onBack: _back,
                        )
                      : _ContactStep(
                          key: const ValueKey('contact'),
                          ctrl: _contactCtrl,
                          focusNode: _contactFocus,
                          error: _error,
                          loading: _loading,
                          onNext: _sendOtp,
                        ),
                ),

                const Spacer(flex: 3),
                Center(
                  child: Text(
                    'ООО «Некст» © 2026',
                    style: TextStyle(color: secondaryText, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Шаг 1: ввод контакта ────────────────────────────────────────────────────

class _ContactStep extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final String error;
  final bool loading;
  final VoidCallback onNext;

  const _ContactStep({
    super.key,
    required this.ctrl,
    required this.focusNode,
    required this.error,
    required this.loading,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Войти в систему',
          style: TextStyle(
            color: primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Введите номер телефона или email',
          style: TextStyle(color: secondaryText, fontSize: 13),
        ),
        const SizedBox(height: 24),
        _StyledField(
          ctrl: ctrl,
          focusNode: focusNode,
          hint: '+7 (___) ___-__-__ или email',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.emailAddress,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          accentColor: accentColor,
          primaryText: primaryText,
          secondaryText: secondaryText,
          onSubmit: onNext,
        ),
        if (error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ErrorText(error),
        ],
        const SizedBox(height: 24),
        AppButton(
          label: 'Получить код',
          loading: loading,
          onPressed: onNext,
          width: double.infinity,
          icon: Icons.arrow_forward_ios_rounded,
        ),
      ],
    );
  }
}

// ─── Шаг 2: ввод OTP ─────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final String contact;
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final String error;
  final bool loading;
  final int resendCountdown;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;

  const _OtpStep({
    super.key,
    required this.contact,
    required this.ctrl,
    required this.focusNode,
    required this.error,
    required this.loading,
    required this.resendCountdown,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Icon(Icons.arrow_back_ios_rounded,
                  size: 18, color: accentColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Код подтверждения',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Код отправлен на $contact',
          style: TextStyle(color: secondaryText, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // ── 6-значный OTP ───────────────────────
        _OtpField(
          ctrl: ctrl,
          focusNode: focusNode,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          accentColor: accentColor,
          primaryText: primaryText,
          onSubmit: onVerify,
        ),

        if (error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ErrorText(error),
        ],
        const SizedBox(height: 24),
        AppButton(
          label: 'Подтвердить',
          loading: loading,
          onPressed: onVerify,
          width: double.infinity,
          icon: Icons.check_rounded,
        ),
        const SizedBox(height: 16),

        // ── Повторная отправка ───────────────────
        Center(
          child: resendCountdown > 0
              ? Text(
                  'Повторная отправка через ${resendCountdown}с',
                  style: TextStyle(color: secondaryText, fontSize: 13),
                )
              : GestureDetector(
                  onTap: onResend,
                  child: Text(
                    'Отправить код повторно',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── OTP поле (6 цифр, крупный шрифт) ────────────────────────────────────────

class _OtpField extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final Color surfaceColor;
  final Color borderColor;
  final Color accentColor;
  final Color primaryText;
  final VoidCallback onSubmit;

  const _OtpField({
    required this.ctrl,
    required this.focusNode,
    required this.surfaceColor,
    required this.borderColor,
    required this.accentColor,
    required this.primaryText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: ctrl,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primaryText,
          letterSpacing: 12,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '——————',
          hintStyle: TextStyle(
            color: borderColor,
            fontSize: 24,
            letterSpacing: 8,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              color: accentColor, size: 20),
        ),
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

// ─── Обычное поле ввода ───────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final Color surfaceColor;
  final Color borderColor;
  final Color accentColor;
  final Color primaryText;
  final Color secondaryText;
  final VoidCallback onSubmit;

  const _StyledField({
    required this.ctrl,
    required this.focusNode,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.surfaceColor,
    required this.borderColor,
    required this.accentColor,
    required this.primaryText,
    required this.secondaryText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: ctrl,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16, color: primaryText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: secondaryText, fontSize: 14),
          prefixIcon: Icon(icon, color: accentColor, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

// ─── Сообщение об ошибке ──────────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).colorScheme.brightness == Brightness.dark;
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, size: 15, color: dangerColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: dangerColor, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ─── Лого / бренд ────────────────────────────────────────────────────────────

class _LogoBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText =
        isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.local_shipping_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 20),
        Text(
          'Некст',
          style: TextStyle(
            color: primaryText,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Система управления логистикой',
          style: TextStyle(color: secondaryText, fontSize: 14),
        ),
      ],
    );
  }
}
