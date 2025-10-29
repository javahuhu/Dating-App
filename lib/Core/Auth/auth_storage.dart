// lib/core/auth_storage.dart
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writes the token to secure storage (mobile/desktop) and to SharedPreferences (fallback).
Future<void> saveToken(String token) async {
  try {
    // Secure storage for mobile/desktop
    const secure = FlutterSecureStorage();
    await secure.write(key: 'jwt', value: token);
  } catch (e) {
    debugPrint('saveToken: secure write failed: $e');
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', token);
  } catch (e) {
    debugPrint('saveToken: shared prefs write failed: $e');
  }
}

/// Reads token using secure storage first, then SharedPreferences as fallback.
Future<String?> readToken() async {
  try {
    if (!kIsWeb) {
      const secure = FlutterSecureStorage();
      final token = await secure.read(key: 'jwt');
      if (token != null && token.isNotEmpty) return token;
    }
  } catch (e) {
    debugPrint('readToken: secure read failed: $e');
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token != null && token.isNotEmpty) return token;
  } catch (e) {
    debugPrint('readToken: shared prefs read failed: $e');
  }

  return null;
}
