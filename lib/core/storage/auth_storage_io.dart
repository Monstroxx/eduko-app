import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for native platforms (iOS, Android, desktop).
/// Uses the OS keychain / keystore via [FlutterSecureStorage].
class AuthStorage {
  static const _s = FlutterSecureStorage();

  static Future<String?> read(String key) => _s.read(key: key);

  static Future<void> write(String key, String value) =>
      _s.write(key: key, value: value);

  static Future<void> delete(String key) => _s.delete(key: key);

  static Future<void> deleteAll() => _s.deleteAll();
}
