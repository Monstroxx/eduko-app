// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Plain-localStorage storage for Flutter Web.
///
/// [FlutterSecureStorage] on web requires `window.crypto.subtle` (Web Crypto
/// API), which is only available in secure contexts (HTTPS). On plain HTTP
/// (local dev / LAN), `subtle` is `undefined` and every read/write throws a
/// null-check error.  This implementation stores tokens unencrypted in
/// `localStorage` — acceptable for a development/LAN deployment but should be
/// replaced by HTTPS + FlutterSecureStorage for production.
class AuthStorage {
  static Future<String?> read(String key) async =>
      html.window.localStorage[key];

  static Future<void> write(String key, String value) async =>
      html.window.localStorage[key] = value;

  static Future<void> delete(String key) async =>
      html.window.localStorage.remove(key);

  static Future<void> deleteAll() async {
    for (final key in [
      'auth_token',
      'user_id',
      'school_id',
      'role',
      'first_name',
      'last_name',
    ]) {
      html.window.localStorage.remove(key);
    }
  }
}
