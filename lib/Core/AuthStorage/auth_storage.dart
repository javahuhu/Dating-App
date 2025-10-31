// lib/core/auth_storage.dart
import 'dart:html' as html; // Add this import
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writes the token to all available storage backends
Future<void> saveToken(String token) async {
  debugPrint('Saving token to all storage backends');
  
  // Web storage
  if (kIsWeb) {
    try {
      html.window.localStorage['jwt'] = token;
      debugPrint('Token saved to web localStorage');
    } catch (e) {
      debugPrint('Web localStorage save failed: $e');
    }
  } else {
    // Mobile/desktop secure storage
    try {
      const secure = FlutterSecureStorage();
      await secure.write(key: 'jwt', value: token);
      debugPrint('Token saved to secure storage');
    } catch (e) {
      debugPrint('Secure storage write failed: $e');
    }
  }

  // SharedPreferences as fallback
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', token);
    debugPrint('Token saved to SharedPreferences');
  } catch (e) {
    debugPrint('SharedPreferences write failed: $e');
  }
}

/// Reads token from all available storage backends
Future<String?> readToken() async {
  // Try web storage first
  if (kIsWeb) {
    try {
      final token = html.window.localStorage['jwt'];
      debugPrint('Read from web localStorage: $token');
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('Web localStorage read failed: $e');
    }
  } else {
    // Try secure storage for mobile/desktop
    try {
      const secure = FlutterSecureStorage();
      final token = await secure.read(key: 'jwt');
      debugPrint('Read from secure storage: $token');
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('Secure storage read failed: $e');
    }
  }

  // Fallback to SharedPreferences
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    debugPrint('Read from SharedPreferences: $token');
    if (token != null && token.isNotEmpty) return token;
  } catch (e) {
    debugPrint('SharedPreferences read failed: $e');
  }

  debugPrint('No token found in any storage backend');
  return null;
}