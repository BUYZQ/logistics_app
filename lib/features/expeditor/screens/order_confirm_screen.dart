import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/services/order_service.dart';
import 'package:logistics_app/core/widgets/app_button.dart';
import 'package:logistics_app/features/expeditor/widgets/confirm_widgets.dart';

class OrderConfirmScreen extends StatefulWidget {
  final String orderId;
  const OrderConfirmScreen({super.key, required this.orderId});

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen> {
  Order? _order;
  final _commentCtrl = TextEditingController();
  final List<XFile> _photos = [];
  bool _loading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final orders = await OrderService.getOrders();
      if (mounted) {
        setState(() {
          _order = orders.where((o) => o.id == widget.orderId).firstOrNull;
        });
      }
    } catch (e) {
      // Ignored for now
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Максимум 5 фотографий')),
      );
      return;
    }
    final img = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1080);
    if (img != null) setState(() => _photos.add(img));
  }

  void _showSourceDialog() {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lDivider;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: accentColor),
                title:
                    Text('Камера', style: TextStyle(color: primaryText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library_outlined, color: accentColor),
                title:
                    Text('Галерея', style: TextStyle(color: primaryText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_commentCtrl.text.trim().isEmpty && _photos.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      final isDark = cs.brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Добавьте комментарий или фото'),
            backgroundColor:
                isDark ? AppTheme.warning : AppTheme.lWarning),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      if (_order != null) {
        await OrderService.updateOrderStatus(
          _order!.id,
          OrderStatus.delivered,
          comment: _commentCtrl.text.trim(),
          attachedPhotos: _photos.map((p) => p.path).toList(), // just storing paths locally to simulate
        );
      }
      if (mounted) {
        setState(() => _loading = false);
        final cs = Theme.of(context).colorScheme;
        final isDark = cs.brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Доставка подтверждена!'),
            backgroundColor: isDark ? AppTheme.success : AppTheme.lSuccess,
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
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;

    if (_order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryText, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Подтверждение доставки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 16, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_order!.number} · ${_order!.toAddress}',
                    style: TextStyle(fontSize: 13, color: accentColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ConfirmLabel('Комментарий'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _commentCtrl,
            maxLines: 4,
            style: TextStyle(color: primaryText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Опишите условия доставки, состояние груза...',
              hintStyle: TextStyle(color: secondaryText, fontSize: 13),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ConfirmLabel('Фотографии'),
              const Spacer(),
              Text('${_photos.length}/5',
                  style: TextStyle(fontSize: 12, color: secondaryText)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length + (_photos.length < 5 ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                if (i == _photos.length) {
                  return AddPhotoBtn(onTap: _showSourceDialog);
                }
                return PhotoThumb(
                  file: _photos[i],
                  onRemove: () => setState(() => _photos.removeAt(i)),
                );
              },
            ),
          ),
          const SizedBox(height: 36),
          AppButton(
            label: 'Подтвердить доставку',
            icon: Icons.check_circle_outline_rounded,
            loading: _loading,
            onPressed: _submit,
            width: double.infinity,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
