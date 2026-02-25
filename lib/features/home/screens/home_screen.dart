import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/connectivity_provider.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final location = GoRouterState.of(context).matchedLocation;

    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline)
            MaterialBanner(
              content: const Text('Offline — Daten aus lokalem Cache'),
              leading: const Icon(Icons.cloud_off, color: Colors.orange),
              backgroundColor: Colors.orange.shade50,
              actions: [const SizedBox.shrink()],
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(location, auth.role ?? 'student'),
        onDestinationSelected: (i) => _onTap(context, i, auth.role ?? 'student'),
        destinations: _destinations(auth.role ?? 'student'),
      ),
    );
  }

  List<NavigationDestination> _destinations(String role) {
    final items = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Übersicht',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_today_outlined),
        selectedIcon: Icon(Icons.calendar_today),
        label: 'Stundenplan',
      ),
      const NavigationDestination(
        icon: Icon(Icons.swap_horiz_outlined),
        selectedIcon: Icon(Icons.swap_horiz),
        label: 'Vertretung',
      ),
    ];

    if (role == 'teacher' || role == 'admin') {
      items.add(const NavigationDestination(
        icon: Icon(Icons.fact_check_outlined),
        selectedIcon: Icon(Icons.fact_check),
        label: 'Anwesenheit',
      ));
    }

    items.add(const NavigationDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: 'Entschuldigung',
    ));

    items.add(const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profil',
    ));

    return items;
  }

  int _selectedIndex(String location, String role) {
    final routes = _routes(role);
    final idx = routes.indexWhere((r) => location == r || (r != '/' && location.startsWith(r)));
    return idx >= 0 ? idx : 0;
  }

  List<String> _routes(String role) {
    final r = ['/', '/timetable', '/substitutions'];
    if (role == 'teacher' || role == 'admin') r.add('/attendance');
    r.addAll(['/excuses', '/profile']);
    return r;
  }

  void _onTap(BuildContext context, int index, String role) {
    final routes = _routes(role);
    if (index < routes.length) context.go(routes[index]);
  }
}
