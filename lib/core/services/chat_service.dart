import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logistics_app/core/models/message.dart';
import 'package:logistics_app/core/services/api_service.dart';

class ChatService {
  // Use the same base URL as the ApiService
  static const String _baseUrl = 'http://10.0.2.2:8000';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await ApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<ChatRoom>> getRooms() async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/chat/rooms'),
      headers: await _authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final body = utf8.decode(resp.bodyBytes);
      final List data = jsonDecode(body);
      return data.map((e) => ChatRoom.fromJson(e)).toList();
    }
    throw ApiException(resp.statusCode, 'Не удалось загрузить список чатов');
  }

  static Future<ChatRoom> createRoom({
    required String orderId,
    required String orderNumber,
    required String expeditorId,
  }) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/chat/rooms'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'order_id': orderId,
        'order_number': orderNumber,
        'expeditor_id': int.tryParse(expeditorId) ?? 0,
      }),
    ).timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final body = utf8.decode(resp.bodyBytes);
      return ChatRoom.fromJson(jsonDecode(body));
    }
    throw ApiException(resp.statusCode, 'Не удалось создать чат');
  }

  static Future<ChatRoom> getRoomMessages(String roomId) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/chat/rooms/$roomId/messages'),
      headers: await _authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final body = utf8.decode(resp.bodyBytes);
      return ChatRoom.fromJson(jsonDecode(body));
    }
    throw ApiException(resp.statusCode, 'Не удалось загрузить историю сообщений');
  }

  static Future<ChatMessage> sendMessage(String roomId, String text) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/chat/rooms/$roomId/messages'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'text': text,
      }),
    ).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final body = utf8.decode(resp.bodyBytes);
      return ChatMessage.fromJson(jsonDecode(body));
    }
    throw ApiException(resp.statusCode, 'Не удалось отправить сообщение');
  }
}
