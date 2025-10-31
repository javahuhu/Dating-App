// lib/data/api/profile_api.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileApi {
  final String baseUrl = 'http://localhost:3000';

  Future<UserinformationModel?> fetchProfile(String token) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/profile/megl'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Fetch profile status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final dynamic jsonBody = jsonDecode(resp.body);

        // Handle different response formats with proper type casting
        Map<String, dynamic> userMap;

        if (jsonBody is Map && jsonBody.containsKey('user')) {
          userMap = Map<String, dynamic>.from(jsonBody['user'] as Map);
        } else if (jsonBody is Map) {
          userMap = Map<String, dynamic>.from(jsonBody);
        } else {
          return null;
        }

        return UserinformationModel.fromMap(userMap);
      } else if (resp.statusCode == 404) {
        // Profile doesn't exist yet
        print('Profile not found (404) - new user');
        return null;
      } else {
        print('Failed to fetch profile: ${resp.statusCode}');
        return null;
      }
    } catch (e, st) {
      print('Profile fetch error: $e');
      return null;
    }
  }

  Future<UserinformationModel> uploadProfile({
    required String token,
    required String name,
    required int age,
    required String bio,
    String? personality,
    String? gender,
    String? motivation,
    String? frustration,
    String? tags,
    File? imageFile,
    Uint8List? imageBytes,
    String? filename,
  }) async {
    final uri = Uri.parse('$baseUrl/api/profile');

    try {
      // If no file, do a JSON post
      if (imageFile == null && imageBytes == null) {
        final body = <String, dynamic>{'name': name, 'age': age, 'bio': bio};

        if (gender != null && gender.isNotEmpty) {
          body['gender'] = gender;
        }
        if (personality != null && personality.isNotEmpty) {
          body['personality'] = personality;
        }
        if (motivation != null && motivation.isNotEmpty) {
          body['motivation'] = motivation;
        }
        if (frustration != null && frustration.isNotEmpty) {
          body['frustration'] = frustration;
        }
        if (tags != null && tags.isNotEmpty) {
          body['tags'] = tags; // FIXED: Changed from 'frustration' to 'tags'
        }

        print('Uploading profile data: $body');

        final resp = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final dynamic jsonBody = jsonDecode(resp.body);
          Map<String, dynamic> userMap;

          if (jsonBody is Map && jsonBody.containsKey('user')) {
            userMap = Map<String, dynamic>.from(jsonBody['user'] as Map);
          } else {
            userMap = Map<String, dynamic>.from(jsonBody);
          }

          return UserinformationModel.fromMap(userMap);
        } else {
          throw Exception(
            'Failed to upload profile: ${resp.statusCode} ${resp.body}',
          );
        }
      }

      // Multipart upload with image
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      // Required fields
      request.fields['name'] = name;
      request.fields['age'] = age.toString();
      request.fields['bio'] = bio;

      if (gender != null && gender.isNotEmpty) {
        request.fields['gender'] = gender;
      }
      if (personality != null && personality.isNotEmpty) {
        request.fields['personality'] = personality;
      }
      if (motivation != null && motivation.isNotEmpty) {
        request.fields['motivation'] = motivation;
      }
      if (frustration != null && frustration.isNotEmpty) {
        request.fields['frustration'] = frustration;
      }
      if (tags != null && tags.isNotEmpty) {
        // ADDED: Include tags in multipart
        request.fields['tags'] = tags;
      }

      // Handle image
      if (kIsWeb) {
        if (imageBytes != null) {
          final fName =
              filename ??
              'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final multipart = http.MultipartFile.fromBytes(
            'profilePicture',
            imageBytes,
            filename: fName,
          );
          request.files.add(multipart);
        }
      } else {
        if (imageFile != null) {
          final multipart = await http.MultipartFile.fromPath(
            'profilePicture',
            imageFile.path,
          );
          request.files.add(multipart);
        }
      }

      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final dynamic jsonBody = jsonDecode(resp.body);
        Map<String, dynamic> userMap;

        if (jsonBody is Map && jsonBody.containsKey('user')) {
          userMap = Map<String, dynamic>.from(jsonBody['user'] as Map);
        } else {
          userMap = Map<String, dynamic>.from(jsonBody);
        }

        return UserinformationModel.fromMap(userMap);
      } else {
        throw Exception('Upload failed: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('Profile upload error: $e');
      throw Exception('Profile upload failed: $e');
    }
  }
}
