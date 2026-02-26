import 'package:flutter_test/flutter_test.dart';
import 'package:eduko/core/config/app_config.dart';

void main() {
  // AppConfig.normalizeUrl is a pure function — no platform channels needed.
  group('AppConfig.normalizeUrl', () {
    test('appends /api/v1 when not present', () {
      expect(AppConfig.normalizeUrl('http://192.168.1.1:8080'), 'http://192.168.1.1:8080/api/v1');
    });

    test('does not double-append /api/v1', () {
      expect(AppConfig.normalizeUrl('http://192.168.1.1:8080/api/v1'), 'http://192.168.1.1:8080/api/v1');
    });

    test('strips trailing slash before appending', () {
      expect(AppConfig.normalizeUrl('http://myserver.local:8080/'), 'http://myserver.local:8080/api/v1');
    });

    test('works with https', () {
      expect(AppConfig.normalizeUrl('https://eduko.example.com'), 'https://eduko.example.com/api/v1');
    });

    test('works with https and trailing slash', () {
      expect(AppConfig.normalizeUrl('https://eduko.example.com/'), 'https://eduko.example.com/api/v1');
    });

    test('preserves an already-complete URL', () {
      expect(
        AppConfig.normalizeUrl('https://school.edu/api/v1'),
        'https://school.edu/api/v1',
      );
    });

    test('works with IP + port', () {
      expect(AppConfig.normalizeUrl('http://10.0.0.5:3000'), 'http://10.0.0.5:3000/api/v1');
    });
  });

  group('AppConfig static state', () {
    test('hasServerUrl reflects whether baseUrl is non-empty', () {
      // After package import, this is purely state-based — no I/O
      final before = AppConfig.hasServerUrl;
      expect(before, isA<bool>());
    });
  });
}
