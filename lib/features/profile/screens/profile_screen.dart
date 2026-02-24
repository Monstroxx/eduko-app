import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

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
            child: Text(
              '${auth.firstName?.substring(0, 1) ?? ''}${auth.lastName?.substring(0, 1) ?? ''}',
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${auth.firstName ?? ''} ${auth.lastName ?? ''}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _roleLabel(auth.role ?? ''),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Quick stats for students
          if (auth.isStudent) ...[
            const Card(
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: Colors.orange),
                title: Text('Unentschuldigte Fehlstunden'),
                trailing: Text('0'), // TODO: from provider
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.pending_outlined),
                title: Text('Ausstehende Entschuldigungen'),
                trailing: Text('0'), // TODO: from provider
              ),
            ),
          ],

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

  String _roleLabel(String role) {
    switch (role) {
      case 'student': return 'Schüler';
      case 'teacher': return 'Lehrer';
      case 'admin': return 'Verwaltung';
      default: return role;
    }
  }
}
