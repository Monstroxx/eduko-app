import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs a no-op mock for the FlutterSecureStorage method channel so that
/// [AuthNotifier] (which calls storage in its constructor) works in tests.
///
/// Call once inside [setUpAll] or [setUp] before pumping any widget that
/// creates an [AuthNotifier].
void setupSecureStorageMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'read':
          return null; // no saved token → starts unauthenticated
        case 'write':
        case 'delete':
        case 'deleteAll':
          return null;
        case 'containsKey':
          return false;
        case 'readAll':
          return <String, String>{};
        default:
          return null;
      }
    },
  );
}
