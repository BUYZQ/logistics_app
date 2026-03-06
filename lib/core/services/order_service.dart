import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/services/api_service.dart';

class OrderService {
  static const String _baseUrl = 'http://10.0.2.2:8000/orders';

  static Future<List<Order>> getOrders() async {
    final token = ApiService.getToken();
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Не удалось загрузить заявки: ${response.statusCode}');
    }
  }

  static Future<Order> createOrder(Order order) async {
    final token = ApiService.getToken();
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(order.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Order.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Ошибка создания заявки: ${response.statusCode}');
    }
  }

  static Future<Order> updateOrderStatus(String orderId, OrderStatus status, {String? expeditorId, String? expeditorName, String? expeditorPhone, String? comment, List<String>? attachedPhotos}) async {
    final token = ApiService.getToken();
    final Map<String, dynamic> body = {
      'status': status.name,
    };
    
    if (expeditorId != null) body['expeditorId'] = expeditorId;
    if (expeditorName != null) body['expeditorName'] = expeditorName;
    if (expeditorPhone != null) body['expeditorPhone'] = expeditorPhone;
    if (comment != null) body['comment'] = comment;
    if (attachedPhotos != null) body['attachedPhotos'] = jsonEncode(attachedPhotos);

    final response = await http.put(
      Uri.parse('$_baseUrl/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Ошибка обновления статуса заявки: ${response.statusCode}');
    }
  }
}
