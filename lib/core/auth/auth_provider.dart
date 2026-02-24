import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

final authTokenProvider = StateProvider<String?>((ref) => null);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;
  final String? userId;
  final String? schoolId;
  final String? role;
  final String? firstName;
  final String? lastName;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.userId,
    this.schoolId,
    this.role,
    this.firstName,
    this.lastName,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    String? userId,
    String? schoolId,
    String? role,
    String? firstName,
    String? lastName,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  static const _storage = FlutterSecureStorage();

  AuthNotifier(this.ref) : super(const AuthState()) {
    _loadSavedAuth();
  }

  Future<void> _loadSavedAuth() async {
    final token = await _storage.read(key: 'auth_token');
    final userId = await _storage.read(key: 'user_id');
    final schoolId = await _storage.read(key: 'school_id');
    final role = await _storage.read(key: 'role');
    final firstName = await _storage.read(key: 'first_name');
    final lastName = await _storage.read(key: 'last_name');

    if (token != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        userId: userId,
        schoolId: schoolId,
        role: role,
        firstName: firstName,
        lastName: lastName,
      );
      ref.read(authTokenProvider.notifier).state = token;
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({
    required String token,
    required String userId,
    required String schoolId,
    required String role,
    required String firstName,
    required String lastName,
  }) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_id', value: userId);
    await _storage.write(key: 'school_id', value: schoolId);
    await _storage.write(key: 'role', value: role);
    await _storage.write(key: 'first_name', value: firstName);
    await _storage.write(key: 'last_name', value: lastName);

    ref.read(authTokenProvider.notifier).state = token;

    state = AuthState(
      status: AuthStatus.authenticated,
      token: token,
      userId: userId,
      schoolId: schoolId,
      role: role,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
