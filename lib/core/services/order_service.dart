import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/services/api_service.dart';

class OrderService {
  static String get _ordersUrl => '$baseUrl/orders';

  static Future<List<Order>> getOrders() async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse(_ordersUrl),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Order.fromJson(json)).toList();
    }

    throw Exception('Не удалось загрузить заявки: ${response.statusCode}');
  }

  static Future<Order> createOrder(Order order) async {
    final token = await ApiService.getToken();
    final response = await http
        .post(
          Uri.parse(_ordersUrl),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(order.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Order.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }

    throw Exception('Ошибка создания заявки: ${response.statusCode}');
  }

  static Future<Order> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? expeditorId,
    String? expeditorName,
    String? expeditorPhone,
    String? comment,
    List<String>? attachedPhotos,
  }) async {
    final token = await ApiService.getToken();
    final Map<String, dynamic> body = {
      'status': status.name,
    };

    if (expeditorId != null) body['expeditorId'] = expeditorId;
    if (expeditorName != null) body['expeditorName'] = expeditorName;
    if (expeditorPhone != null) body['expeditorPhone'] = expeditorPhone;
    if (comment != null) body['comment'] = comment;
    if (attachedPhotos != null) body['attachedPhotos'] = attachedPhotos;

    final response = await http
        .put(
          Uri.parse('$_ordersUrl/$orderId/status'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }

    throw Exception(
      'Ошибка обновления статуса заявки: ${response.statusCode}',
    );
  }
}
