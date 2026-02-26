import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static const String appName = 'Eduko';
  static const String apiVersion = 'v1';

  static String _baseUrl = '';
  static String get baseUrl => _baseUrl;
  static bool get hasServerUrl => _baseUrl.isNotEmpty;

  static const storage = FlutterSecureStorage();

  static Future<void> init() async {
    final savedUrl = await storage.read(key: 'server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    } else if (kIsWeb) {
      // On web, auto-detect backend from current host (assumes same-origin or port 8080).
      _baseUrl = _detectWebBaseUrl();
    }
    // On mobile with no saved URL: leave empty → forces server setup screen.
  }

  static String _detectWebBaseUrl() {
    // In web, use Uri.base which reflects window.location.
    final uri = Uri.base;
    // Assume backend runs on same host, port 8080.
    final backendUri = uri.replace(port: 8080, path: '/api/v1');
    return backendUri.toString();
  }

  /// Normalizes a raw server URL to end with /api/v1.
  /// Pure function — no side effects, safe to call from tests.
  static String normalizeUrl(String url) {
    // Remove trailing slash before checking
    var u = url.trimRight();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u.endsWith('/api/v1') ? u : '$u/api/v1';
  }

  static Future<void> setServerUrl(String url) async {
    _baseUrl = normalizeUrl(url);
    await storage.write(key: 'server_url', value: _baseUrl);
  }

  static Future<void> clearServerUrl() async {
    _baseUrl = '';
    await storage.delete(key: 'server_url');
  }
}
