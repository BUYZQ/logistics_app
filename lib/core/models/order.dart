import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  accepted,
  inTransit,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Новая';
      case OrderStatus.accepted:
        return 'Принята';
      case OrderStatus.inTransit:
        return 'В пути';
      case OrderStatus.delivered:
        return 'Доставлена';
      case OrderStatus.cancelled:
        return 'Отклонена';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.accepted:
        return const Color(0xFF3B7EF6);
      case OrderStatus.inTransit:
        return const Color(0xFF8B5CF6);
      case OrderStatus.delivered:
        return const Color(0xFF22C55E);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  int get step {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.inTransit:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }
}

class Order {
  final String id;
  final String number;
  final String cargoName;
  final String cargoWeight;
  final String fromAddress;
  final String toAddress;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final DateTime date;
  final OrderStatus status;
  final String operatorId;
  final String? expeditorId;
  final String? expeditorName;
  final String? expeditorPhone;
  final String? comment;
  final List<String> attachedPhotos;
  final String? operatorName;

  const Order({
    required this.id,
    required this.number,
    required this.cargoName,
    required this.cargoWeight,
    required this.fromAddress,
    required this.toAddress,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.date,
    required this.status,
    required this.operatorId,
    this.expeditorId,
    this.expeditorName,
    this.expeditorPhone,
    this.comment,
    this.attachedPhotos = const [],
    this.operatorName,
  });

  Order copyWith({
    OrderStatus? status,
    String? expeditorId,
    String? expeditorName,
    String? expeditorPhone,
    String? comment,
    List<String>? attachedPhotos,
  }) {
    return Order(
      id: id,
      number: number,
      cargoName: cargoName,
      cargoWeight: cargoWeight,
      fromAddress: fromAddress,
      toAddress: toAddress,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      date: date,
      status: status ?? this.status,
      operatorId: operatorId,
      expeditorId: expeditorId ?? this.expeditorId,
      expeditorName: expeditorName ?? this.expeditorName,
      expeditorPhone: expeditorPhone ?? this.expeditorPhone,
      comment: comment ?? this.comment,
      attachedPhotos: attachedPhotos ?? this.attachedPhotos,
      operatorName: operatorName,
    );
  }
}

// In-memory mock data store
// Компания «Некст» — поставка пищевых товаров, г. Нерюнгри
// Склады: ул. Амгинская, 5 / 6 / 7 / 8, Нерюнгри, Респ. Саха (Якутия), 678960
class OrderStore {
  static final List<Order> _orders = [
    Order(
      id: '1',
      number: 'НКТ-2026-001',
      cargoName: 'Соки и нектары',
      cargoWeight: '2 пал. (1.2 т)',
      fromAddress: 'Склад №1, ул. Амгинская, 5, Нерюнгри',
      toAddress: 'Магазин «Седьмой», ул. Ленина, 35, Нерюнгри',
      fromLat: 56.6542,
      fromLng: 124.7185,
      toLat: 56.6596,
      toLng: 124.7110,
      date: DateTime.now().add(const Duration(hours: 2)),
      status: OrderStatus.pending,
      operatorId: 'op1',
      operatorName: 'Алексей Иванов',
      expeditorPhone: '+7 (914) 001-23-45',
    ),
    Order(
      id: '2',
      number: 'НКТ-2026-002',
      cargoName: 'Чипсы и снеки',
      cargoWeight: '1 пал. (480 кг)',
      fromAddress: 'Склад №2, ул. Амгинская, 6, Нерюнгри',
      toAddress: 'Торговый центр «Фортуна», пр. Дружбы Народов, 18',
      fromLat: 56.6535,
      fromLng: 124.7198,
      toLat: 56.6712,
      toLng: 124.7320,
      date: DateTime.now().add(const Duration(hours: 1)),
      status: OrderStatus.accepted,
      operatorId: 'op1',
      operatorName: 'Алексей Иванов',
      expeditorId: 'ex1',
      expeditorName: 'Дмитрий Петров',
      expeditorPhone: '+7 (914) 765-43-21',
    ),
    Order(
      id: '3',
      number: 'НКТ-2026-003',
      cargoName: 'Лапша быстрого приготовления',
      cargoWeight: '3 пал. (1.8 т)',
      fromAddress: 'Склад №3, ул. Амгинская, 7, Нерюнгри',
      toAddress: 'Оптовая база «Якутопторг», ул. Кравченко, 12',
      fromLat: 56.6528,
      fromLng: 124.7210,
      toLat: 56.6540,
      toLng: 124.7080,
      date: DateTime.now().subtract(const Duration(hours: 3)),
      status: OrderStatus.inTransit,
      operatorId: 'op1',
      operatorName: 'Алексей Иванов',
      expeditorId: 'ex1',
      expeditorName: 'Дмитрий Петров',
      expeditorPhone: '+7 (914) 765-43-21',
    ),
    Order(
      id: '4',
      number: 'НКТ-2026-004',
      cargoName: 'Кофе, чай, сахар',
      cargoWeight: '2 пал. (900 кг)',
      fromAddress: 'Склад №4, ул. Амгинская, 8, Нерюнгри',
      toAddress: 'Магазин «Полюс», ул. Чайковского, 3, Нерюнгри',
      fromLat: 56.6521,
      fromLng: 124.7223,
      toLat: 56.6650,
      toLng: 124.7220,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: OrderStatus.delivered,
      operatorId: 'op1',
      operatorName: 'Алексей Иванов',
      expeditorId: 'ex1',
      expeditorName: 'Дмитрий Петров',
      expeditorPhone: '+7 (914) 765-43-21',
      comment: 'Доставлено без замечаний. Паллеты возвращены на склад.',
    ),
  ];

  static List<Order> getAll() => List.from(_orders);

  static List<Order> getForExpeditor(String expeditorId) {
    return _orders
        .where((o) =>
            o.expeditorId == expeditorId ||
            (o.status == OrderStatus.pending && o.expeditorId == null))
        .toList();
  }

  static void updateOrder(Order updated) {
    final idx = _orders.indexWhere((o) => o.id == updated.id);
    if (idx != -1) _orders[idx] = updated;
  }

  static void addOrder(Order order) {
    _orders.insert(0, order);
  }
}
