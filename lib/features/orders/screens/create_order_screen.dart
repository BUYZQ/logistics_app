import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/core/services/order_service.dart';
import 'package:logistics_app/core/widgets/app_button.dart';
import 'package:logistics_app/features/orders/widgets/section_label.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(hours: 2));
  bool _loading = false;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _cargoCtrl.dispose();
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lSurface;

    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: accentColor,
            onPrimary: Colors.white,
            secondary: accentColor,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            surface: surfaceColor,
            onSurface: isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    final newOrder = Order(
      id: '',
      number:
          'ПИ-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      cargoName: _cargoCtrl.text,
      cargoWeight: _weightCtrl.text,
      fromAddress: _fromCtrl.text,
      toAddress: _toCtrl.text,
      fromLat: 56.6596,
      fromLng: 124.7154,
      toLat: 56.6596,
      toLng: 124.7154,
      date: _date,
      status: OrderStatus.pending,
      operatorId: AuthState.currentUser!.id,
      operatorName: AuthState.currentUser!.name,
      comment: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );
    try {
      final created = await OrderService.createOrder(newOrder);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заявка ${created.number} создана'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.background : AppTheme.lBackground;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final fillColor = isDark ? AppTheme.surfaceHigher : AppTheme.lSurfaceHigher;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryText, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Новая заявка'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionLabel('Маршрут'),
            const SizedBox(height: 10),
            AppFormField(
              controller: _fromCtrl,
              hint: 'Адрес отправки',
              icon: Icons.location_on_outlined,
              validator: (v) => v!.isEmpty ? 'Введите адрес' : null,
            ),
            const SizedBox(height: 10),
            AppFormField(
              controller: _toCtrl,
              hint: 'Адрес доставки',
              icon: Icons.flag_outlined,
              validator: (v) => v!.isEmpty ? 'Введите адрес' : null,
            ),
            const SizedBox(height: 20),
            SectionLabel('Груз'),
            const SizedBox(height: 10),
            AppFormField(
              controller: _cargoCtrl,
              hint: 'Наименование груза',
              icon: Icons.inventory_2_outlined,
              validator: (v) => v!.isEmpty ? 'Введите груз' : null,
            ),
            const SizedBox(height: 10),
            AppFormField(
              controller: _weightCtrl,
              hint: 'Вес (напр. 1.5 т)',
              icon: Icons.scale_outlined,
              validator: (v) => v!.isEmpty ? 'Введите вес' : null,
            ),
            const SizedBox(height: 20),
            SectionLabel('Дата'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: secondaryText),
                    const SizedBox(width: 10),
                    Text(
                      '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                      style: TextStyle(color: primaryText, fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: secondaryText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SectionLabel('Примечание'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              style: TextStyle(color: primaryText, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Дополнительная информация...',
                hintStyle: TextStyle(color: secondaryText),
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Создать заявку',
              icon: Icons.check_rounded,
              loading: _loading,
              onPressed: _submit,
              width: double.infinity,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
