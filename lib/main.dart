import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logistics_app/app/app.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/core/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = await ApiService.getToken();
  final prefs = await SharedPreferences.getInstance();
  final userStr = prefs.getString('user_data');

  if (token != null && userStr != null) {
    try {
      final userJson = jsonDecode(userStr);
      AuthState.currentUser = AppUser.fromJson(userJson);
    } catch (_) {
      // ignore
    }
  }

  runApp(App());
}
