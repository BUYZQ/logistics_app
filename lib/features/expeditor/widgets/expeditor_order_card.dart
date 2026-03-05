import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/widgets/status_badge.dart';

// ─── RouteRow (compact version for expeditor) ────────────────────────────────

class ExpeditorRouteRow extends StatelessWidget {
  final String from;
  final String to;
  const ExpeditorRouteRow({super.key, required this.from, required this.to});

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
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: accentColor, shape: BoxShape.circle)),
            Container(width: 1, height: 20, color: dividerColor),
            Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: successColor, shape: BoxShape.circle)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from,
                  style: TextStyle(fontSize: 12, color: primaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Text(to,
                  style: TextStyle(fontSize: 12, color: primaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class ExpeditorEmptyState extends StatelessWidget {
  const ExpeditorEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: secondaryText),
              const SizedBox(height: 12),
              Text('Нет активных заявок',
                  style: TextStyle(color: secondaryText, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class ExpeditorActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ExpeditorActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Action row ───────────────────────────────────────────────────────────────

class ExpeditorActionRow extends StatelessWidget {
  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCall;
  final VoidCallback onMap;
  final VoidCallback onConfirm;

  const ExpeditorActionRow({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    required this.onCall,
    required this.onMap,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final dangerColor = isDark ? AppTheme.danger : AppTheme.lDanger;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;

    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          ExpeditorActionBtn(
              icon: Icons.close_rounded,
              label: 'Отклонить',
              color: dangerColor,
              onTap: onReject),
          const SizedBox(width: 8),
          ExpeditorActionBtn(
              icon: Icons.phone_outlined,
              label: 'Позвонить',
              color: secondaryText,
              onTap: onCall),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onAccept,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Принять',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          ExpeditorActionBtn(
              icon: Icons.map_outlined,
              label: 'Карта',
              color: accentColor,
              onTap: onMap),
          const SizedBox(width: 8),
          ExpeditorActionBtn(
              icon: Icons.phone_outlined,
              label: 'Позвонить',
              color: secondaryText,
              onTap: onCall),
          const SizedBox(width: 8),
          if (order.status == OrderStatus.inTransit ||
              order.status == OrderStatus.accepted)
            Expanded(
              child: GestureDetector(
                onTap: onConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: successColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Подтвердить',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class ExpeditorOrderCard extends StatelessWidget {
  final Order order;
  final int index;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCall;
  final VoidCallback onMap;
  final VoidCallback onConfirm;

  const ExpeditorOrderCard({
    super.key,
    required this.order,
    required this.index,
    required this.onAccept,
    required this.onReject,
    required this.onCall,
    required this.onMap,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final borderColor = order.status == OrderStatus.pending
        ? (isDark ? AppTheme.warning : AppTheme.lWarning).withValues(alpha: 0.4)
        : (isDark ? AppTheme.cardBorder : AppTheme.lCardBorder);
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lDivider;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 70),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - v)), child: child)),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(order.number,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: primaryText)),
                      const Spacer(),
                      StatusBadge(status: order.status, small: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ExpeditorRouteRow(
                      from: order.fromAddress, to: order.toAddress),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 13, color: secondaryText),
                      const SizedBox(width: 5),
                      Text('${order.cargoName} · ${order.cargoWeight}',
                          style:
                              TextStyle(fontSize: 12, color: secondaryText)),
                      const Spacer(),
                      Icon(Icons.access_time_rounded,
                          size: 13, color: secondaryText),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM HH:mm').format(order.date),
                        style: TextStyle(fontSize: 12, color: secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (order.status != OrderStatus.cancelled &&
                order.status != OrderStatus.delivered) ...[
              Container(
                height: 1,
                color: dividerColor,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: ExpeditorActionRow(
                  order: order,
                  onAccept: onAccept,
                  onReject: onReject,
                  onCall: onCall,
                  onMap: onMap,
                  onConfirm: onConfirm,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
