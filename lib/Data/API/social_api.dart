import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:html' as html;
import 'package:logging/logging.dart';

class SocialAuth {
  final String serverBase = 'http://localhost:3000/api/auth';
  final _secureStorage = const FlutterSecureStorage();

  /// Central logger instance
  static final _log = Logger('SocialAuth');

  SocialAuth() {
    // Configure root logging once — outputs to console
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // Example format: [INFO] 2025-10-29 17:30:00.000 SocialAuth: message
      // ignore: avoid_print
      print(
          '[${record.level.name}] ${record.time.toIso8601String()} ${record.loggerName}: ${record.message}');
    });
  }

  Future<String?> signInWithProvider(
    String provider, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final authUrl = '$serverBase/$provider${kIsWeb ? '?web=1' : ''}';
    _log.info('Starting OAuth flow for provider=$provider (web=$kIsWeb)');

    if (kIsWeb) {
      final width = 600;
      final height = 700;
      final screenWidth = html.window.screen?.width ?? 1024;
      final screenHeight = html.window.screen?.height ?? 768;
      final left = ((screenWidth - width) / 2).round();
      final top = ((screenHeight - height) / 2).round();
      final features =
          'popup=yes,width=$width,height=$height,left=$left,top=$top,scrollbars=yes';

      html.WindowBase? popup;
      try {
        popup = html.window.open(authUrl, 'oauth_popup', features);
        _log.info('Popup window opened successfully.');
      } catch (e) {
        _log.warning('Failed to open popup: $e');
        popup = null;
      }

      if (popup == null) {
        _log.warning('Popup is null — redirecting full page to $authUrl');
        html.window.location.href = authUrl;
        return null;
      }

      final completer = Completer<String?>();
      late StreamSubscription<html.MessageEvent> sub;
      Timer? timeoutTimer;
      Timer? pollTimer;

      void messageHandler(html.MessageEvent event) {
        try {
          final origin = event.origin;
          final frontendOrigin = _getFrontendOrigin();
          final serverOrigin = _getServerOrigin();

          final acceptFromFrontend =
              frontendOrigin.isNotEmpty && origin == frontendOrigin;
          final acceptFromServer =
              serverOrigin.isNotEmpty && origin == serverOrigin;
          final permissive =
              frontendOrigin.isEmpty && serverOrigin.isEmpty;

          if (!(acceptFromFrontend || acceptFromServer || permissive)) {
            _log.fine('Message ignored from untrusted origin: $origin');
            return;
          }

          final data = event.data;
          if (data is Map && data['type'] == 'oauth' && data['token'] is String) {
            final token = data['token'] as String;
            html.window.localStorage.remove('oauth_token');
            if (!completer.isCompleted) completer.complete(token);
            _log.info('Received token via message event');
          } else if (data is String && data.isNotEmpty) {
            if (!completer.isCompleted) completer.complete(data);
            _log.info('Received raw token string via message event');
          }
        } catch (e) {
          _log.severe('Message handler error: $e');
        }
      }

      // subscribe
      sub = html.window.onMessage.listen(messageHandler);

      // timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          _log.warning('OAuth flow timed out.');
          completer.complete(null);
        }
      });

      // poll popup
      pollTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        try {
          if (popup == null || (popup.closed ?? true)) {
            t.cancel();
            if (!completer.isCompleted) {
              _log.info('Popup closed before completion.');
              completer.complete(null);
            }
          }
        } catch (_) {}
      });

      final token = await completer.future;

      // cleanup
      try {
        await sub.cancel();
      } catch (_) {}
      timeoutTimer.cancel();
      pollTimer.cancel();

      _log.info('OAuth flow completed. Token: ${token ?? "null"}');

      if (token != null && token.isNotEmpty) {
        await saveToken(token);
        return token;
      }

      // fallback to localStorage
      try {
        final fallback = html.window.localStorage['oauth_token'];
        if (fallback != null && fallback.isNotEmpty) {
          html.window.localStorage.remove('oauth_token');
          await saveToken(fallback);
          _log.info('Using fallback token from localStorage.');
          return fallback;
        }
      } catch (e) {
        _log.warning('LocalStorage fallback error: $e');
      }

      _log.warning('No token obtained after OAuth flow.');
      return null;
    } else {
      return await _mobileSignIn(authUrl);
    }
  }

  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      try {
        html.window.localStorage['jwt'] = token;
        _log.info('Saved JWT token to localStorage.');
      } catch (e) {
        _log.warning('Failed to save JWT to localStorage: $e');
      }
    } else {
      await _secureStorage.write(key: 'jwt', value: token);
      _log.info('Saved JWT token securely on device.');
    }
  }

  Future<String?> readToken() async {
    if (kIsWeb) {
      try {
        final token = html.window.localStorage['jwt'];
        _log.fine('Read JWT from localStorage: ${token ?? "null"}');
        return token;
      } catch (e) {
        _log.warning('Error reading JWT from localStorage: $e');
        return null;
      }
    } else {
      final token = await _secureStorage.read(key: 'jwt');
      _log.fine('Read JWT from secure storage: ${token ?? "null"}');
      return token;
    }
  }

  Future<String?> _mobileSignIn(String authUrl) async {
    _log.info('Mobile sign-in flow not implemented. URL=$authUrl');
    return null;
  }

  String _getFrontendOrigin() {
    try {
      final loc = html.window.location;
      final origin = '${loc.protocol}//${loc.host}';
      _log.fine('Frontend origin: $origin');
      return origin;
    } catch (e) {
      _log.warning('Error reading frontend origin: $e');
      return '';
    }
  }

  String _getServerOrigin() {
    try {
      final uri = Uri.parse(serverBase);
      final origin = uri.origin;
      _log.fine('Server origin: $origin');
      return origin;
    } catch (e) {
      _log.warning('Error reading server origin: $e');
      return '';
    }
  }
}
