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

  static OrderStatus fromString(String status) {
    switch (status) {
      case 'accepted':
        return OrderStatus.accepted;
      case 'inTransit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
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
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    List<String> parsedPhotos = [];
    if (json['attachedPhotos'] != null) {
      try {
        parsedPhotos = List<String>.from(json['attachedPhotos']);
      } catch (_) {}
    }

    return Order(
      id: json['id']?.toString() ?? '',
      number: json['number'] ?? '',
      cargoName: json['cargoName'] ?? '',
      cargoWeight: json['cargoWeight'] ?? '',
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      fromLat: (json['fromLat'] as num?)?.toDouble() ?? 0.0,
      fromLng: (json['fromLng'] as num?)?.toDouble() ?? 0.0,
      toLat: (json['toLat'] as num?)?.toDouble() ?? 0.0,
      toLng: (json['toLng'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      status: OrderStatusExtension.fromString(json['status'] ?? 'pending'),
      operatorId: json['operatorId']?.toString() ?? '',
      expeditorId: json['expeditorId']?.toString(),
      expeditorName: json['expeditorName'],
      expeditorPhone: json['expeditorPhone'],
      comment: json['comment'],
      attachedPhotos: parsedPhotos,
      operatorName: json['operatorName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'cargoName': cargoName,
      'cargoWeight': cargoWeight,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      'expeditorId': expeditorId,
      'expeditorName': expeditorName,
      'expeditorPhone': expeditorPhone,
      'comment': comment,
      'attachedPhotos': attachedPhotos,
    };
  }
}
