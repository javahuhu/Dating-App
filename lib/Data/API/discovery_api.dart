// lib/data/api/discovery_api.dart
import 'dart:convert';
import 'package:dating_app/Core/AuthStorage/auth_storage.dart';
import 'package:http/http.dart' as http;

class DiscoveryApi {
  final String baseUrl;
  DiscoveryApi({required this.baseUrl});

  Future<String?> _getToken() async {
    return await readToken();
  }

  Future<List<Map<String, dynamic>>> fetchProfiles({
    required double lat,
    required double lon,
    int page = 0,
    int limit = 20,
    int? minAge,
    int? maxAge,
    double? maxDistanceKm,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final qs = <String, String>{
      'lat': lat.toString(),
      'lon': lon.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (minAge != null) qs['minAge'] = minAge.toString();
    if (maxAge != null) qs['maxAge'] = maxAge.toString();
    if (maxDistanceKm != null) qs['maxDistanceKm'] = maxDistanceKm.toString();

    final uri = Uri.parse(
      '$baseUrl/api/discovery/profiles',
    ).replace(queryParameters: qs);
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw Exception('Failed to fetch discovery profiles: ${res.statusCode}');
    final body = jsonDecode(res.body);
    final raw = (body is Map && body.containsKey('profiles'))
        ? body['profiles']
        : body;
    if (raw is List) return List<Map<String, dynamic>>.from(raw.cast<Map>());
    return [];
  }

  Future<Map<String, dynamic>> like(String targetId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final uri = Uri.parse('$baseUrl/api/discovery/$targetId/like');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw Exception('Like failed: ${res.statusCode} ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> skip(String targetId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final uri = Uri.parse('$baseUrl/api/discovery/$targetId/skip');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw Exception('Skip failed: ${res.statusCode} ${res.body}');
  }

  // get sent likes (people current user has liked, waiting)
  Future<List<Map<String, dynamic>>> getSent() async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final uri = Uri.parse(
      '$baseUrl/api/discovery/sent',
    ); // <- matches discoverySentRoute.ts
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Failed to fetch sent likes: ${res.statusCode} ${res.body}',
      );
    }
    final body = jsonDecode(res.body);
    // route returns { success: true, items: [...] }
    final raw = (body is Map && body.containsKey('items'))
        ? body['items']
        : body;
    if (raw is List) return List<Map<String, dynamic>>.from(raw.cast<Map>());
    return [];
  }

  // NEW: get matches (mutual), optional if you want to display matches separately
  Future<List<Map<String, dynamic>>> getMatches() async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final uri = Uri.parse('$baseUrl/api/discovery/matches');
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw Exception('Failed to fetch matches: ${res.statusCode}');
    final body = jsonDecode(res.body);
    final raw = (body is Map && body.containsKey('matches'))
        ? body['matches']
        : body;
    if (raw is List) return List<Map<String, dynamic>>.from(raw.cast<Map>());
    return [];
  }

  String? currentUserId;

  Future<String?> getCurrentUser() async {
    // return cached if present
    if (currentUserId != null) return currentUserId;
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final uri = Uri.parse('$baseUrl/api/auth/me');
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // If backend has no /auth/me, gracefully return null
      return null;
    }
    final body = jsonDecode(res.body);
    // backend expected shape: { success: true, user: { id: '...' } }
    try {
      if (body is Map && body['user'] != null && body['user']['id'] != null) {
        currentUserId = body['user']['id'].toString();
        return currentUserId;
      }
      // alternative shapes: { id: '...' } or { userId: '...' }
      if (body is Map && body['id'] != null) {
        currentUserId = body['id'].toString();
        return currentUserId;
      }
    } catch (_) {}
    return null;
  }

  /// Get messages between current user and partner
  Future<List<Map<String, dynamic>>> getMessages(String partnerId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final uri = Uri.parse('$baseUrl/api/messages/$partnerId');
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw Exception(
        'Failed to fetch messages: ${res.statusCode} ${res.body}',
      );
    final body = jsonDecode(res.body);
    final raw = (body is Map && body.containsKey('messages'))
        ? body['messages']
        : body;
    if (raw is List) return List<Map<String, dynamic>>.from(raw.cast<Map>());
    return [];
  }

  /// Send a message to partner
  Future<Map<String, dynamic>> sendMessage(
    String partnerId,
    String text,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final uri = Uri.parse('$baseUrl/api/messages/$partnerId');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw Exception('Failed to send message: ${res.statusCode} ${res.body}');
    final body = jsonDecode(res.body);
    if (body is Map && body.containsKey('message'))
      return Map<String, dynamic>.from(body['message']);
    if (body is Map) return Map<String, dynamic>.from(body);
    return {};
  }

  /// Unmatch partner (delete match + messages)
  Future<Map<String, dynamic>> unmatch(String partnerId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final uri = Uri.parse('$baseUrl/api/discovery/unmatch/$partnerId');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw Exception('Failed to unmatch: ${res.statusCode} ${res.body}');
    final body = jsonDecode(res.body);
    if (body is Map) return Map<String, dynamic>.from(body);
    return {};
  }

  /// Check whether current user and partnerId are matched (mutual)
  Future<bool> isMatched(String partnerId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final uri = Uri.parse('$baseUrl/api/discovery/isMatched/$partnerId');
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // treat non-2xx as not matched or error
      throw Exception('Failed to check match: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(res.body);
    if (body is Map && body.containsKey('matched'))
      return body['matched'] == true;
    return false;
  }

  // get received likes (people who liked the current user)
  Future<List<Map<String, dynamic>>> getReceived() async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    // matches your discoveryRoute: /api/discovery/likes/received
    final uri = Uri.parse('$baseUrl/api/discovery/likes/received');
    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Failed to fetch received likes: ${res.statusCode} ${res.body}',
      );
    }
    final body = jsonDecode(res.body);
    // server returns { success: true, likes: [...] } per your route
    final raw = (body is Map && body.containsKey('likes'))
        ? body['likes']
        : body;
    if (raw is List) return List<Map<String, dynamic>>.from(raw.cast<Map>());
    return [];
  }

  Future<void> declineReceivedLike(String likerId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');
    final uri = Uri.parse('$baseUrl/api/discovery/likes/decline/$likerId');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to decline like: ${res.statusCode} ${res.body}');
    }
  }
}
