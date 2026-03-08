import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Базовый URL бэкенда. Меняйте на IP вашего сервера при деплое.
/// Для Android-эмулятора: 10.0.2.2:8000
/// Для реального устройства: IP компьютера в сети, например 192.168.1.100:8000
/// Для Render: https://logistics-app-yjqp.onrender.com
const String baseUrl = 'http://192.168.101.7:8000';

const String _tokenKey = 'auth_token';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  // ── Токен ─────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Вспомогательные ───────────────────────────────────────────────────────

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parse(http.Response resp) {
    final body = utf8.decode(resp.bodyBytes);
    final json = jsonDecode(body);
    if (resp.statusCode >= 400) {
      final detail = json['detail'] ?? 'Ошибка сервера';
      throw ApiException(resp.statusCode, detail.toString());
    }
    return json as Map<String, dynamic>;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Отправить OTP код на телефон или email.
  static Future<void> sendOtp(String contact) async {
    final resp = await http
        .post(
          Uri.parse('$baseUrl/auth/send-otp'),
          headers: _headers,
          body: jsonEncode({'contact': contact}),
        )
        .timeout(const Duration(seconds: 45)); // Увеличено для Render
    _parse(resp);
  }

  /// Проверить OTP и получить данные пользователя + токен.
  static Future<Map<String, dynamic>> verifyOtp(
      String contact, String code) async {
    final resp = await http
        .post(
          Uri.parse('$baseUrl/auth/verify-otp'),
          headers: _headers,
          body: jsonEncode({'contact': contact, 'code': code}),
        )
        .timeout(const Duration(seconds: 30));
    return _parse(resp);
  }

  /// Получить профиль текущего пользователя по JWT.
  static Future<Map<String, dynamic>> getMe() async {
    final resp = await http
        .get(
          Uri.parse('$baseUrl/auth/me'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    return _parse(resp);
  }

  /// Загрузить аватар пользователя
  static Future<String> uploadAvatar(String filePath) async {
    final uri = Uri.parse('$baseUrl/upload/avatar');
    final req = http.MultipartRequest('POST', uri);
    
    final auth = await _authHeaders();
    req.headers.addAll(auth);

    req.files.add(await http.MultipartFile.fromPath('file', filePath));

    final resp = await req.send().timeout(const Duration(seconds: 60));
    final respStr = await resp.stream.bytesToString();
    
    if (resp.statusCode >= 400) {
      throw ApiException(resp.statusCode, 'Не удалось загрузить фото');
    }
    
    final json = jsonDecode(respStr);
    return json['avatarUrl'] as String;
  }
}
