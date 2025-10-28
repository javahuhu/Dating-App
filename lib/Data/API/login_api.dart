import 'dart:convert';
import 'dart:io';

import 'package:dating_app/Data/Models/user_login_model.dart';
import 'package:http/http.dart' as http;

class LoginApi {
  final String baseUrl = 'http://localhost:3000/api/auth';

  Future<Map<String, dynamic>> loginUser(UserLoginModel user) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': data['user'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
          'status': response.statusCode,
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on FormatException {
      return {'success': false, 'message': 'Invalid server response format.'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error occurred: $e'};
    }
  }
}
