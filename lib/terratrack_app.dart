import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/settings/settings_provider.dart';

class TerraTrackApp extends ConsumerWidget {
  const TerraTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TerraTrack',
      debugShowCheckedModeBanner: false,
      // Text styles are built at a fixed base size (1.0) here — the actual
      // font-size setting is applied once, globally, via the MediaQuery
      // textScaler override in `builder` below. Baking it into the theme's
      // TextTheme only scaled widgets that read theme.textTheme; plenty of
      // screens (login pages, the admin portal, the New Entry cards) use
      // literal `TextStyle(fontSize: ...)` values, which a theme-only scale
      // can't reach. A single ambient textScaler scales every Text widget
      // in the app — theme-driven or hardcoded — consistently.
      theme: AppTheme.lightTheme(1.0),
      darkTheme: AppTheme.darkTheme(1.0),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return ResponsiveBreakpoints.builder(
          child: MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(settings.fontSize),
            ),
            child: child!,
          ),
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          ],
        );
      },
    );
  }
}
