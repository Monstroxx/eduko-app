import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eduko/core/api/api_service.dart';
import 'package:eduko/core/auth/auth_provider.dart';
import 'package:eduko/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_notifier.dart';
import '../helpers/test_api_service.dart';

/// Pumps the [LoginScreen] with [apiServiceProvider] overridden.
/// [authProvider] uses the real [AuthNotifier], but FlutterSecureStorage is
/// mocked via [setupSecureStorageMock] so no platform channel is needed.
Widget _buildLoginScreen(ApiService fakeService) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(fakeService),
    ],
    child: const MaterialApp(
      home: LoginScreen(),
    ),
  );
}

void main() {
  setUp(setupSecureStorageMock);

  group('LoginScreen — form validation', () {
    testWidgets('shows error when username is empty', (tester) async {
      final svc = FakeApiService(healthResult: true);
      await tester.pumpWidget(_buildLoginScreen(svc));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Benutzername eingeben'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      final svc = FakeApiService(healthResult: true);
      await tester.pumpWidget(_buildLoginScreen(svc));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Benutzername'),
        'admin',
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Passwort eingeben'), findsOneWidget);
    });
  });

  group('LoginScreen — server unreachable', () {
    testWidgets('shows "Server nicht erreichbar" when health check fails',
        (tester) async {
      final svc = FakeApiService(healthResult: false);
      await tester.pumpWidget(_buildLoginScreen(svc));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Benutzername'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passwort'),
        'admin123',
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Server nicht erreichbar'), findsOneWidget);
    });
  });

  group('LoginScreen — connection error', () {
    testWidgets('shows helpful message on DioException connectionError',
        (tester) async {
      final svc = FakeApiService(
        healthResult: true,
        loginException: fakeConnectionError(),
      );
      await tester.pumpWidget(_buildLoginScreen(svc));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Benutzername'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passwort'),
        'admin123',
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Verbindung zum Server fehlgeschlagen'),
        findsOneWidget,
      );
    });
  });

  group('LoginScreen — wrong credentials', () {
    testWidgets('shows "Benutzername oder Passwort falsch" on 401',
        (tester) async {
      final svc = FakeApiService(
        healthResult: true,
        loginException: fakeUnauthorized(),
      );
      await tester.pumpWidget(_buildLoginScreen(svc));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Benutzername'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passwort'),
        'wrongpassword',
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Benutzername oder Passwort falsch'),
        findsOneWidget,
      );
    });
  });

  group('LoginScreen — successful login', () {
    testWidgets('authProvider state is authenticated after success',
        (tester) async {
      final svc = FakeApiService(
        healthResult: true,
        loginResponse: fakeResponse(data: {
          'token': 'valid-jwt',
          'user': {
            'id': 'user-001',
            'school_id': 'school-001',
            'role': 'admin',
            'first_name': 'Max',
            'last_name': 'Muster',
          }
        }),
      );

      AuthState? capturedState;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(svc),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedState = ref.watch(authProvider);
              return const MaterialApp(home: LoginScreen());
            },
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Benutzername'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passwort'),
        'admin123',
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(capturedState?.token, 'valid-jwt');
      expect(capturedState?.role, 'admin');
      expect(capturedState?.isAuthenticated, isTrue);
    });
  });

  group('LoginScreen — loading indicator', () {
    testWidgets('spinner visible while request is in flight', (tester) async {
      final svc = _ControlledApiService();
      await tester.pumpWidget(_buildLoginScreen(svc));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Benutzername'),
        'admin',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passwort'),
        'admin123',
      );

      // Tap fires _login(), which sets _loading=true then awaits checkHealth
      await tester.tap(find.byType(FilledButton));
      await tester.pump(); // run microtasks: setState(_loading=true)
      await tester.pump(); // rebuild widget tree with spinner

      // While loading, the button must be disabled (onPressed == null)
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);

      // Let the request finish
      svc.release();
      await tester.pumpAndSettle();
    });
  });
}

/// An [ApiService] whose [checkHealth] blocks until [release] is called.
/// Lets tests assert on the in-flight loading state.
class _ControlledApiService extends FakeApiService {
  final _completer = Completer<void>();

  _ControlledApiService()
      : super(
          loginException: DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.connectionError,
          ),
        );

  void release() {
    if (!_completer.isCompleted) _completer.complete();
  }

  @override
  Future<bool> checkHealth() async {
    await _completer.future;
    return true;
  }
}
