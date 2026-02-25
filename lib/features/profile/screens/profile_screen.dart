import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/excuse_provider.dart';
import '../../../core/models/excuse.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '${auth.firstName?.isNotEmpty == true ? auth.firstName!.substring(0, 1) : ''}'
              '${auth.lastName?.isNotEmpty == true ? auth.lastName!.substring(0, 1) : ''}',
              style: TextStyle(
                fontSize: 28,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${auth.firstName ?? ''} ${auth.lastName ?? ''}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Chip(
            avatar: Icon(_roleIcon(auth.role ?? ''), size: 16),
            label: Text(_roleLabel(auth.role ?? '')),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 32),

          // Stats cards
          if (auth.isStudent) ...[
            _StatsSection(ref: ref),
          ],

          if (auth.isTeacher || auth.isAdmin) ...[
            _TeacherStats(ref: ref),
          ],

          const SizedBox(height: 24),

          // Account info
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Schul-ID'),
                  subtitle: Text(auth.schoolId ?? '–'),
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('User-ID'),
                  subtitle: Text(auth.userId ?? '–'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Abmelden'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) => switch (role) {
        'student' => Icons.school,
        'teacher' => Icons.person,
        'admin' => Icons.admin_panel_settings,
        _ => Icons.person,
      };

  String _roleLabel(String role) => switch (role) {
        'student' => 'Schüler',
        'teacher' => 'Lehrer',
        'admin' => 'Verwaltung',
        _ => role,
      };
}

class _StatsSection extends StatelessWidget {
  final WidgetRef ref;
  const _StatsSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final excusesAsync = ref.watch(excusesProvider);

    return excusesAsync.when(
      data: (excuses) {
        final pending =
            excuses.where((e) => e.status == ExcuseStatus.pending).length;
        final approved =
            excuses.where((e) => e.status == ExcuseStatus.approved).length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.pending_outlined,
                    color: Colors.orange,
                    label: 'Ausstehend',
                    value: '$pending',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    label: 'Genehmigt',
                    value: '$approved',
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TeacherStats extends StatelessWidget {
  final WidgetRef ref;
  const _TeacherStats({required this.ref});

  @override
  Widget build(BuildContext context) {
    final excusesAsync = ref.watch(excusesProvider);

    return excusesAsync.when(
      data: (excuses) {
        final pending =
            excuses.where((e) => e.status == ExcuseStatus.pending).length;
        return _StatCard(
          icon: Icons.pending_actions,
          color: Colors.orange,
          label: 'Offene Entschuldigungen',
          value: '$pending',
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
