import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/excuse.dart';
import '../../../core/theme/app_theme.dart';

class ExcusesScreen extends ConsumerWidget {
  const ExcusesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return DefaultTabController(
      length: auth.isStudent ? 1 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entschuldigungen'),
          bottom: auth.isStudent
              ? null
              : const TabBar(
                  tabs: [
                    Tab(text: 'Ausstehend'),
                    Tab(text: 'Entschuldigt'),
                    Tab(text: 'Abgelehnt'),
                  ],
                ),
        ),
        body: auth.isStudent
            ? _StudentExcuseList()
            : TabBarView(
                children: [
                  _ExcuseList(status: ExcuseStatus.pending),
                  _ExcuseList(status: ExcuseStatus.approved),
                  _ExcuseList(status: ExcuseStatus.rejected),
                ],
              ),
        floatingActionButton: auth.isStudent
            ? FloatingActionButton.extended(
                onPressed: () => context.go('/excuses/create'),
                icon: const Icon(Icons.add),
                label: const Text('Neue Entschuldigung'),
              )
            : null,
      ),
    );
  }
}

class _StudentExcuseList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch student's excuses
    return const Center(child: Text('Keine Entschuldigungen'));
  }
}

class _ExcuseList extends ConsumerWidget {
  final ExcuseStatus status;

  const _ExcuseList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch excuses filtered by status
    return const Center(child: Text('Keine Entschuldigungen'));
  }
}
