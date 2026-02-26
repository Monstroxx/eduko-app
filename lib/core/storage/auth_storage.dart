/// Platform-conditional auth token storage.
///
/// On native (iOS/Android): uses [FlutterSecureStorage] (encrypted keychain/keystore).
/// On web: uses [localStorage] directly — Web Crypto API (required by
/// flutter_secure_storage) is unavailable on plain HTTP origins.
library;

export 'auth_storage_io.dart' if (dart.library.html) 'auth_storage_web.dart';
