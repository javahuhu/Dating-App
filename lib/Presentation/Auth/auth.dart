// lib/presentation/auth_success.dart
import 'dart:html' as html; // web-only
import 'package:dating_app/Data/API/social_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class AuthSuccessPage extends StatefulWidget {
  const AuthSuccessPage({super.key});
  @override
  State<AuthSuccessPage> createState() => _AuthSuccessPageState();
}

class _AuthSuccessPageState extends State<AuthSuccessPage> {
  final _auth = SocialAuth();

  @override
  void initState() {
    super.initState();
    _grabToken();
  }

  void _grabToken() async {
    final uri = Uri.parse(html.window.location.href);
    final token = uri.queryParameters['token'];
    if (token != null) {
      await _auth.saveToken(token);
      if (!mounted) return;
      context.go('/setup');
    } else {
      if (!mounted) return;
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
