import 'dart:convert';
import 'dart:io'; // for SocketException
import 'package:http/http.dart' as http;
import '../Models/user_register_model.dart';

class RegisterAuth {

  final String baseUrl = 'http://localhost:3000/api/auth';

  Future<Map<String, dynamic>> registerUser(UserRegisterModel user) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      // ✅ Handle status codes
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'user': data['user'],
        };
      } else {
        // Server responded but with an error
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
          'status': response.statusCode,
        };
      }
    } on SocketException {
      // No Internet connection
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on FormatException {
      // Invalid JSON format
      return {
        'success': false,
        'message': 'Invalid server response format.',
      };
    } catch (e) {
      // Catch any other error
      return {
        'success': false,
        'message': 'Unexpected error occurred: $e',
      };
    }
  }
}
