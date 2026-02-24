import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static const String appName = 'Eduko';
  static const String apiVersion = 'v1';

  // Default server URL — user configures on first launch
  static String _baseUrl = 'http://localhost:8080/api/v1';
  static String get baseUrl => _baseUrl;

  static const storage = FlutterSecureStorage();

  static Future<void> init() async {
    final savedUrl = await storage.read(key: 'server_url');
    if (savedUrl != null) {
      _baseUrl = savedUrl;
    }
  }

  static Future<void> setServerUrl(String url) async {
    _baseUrl = url.endsWith('/api/v1') ? url : '$url/api/v1';
    await storage.write(key: 'server_url', value: _baseUrl);
  }
}
