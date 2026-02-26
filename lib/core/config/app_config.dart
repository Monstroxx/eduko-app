import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static const String appName = 'Eduko';
  static const String apiVersion = 'v1';

  static String _baseUrl = '';
  static String get baseUrl => _baseUrl;
  static bool get hasServerUrl => _baseUrl.isNotEmpty;

  // Only used on non-web platforms. On web, FlutterSecureStorage needs
  // Web Crypto (HTTPS-only). We skip storage entirely on web and always
  // auto-detect the backend URL from window.location.
  static const _storage = FlutterSecureStorage();

  static Future<void> init() async {
    if (kIsWeb) {
      // On web: always auto-detect — no persistent URL needed because
      // the server is always the same host on port 8080.
      _baseUrl = _detectWebBaseUrl();
      return;
    }

    // Mobile / desktop: read previously saved URL.
    final savedUrl = await _storage.read(key: 'server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
    // No saved URL on mobile → forces server setup screen.
  }

  static String _detectWebBaseUrl() {
    // In web, use Uri.base which reflects window.location.
    // Assume backend is on the same host on port 8080.
    final uri = Uri.base;
    final backendUri = uri.replace(port: 8080, path: '/api/v1');
    return backendUri.toString();
  }

  /// Normalizes a raw server URL to end with /api/v1.
  /// Pure function — no side effects, safe to call from tests.
  static String normalizeUrl(String url) {
    var u = url.trimRight();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u.endsWith('/api/v1') ? u : '$u/api/v1';
  }

  /// Save a custom server URL (mobile only; no-op on web).
  static Future<void> setServerUrl(String url) async {
    _baseUrl = normalizeUrl(url);
    if (!kIsWeb) {
      await _storage.write(key: 'server_url', value: _baseUrl);
    }
  }

  /// Clear the saved server URL (mobile only; no-op on web).
  static Future<void> clearServerUrl() async {
    _baseUrl = '';
    if (!kIsWeb) {
      await _storage.delete(key: 'server_url');
    }
  }
}
