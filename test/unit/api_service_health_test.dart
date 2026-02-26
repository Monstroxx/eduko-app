import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:eduko/core/api/api_service.dart';

/// Creates an [ApiService] backed by a [DioAdapter] for controlled test responses.
(ApiService, DioAdapter) _makeService({String baseUrl = 'http://localhost:8080/api/v1'}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  final adapter = DioAdapter(dio: dio);
  return (ApiService(dio), adapter);
}

void main() {
  group('ApiService.checkHealth', () {
    test('returns true when server responds 200', () async {
      final (service, adapter) = _makeService();
      adapter.onGet(
        'http://localhost:8080/health',
        (server) => server.reply(200, {'status': 'ok', 'version': '0.1.0'}),
      );

      expect(await service.checkHealth(), isTrue);
    });

    test('returns false when server is unreachable (connection error)', () async {
      final (service, adapter) = _makeService();
      adapter.onGet(
        'http://localhost:8080/health',
        (server) => server.throws(
          500,
          DioException(
            requestOptions: RequestOptions(path: '/health'),
            type: DioExceptionType.connectionError,
          ),
        ),
      );

      expect(await service.checkHealth(), isFalse);
    });

    test('returns false on non-200 status', () async {
      final (service, adapter) = _makeService();
      adapter.onGet(
        'http://localhost:8080/health',
        (server) => server.reply(503, 'Service Unavailable'),
      );

      // The method checks statusCode == 200 strictly
      final result = await service.checkHealth();
      // 503 should return false since statusCode != 200
      expect(result, isFalse);
    });

    test('strips /api/v1 to build health URL correctly', () async {
      // Verify that the health URL is derived correctly
      final dio = Dio(BaseOptions(baseUrl: 'http://myserver:8080/api/v1'));
      final adapter = DioAdapter(dio: dio);
      final service = ApiService(dio);

      adapter.onGet(
        'http://myserver:8080/health',
        (server) => server.reply(200, {'status': 'ok'}),
      );

      expect(await service.checkHealth(), isTrue);
    });
  });

  group('ApiService.login', () {
    test('sends correct JSON body', () async {
      final (service, adapter) = _makeService();
      adapter.onPost(
        '/auth/login',
        (server) => server.reply(200, {
          'token': 'test-jwt-token',
          'user': {
            'id': 'user-123',
            'school_id': 'school-456',
            'role': 'student',
            'first_name': 'Max',
            'last_name': 'Muster',
          }
        }),
        data: {'username': 'max', 'password': 'pass123', 'school_id': ''},
      );

      final response = await service.login('max', 'pass123', '');
      expect(response.statusCode, 200);
      expect(response.data['token'], 'test-jwt-token');
    });

    test('throws DioException on 401', () async {
      final (service, adapter) = _makeService();
      // Match any POST to /auth/login regardless of body ordering
      adapter.onPost(
        '/auth/login',
        (server) => server.reply(401, {'message': 'invalid credentials'}),
        data: Matchers.any,
      );

      await expectLater(
        service.login('wrong', 'creds', ''),
        throwsA(isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        )),
      );
    });
  });
}
