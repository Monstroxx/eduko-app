import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Sprache'),
            subtitle: Text(locale.languageCode == 'de' ? 'Deutsch' : 'English'),
            onTap: () {
              final newLocale = locale.languageCode == 'de'
                  ? const Locale('en')
                  : const Locale('de');
              ref.read(localeProvider.notifier).state = newLocale;
            },
          ),

          // Theme
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Design'),
            subtitle: const Text('System'),
            onTap: () {
              // TODO: theme switcher
            },
          ),

          const Divider(),

          // Server info
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server'),
            subtitle: const Text('TODO: show connected server URL'),
          ),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Über Eduko'),
            subtitle: const Text('v0.1.0 — Open Source (MIT)'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Eduko',
                applicationVersion: '0.1.0',
                applicationLegalese: '© 2026 Eduko — MIT License',
              );
            },
          ),
        ],
      ),
    );
  }
}
