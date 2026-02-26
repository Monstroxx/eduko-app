import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (!auth.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Kein Zugriff')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin-Panel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Verwaltung', style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.outline,
          )),
          const SizedBox(height: 12),

          _AdminTile(
            icon: Icons.calendar_month,
            title: 'Stundenplan verwalten',
            subtitle: 'Einträge anlegen, bearbeiten, löschen',
            onTap: () => context.go('/timetable'),
          ),
          _AdminTile(
            icon: Icons.swap_horiz,
            title: 'Vertretungen anlegen',
            subtitle: 'Vertretungen und Ausfälle eintragen',
            onTap: () => context.go('/substitutions'),
          ),
          _AdminTile(
            icon: Icons.people,
            title: 'Schüler importieren',
            subtitle: 'CSV-Import für neue Schüler (API: POST /api/v1/import/students)',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Import via CSV — API verfügbar: POST /api/v1/import/students')),
            ),
          ),
          _AdminTile(
            icon: Icons.event,
            title: 'Termine anlegen',
            subtitle: 'Klausuren, Schulveranstaltungen',
            onTap: () => context.go('/appointments'),
          ),

          const SizedBox(height: 24),
          Text('System', style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.outline,
          )),
          const SizedBox(height: 12),

          _AdminTile(
            icon: Icons.sync,
            title: 'Daten synchronisieren',
            subtitle: 'App-Cache mit Server abgleichen',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronisation gestartet — pull to refresh im Dashboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
