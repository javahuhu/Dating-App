// lib/Data/SocialAuth.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


import 'dart:html' as html;

class SocialAuth {
  final String serverBase = 'http://localhost:3000/api/auth';
  final _secureStorage = const FlutterSecureStorage();

  
  Future<String?> signInWithProvider(String provider, {Duration timeout = const Duration(minutes: 2)}) async {
    final authUrl = '$serverBase/$provider${kIsWeb ? '?web=1' : ''}';

    if (kIsWeb) {
    
      final width = 600;
      final height = 700;
      
      final screenWidth = html.window.screen?.width ?? 1024;
      final screenHeight = html.window.screen?.height ?? 768;
      final left = ((screenWidth - width) / 2).round();
      final top = ((screenHeight - height) / 2).round();
      final features = 'popup=yes,width=$width,height=$height,left=$left,top=$top,scrollbars=yes';

      html.WindowBase? popup;
      try {
        popup = html.window.open(authUrl, 'oauth_popup', features);
      } catch (_) {
        popup = null;
      }

    
      if (popup == null) {
      
        html.window.location.href = authUrl;
        return null;
      }

      final completer = Completer<String?>();
      late StreamSubscription<html.MessageEvent> sub;
      Timer? timeoutTimer;
      Timer? pollTimer;

  
      void messageHandler(html.MessageEvent event) {
        try {
          final origin = event.origin ?? '';
          final frontendOrigin = _getFrontendOrigin();
          final serverOrigin = _getServerOrigin();

          // debug
          print('main-window: message received, origin=$origin, expected(frontend)=$frontendOrigin, expected(server)=$serverOrigin, data=${event.data}');

        
          final acceptFromFrontend = frontendOrigin.isNotEmpty && origin == frontendOrigin;
          final acceptFromServer = serverOrigin.isNotEmpty && origin == serverOrigin;
          final permissive = frontendOrigin.isEmpty && serverOrigin.isEmpty;

          if (!(acceptFromFrontend || acceptFromServer || permissive)) {
            print('main-window: origin not allowed -> ignoring');
            return;
          }

          final data = event.data;
          if (data is Map && data['type'] == 'oauth' && data['token'] is String) {
            final token = data['token'] as String;
            // remove fallback token if present
            try {
              html.window.localStorage.remove('oauth_token');
            } catch (_) {}
            if (!completer.isCompleted) completer.complete(token);
          } else if (data is String) {
            if (!completer.isCompleted && data.isNotEmpty) completer.complete(data);
          }
        } catch (e) {
          print('main-window: message handler error: $e');
        }
      }

      // subscribe
      sub = html.window.onMessage.listen(messageHandler);

      // timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });

      // poll for popup closed
      pollTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        try {
          if (popup == null || (popup.closed ?? true)) {
            t.cancel();
            if (!completer.isCompleted) completer.complete(null);
          }
        } catch (_) {
          // ignore cross-origin access exceptions
        }
      });

      final token = await completer.future;

      // cleanup
      try {
        await sub.cancel();
      } catch (_) {}
      timeoutTimer?.cancel();
      pollTimer?.cancel();

      print('main-window: signInWithProvider completer returned token=$token');

      if (token != null && token.isNotEmpty) {
        // store token
        await saveToken(token);
        return token;
      }

      // FALLBACK: check localStorage 'oauth_token' (set by popup as fallback)
      try {
        final fallback = html.window.localStorage['oauth_token'];
        print('main-window: fallback oauth_token from localStorage = $fallback');
        if (fallback != null && fallback.isNotEmpty) {
          // remove it immediately to avoid reuse
          try {
            html.window.localStorage.remove('oauth_token');
          } catch (_) {}
          await saveToken(fallback);
          return fallback;
        }
      } catch (e) {
        print('main-window: localStorage fallback error: $e');
      }

      // nothing found
      return null;
    } else {
      // Non-web (mobile/desktop) flow — use flutter_web_auth or similar
      return await _mobileSignIn(authUrl);
    }
  }

  // Helper: store token (web -> localStorage; mobile -> secure storage)
  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      try {
        html.window.localStorage['jwt'] = token;
        print('main-window: saved jwt to localStorage');
      } catch (e) {
        print('main-window: saveToken localStorage error: $e');
      }
    } else {
      await _secureStorage.write(key: 'jwt', value: token);
    }
  }

  Future<String?> readToken() async {
    if (kIsWeb) {
      try {
        return html.window.localStorage['jwt'];
      } catch (_) {
        return null;
      }
    } else {
      return await _secureStorage.read(key: 'jwt');
    }
  }

  Future<String?> _mobileSignIn(String authUrl) async {
    
    return null;
  }

  String _getFrontendOrigin() {
   
    try {
      final loc = html.window.location;
      final origin = '${loc.protocol}//${loc.host}';
      return origin;
    } catch (_) {
      return '';
    }
  }

  
  String _getServerOrigin() {
    try {
      final uri = Uri.parse(serverBase);
      return uri.origin; 
    } catch (_) {
      return '';
    }
  }
}
