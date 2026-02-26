import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/auth_storage.dart';

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

  AuthNotifier(this.ref) : super(const AuthState()) {
    _loadSavedAuth();
  }

  Future<void> _loadSavedAuth() async {
    try {
      final token = await AuthStorage.read('auth_token');
      final userId = await AuthStorage.read('user_id');
      final schoolId = await AuthStorage.read('school_id');
      final role = await AuthStorage.read('role');
      final firstName = await AuthStorage.read('first_name');
      final lastName = await AuthStorage.read('last_name');

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
    } catch (e) {
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
    await AuthStorage.write('auth_token', token);
    await AuthStorage.write('user_id', userId);
    await AuthStorage.write('school_id', schoolId);
    await AuthStorage.write('role', role);
    await AuthStorage.write('first_name', firstName);
    await AuthStorage.write('last_name', lastName);

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
    await AuthStorage.deleteAll();
    ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
