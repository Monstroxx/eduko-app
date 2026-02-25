import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';

class ServerSetupScreen extends StatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  String? _serverVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64),

                // Logo area
                Icon(Icons.school, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Eduko',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Verbinde dich mit deiner Schule',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://192.168.1.100:8080',
                    prefixIcon: const Icon(Icons.dns_outlined),
                    suffixIcon: _serverVersion != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _connect(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'URL eingeben';
                    if (!v.startsWith('http')) return 'Muss mit http(s):// beginnen';
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(color: theme.colorScheme.error)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (_serverVersion != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text('Verbunden — $_serverVersion',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: _loading ? null : _connect,
                  icon: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: Text(_serverVersion != null ? 'Weiter zur Anmeldung' : 'Verbinden'),
                ),

                const SizedBox(height: 48),

                // Help text
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline, size: 18, color: theme.colorScheme.outline),
                            const SizedBox(width: 8),
                            Text('Hilfe', style: theme.textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gib die URL deines Eduko-Servers ein. '
                          'Du bekommst diese von deiner Schul-IT.\n\n'
                          'Beispiele:\n'
                          '• http://192.168.1.100:8080\n'
                          '• https://eduko.meine-schule.de',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    // If already verified, go to login.
    if (_serverVersion != null) {
      await AppConfig.setServerUrl(_controller.text.trim());
      if (mounted) context.go('/auth/login');
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _serverVersion = null;
    });

    try {
      final url = _controller.text.trim();
      final apiUrl = url.endsWith('/api/v1') ? url : '$url/api/v1';

      // Health check — try to hit the API.
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      // Try a lightweight endpoint.
      final response = await dio.get('$apiUrl/school/settings',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      // 401 = API works, just not authenticated. That's fine.
      if (response.statusCode == 200 || response.statusCode == 401) {
        await AppConfig.setServerUrl(url);
        setState(() => _serverVersion = 'Eduko Server');
      } else {
        setState(() => _error = 'Server antwortet nicht korrekt (${response.statusCode})');
      }
    } on DioException catch (e) {
      setState(() {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          _error = 'Server nicht erreichbar. URL prüfen.';
        } else {
          _error = 'Verbindungsfehler: ${e.message}';
        }
      });
    } catch (e) {
      setState(() => _error = 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
