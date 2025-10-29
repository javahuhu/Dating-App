// lib/data/api/profile_api.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileApi {
  // If testing on Android emulator, change to 'http://10.0.2.2:3000' (see note below)
  final String baseUrl = 'http://localhost:3000';


   Future<UserinformationModel?> fetchProfile(String token) async {
    // Example: call /me or /profile endpoint and parse UserinformationModel
    // Use your existing HTTP client here.
    final resp = await http.get(
      Uri.parse('$baseUrl/api/profile/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      return UserinformationModel.fromMap(json);
    }
    return null;
  }

  
  Future<UserinformationModel> uploadProfile({
    required String token,
    required String name,
    required int age,
    required String bio,
    File? imageFile,
    Uint8List? imageBytes,
    String? filename,
  }) async {
    final uri = Uri.parse('$baseUrl/api/profile');

    try {
      // No image -> JSON POST
      if (imageFile == null && imageBytes == null) {
        final resp = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'name': name, 'age': age, 'bio': bio}),
        );

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final j = jsonDecode(resp.body) as Map<String, dynamic>;
          final userJson = j['user'] as Map<String, dynamic>;
          return UserinformationModel.fromMap(userJson);
        } else {
          throw Exception('Failed to upload profile: ${resp.statusCode} ${resp.body}');
        }
      }

      // Multipart upload
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['name'] = name
        ..fields['age'] = age.toString()
        ..fields['bio'] = bio;

      if (kIsWeb) {
        // Web: must use bytes
        if (imageBytes == null) throw Exception('On web you must provide imageBytes and filename');
        final fName = filename ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final multipart = http.MultipartFile.fromBytes('profilePicture', imageBytes, filename: fName);
        request.files.add(multipart);
      } else {
        // Non-web: prefer fromPath, fallback to bytes
        if (imageFile != null && imageFile.path.isNotEmpty) {
          final filePath = imageFile.path;
          final fName = path.basename(filePath);
          final multipart = await http.MultipartFile.fromPath('profilePicture', filePath, filename: fName);
          request.files.add(multipart);
        } else if (imageBytes != null) {
          final fName = filename ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final multipart = http.MultipartFile.fromBytes('profilePicture', imageBytes, filename: fName);
          request.files.add(multipart);
        } else {
          throw Exception('No valid image provided for upload');
        }
      }

      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        final userJson = j['user'] as Map<String, dynamic>;
        return UserinformationModel.fromMap(userJson);
      } else {
        throw Exception('Failed multipart upload: ${resp.statusCode} ${resp.body}');
      }
    } catch (e, st) {
      throw Exception('Profile upload error: $e\n$st');
    }
  }
}
