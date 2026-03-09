import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';

import '../../../../shared/widgets/shared_widgets.dart';
import '../providers/auth_providers.dart';

/// Splash screen shown while restoring the session.
///
/// This screen triggers [AuthNotifier.checkSession] once.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off session check.
    Future.microtask(() => ref.read(authProvider.notifier).checkSession());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LoadingIndicator(message: 'Loading...'.tr(context)),
      ),
    );
  }
}
