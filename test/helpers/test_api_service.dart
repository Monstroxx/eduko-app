import 'package:dio/dio.dart';
import 'package:eduko/core/api/api_service.dart';

/// A fake [ApiService] that returns configurable canned responses.
///
/// Used in widget and unit tests to avoid real network calls.
class FakeApiService extends ApiService {
  final bool healthResult;
  final Response? loginResponse;
  final DioException? loginException;

  FakeApiService({
    this.healthResult = true,
    this.loginResponse,
    this.loginException,
  }) : super(_fakeDio());

  static Dio _fakeDio() => Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));

  @override
  Future<bool> checkHealth() async => healthResult;

  @override
  Future<Response> login(
    String username,
    String password,
    String schoolId,
  ) async {
    if (loginException != null) throw loginException!;
    return loginResponse!;
  }
}

/// Builds a [Response] for testing.
Response fakeResponse({
  required Map<String, dynamic> data,
  int statusCode = 200,
}) {
  return Response(
    requestOptions: RequestOptions(path: '/auth/login'),
    data: data,
    statusCode: statusCode,
  );
}

/// Builds a [DioException] of type [connectionError] for testing.
DioException fakeConnectionError() {
  return DioException(
    requestOptions: RequestOptions(path: '/auth/login'),
    type: DioExceptionType.connectionError,
    message: 'Connection refused',
  );
}

/// Builds a [DioException] with HTTP 401 for testing.
DioException fakeUnauthorized() {
  return DioException(
    requestOptions: RequestOptions(path: '/auth/login'),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: '/auth/login'),
      statusCode: 401,
      data: {'message': 'invalid credentials'},
    ),
  );
}
