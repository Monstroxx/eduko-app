import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/sync_service.dart';
import '../../../core/i18n/app_localizations.dart';

/// Theme mode state.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          // ── Appearance ──
          _SectionHeader('Darstellung'),

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

          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Design'),
            subtitle: Text(_themeModeLabel(themeMode)),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),

          const Divider(),

          // ── Server ──
          _SectionHeader('Verbindung'),

          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server'),
            subtitle: Text(AppConfig.baseUrl),
            onTap: () => _showServerDialog(context),
          ),

          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Daten synchronisieren'),
            subtitle: const Text('Alle Daten vom Server aktualisieren'),
            onTap: () async {
              final sync = ref.read(syncServiceProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronisiere...')),
              );
              try {
                await sync.syncAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synchronisierung abgeschlossen')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                }
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Lokale Daten löschen'),
            subtitle: const Text('Cache leeren (erfordert Neusync)'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cache löschen?'),
                  content: const Text(
                      'Alle lokal gespeicherten Daten werden gelöscht. '
                      'Sie werden beim nächsten Öffnen neu vom Server geladen.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Abbrechen'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Löschen'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(appDatabaseProvider).clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache gelöscht')),
                  );
                }
              }
            },
          ),

          const Divider(),

          // ── About ──
          _SectionHeader('Info'),

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
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Moderne Schulverwaltung. Open Source.\n'
                    'github.com/Monstroxx/eduko-backend\n'
                    'github.com/Monstroxx/eduko-app',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Hell',
        ThemeMode.dark => 'Dunkel',
      };

  void _showThemePicker(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Design wählen'),
        children: [
          for (final mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              value: mode,
              groupValue: current,
              title: Text(_themeModeLabel(mode)),
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).state = v!;
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  void _showServerDialog(BuildContext context) {
    final controller = TextEditingController(text: AppConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.100:8080',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              await AppConfig.setServerUrl(controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Server geändert: ${AppConfig.baseUrl}')),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
