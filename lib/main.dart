import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/app_logger.dart';
import 'core/config/crash_reporter.dart';
import 'core/constants/api_constants.dart';
import 'injection.dart';
import 'app.dart';

/// Global app config — accessible anywhere after init.
late final AppConfig appConfig;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Resolve environment from --dart-define=FLAVOR ──
  appConfig = AppConfig.fromEnvironment();

  // ── 2. Initialize flavor-aware logging ──
  AppLogger.init(appConfig);
  AppLogger.i('Starting HR Mobile (${appConfig.envName})', tag: 'Boot');

  // ── 3. Configure API base URL from flavor ──
  ApiConstants.configure(appConfig);

  // ── 4. Initialize crash reporting ──
  await CrashReporter.init(appConfig);

  // ── 5. Initialize data-layer DI (GetIt) — NOT MODIFIED ──
  await initDependencies();

  AppLogger.i('All dependencies initialized', tag: 'Boot');

  // ── 6. Launch app ──
  runApp(
    const ProviderScope(
      child: HrMobileApp(),
    ),
  );
}
