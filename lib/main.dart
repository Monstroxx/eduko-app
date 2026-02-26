import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/i18n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('EDUKO_ERROR: ${details.exception}');
    debugPrint('EDUKO_STACK: ${details.stack}');
  };

  runApp(
    const ProviderScope(
      child: EdukoApp(),
    ),
  );
}

class EdukoApp extends ConsumerWidget {
  const EdukoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Eduko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.delegates,
      routerConfig: router,
    );
  }
}
