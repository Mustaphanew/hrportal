import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'core/providers/core_providers.dart';
import 'shared/widgets/shared_widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Root application widget.
///
/// Sets up:
/// 1. [ProviderScope] for Riverpod
/// 2. [MaterialApp.router] with GoRouter
/// 3. RTL + Arabic locale
/// 4. Session expired callback → GoRouter redirect
class HrMobileApp extends ConsumerStatefulWidget {
  const HrMobileApp({super.key});

  @override
  ConsumerState<HrMobileApp> createState() => _HrMobileAppState();
}

class _HrMobileAppState extends ConsumerState<HrMobileApp> {
  @override
  void initState() {
    super.initState();
    // Connect SessionManager's expiry callback to show dialog.
    Future.microtask(() {
      final session = ref.read(sessionManagerProvider);
      session.onSessionExpired = (message) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          SessionExpiredDialog.show(ctx);
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'HR Mobile',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],

      // ── Theme ──
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),

      // ── Locale (RTL Arabic) ──
      locale: const Locale('ar'),
      // ── Router ──
      routerConfig: router,
    );
  }
}
