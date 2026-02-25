import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/server_setup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/timetable/screens/timetable_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/excuses/screens/excuses_screen.dart';
import '../../features/excuses/screens/create_excuse_screen.dart';
import '../../features/excuses/screens/excuse_detail_screen.dart';
import '../../features/lessons/screens/lessons_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';
import '../../features/substitutions/screens/substitutions_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = auth.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/auth/setup',
        builder: (context, state) => const ServerSetupScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main app with bottom navigation shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/timetable',
            builder: (context, state) => const TimetableScreen(),
          ),
          GoRoute(
            path: '/substitutions',
            builder: (context, state) => const SubstitutionsScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/excuses',
            builder: (context, state) => const ExcusesScreen(),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CreateExcuseScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ExcuseDetailScreen(
                  excuseId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/lessons',
            builder: (context, state) => const LessonsScreen(),
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
