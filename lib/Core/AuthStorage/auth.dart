// lib/presentation/auth_success.dart
import 'dart:async';
import 'dart:html' as html; // web-only
import 'package:dating_app/Data/API/social_api.dart';
import 'package:dating_app/Data/API/profile_api.dart';
import 'package:dating_app/Data/Models/userinformation_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthSuccessPage extends StatefulWidget {
  const AuthSuccessPage({super.key});
  @override
  State<AuthSuccessPage> createState() => _AuthSuccessPageState();
}

class _AuthSuccessPageState extends State<AuthSuccessPage> {
  final _auth = SocialAuth();
  final _profileApi = ProfileApi();
  bool _processing = true;

  @override
  void initState() {
    super.initState();

    Timer.run(_handleRedirect);
  }

  Future<void> _clearTokenFromUrl() async {
    try {
      final uri = Uri.parse(html.window.location.href);
      final params = Map<String, List<String>>.from(uri.queryParametersAll);
      params.remove('token');
      final newQuery = params.entries
          .expand((e) => e.value.map((v) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(v)}'))
          .join('&');
      final cleaned = uri.replace(query: newQuery);
      html.window.history.replaceState(null, '', cleaned.toString());
    } catch (_) {
      // ignore failures to clear URL
    }
  }
Future<void> _handleRedirect() async {
  try {
    final uri = Uri.parse(html.window.location.href);
    String? token = uri.queryParameters['token'];
    
    debugPrint('URL token parameter: $token');
    debugPrint('Full URL: ${uri.toString()}');

    // Try fallback from storage if no query param
    if (token == null) {
      token = await _auth.readToken();
      debugPrint('Token from storage: $token');
    }

    if (token == null || token.isEmpty) {
      debugPrint('No token found, redirecting to home');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return;
    }

    debugPrint('Saving token to storage...');
    await _auth.saveToken(token);
    
    // Verify the token was saved
    final savedToken = await _auth.readToken();
    debugPrint('Token verification - read back: $savedToken');

    // Fetch profile
    UserinformationModel? profile;
    try {
      profile = await _profileApi.fetchProfile(token);
      debugPrint('Profile fetch successful: ${profile != null}');
    } catch (e) {
      debugPrint('Profile fetch error: $e');
      profile = null;
    }

    // Determine completeness
    final picture = (profile?.profilePictureUrl ?? profile?.profilePicture ?? '').toString().trim();
    final hasProfile = profile != null &&
        profile.name.trim().isNotEmpty &&
        profile.age > 0 &&
        profile.bio.trim().isNotEmpty &&
        picture.isNotEmpty;

    debugPrint('Profile completeness check - hasProfile: $hasProfile');
    debugPrint('Name: ${profile?.name}, Age: ${profile?.age}, Bio: ${profile?.bio}, Picture: $picture');

    // Clean up token from URL - ADD THIS BACK
    await _clearTokenFromUrl();

    if (!mounted) return;

    // ✅ Run navigation on next frame to ensure context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (hasProfile) {
        debugPrint('Redirecting to homepage');
        context.go('/homepage');
      } else {
        debugPrint('Redirecting to setup');
        context.go('/setup');
      }
    });
  } catch (e, st) {
    debugPrint('Auth redirect error: $e\n$st');
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/');
    });
  } finally {
    if (mounted) setState(() => _processing = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _processing
            ? Column(mainAxisSize: MainAxisSize.min, children: const [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Finalizing sign-in...'),
              ])
            : const Text('Redirecting...'),
      ),
    );
  }
}
