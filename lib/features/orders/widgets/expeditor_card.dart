import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/services/chat_service.dart';

class ExpeditorCard extends StatefulWidget {
  final Order order;
  final Function(String) onCall;
  const ExpeditorCard({super.key, required this.order, required this.onCall});

  @override
  State<ExpeditorCard> createState() => _ExpeditorCardState();
}

class _ExpeditorCardState extends State<ExpeditorCard> {
  bool _creatingChat = false;

  Future<void> _openChat() async {
    if (_creatingChat) return;
    setState(() => _creatingChat = true);
    try {
      final room = await ChatService.createRoom(
        orderId: widget.order.id,
        orderNumber: widget.order.number,
        expeditorId: widget.order.expeditorId ?? '',
        operatorId: widget.order.operatorId,
      );
      if (mounted) {
        context.push('/chat/${room.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creatingChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delivery_dining_rounded,
                color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.order.expeditorName!,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: primaryText)),
                Text('Экспедитор',
                    style: TextStyle(fontSize: 12, color: secondaryText)),
              ],
            ),
          ),
          if (widget.order.expeditorId != null)
            GestureDetector(
              onTap: _openChat,
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: _creatingChat
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
                      )
                    : Icon(Icons.chat_bubble_outline_rounded, color: accentColor, size: 20),
              ),
            ),
          if (widget.order.expeditorPhone != null)
            GestureDetector(
              onTap: () => widget.onCall(widget.order.expeditorPhone!),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: successColor.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.call_rounded, color: successColor, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
