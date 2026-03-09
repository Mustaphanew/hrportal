import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';
import 'package:hr_portal/core/localization/locale_provider.dart';
import 'package:hr_portal/core/theme/theme_mode_provider.dart';
import 'package:pwa_install/pwa_install.dart';

import '../../../../shared/controllers/global_error_handler.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);
    final localeMode = ref.watch(localeModeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Show error snackbar/dialog when error changes.
    ref.listen<LoginFormState>(loginFormProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        if (next.error!.action != ErrorAction.showFieldErrors) {
          GlobalErrorHandler.show(context, next.error!);
        }
      }
    });

    String getLocaleName(AppLocaleMode mode) {
      switch (mode) {
        case AppLocaleMode.system:
          return 'System'.tr(context);
        case AppLocaleMode.en:
          return 'English'.tr(context);
        case AppLocaleMode.ar:
          return 'Arabic'.tr(context);
      }
    }

    // theme
    String getThemeName(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.system:
          return 'System'.tr(context);
        case ThemeMode.light:
          return 'Light'.tr(context);
        case ThemeMode.dark:
          return 'Dark'.tr(context);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──
                  Icon(
                    Icons.business_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Employee Self Service Portal'.tr(context),
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      PopupMenuButton<ThemeMode>(
                        tooltip: 'Theme'.tr(context),
                        padding: EdgeInsets.zero,
                        position: PopupMenuPosition.under,
                        icon: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            disabledForegroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          onPressed: null,
                          icon: const Icon(Icons.brightness_6_outlined),
                          label: Row(
                            children: [
                              Text("${'Theme'.tr(context)} (${getThemeName(themeMode)})"),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        initialValue: themeMode,
                        onSelected: (m) =>
                            ref.read(themeModeProvider.notifier).setThemeMode(m),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'.tr(context)),
                          ),
                          PopupMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'.tr(context)),
                          ),
                          PopupMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'.tr(context)),
                          ),
                        ],
                      ),

                      const SizedBox(width: 8),
                      PopupMenuButton<AppLocaleMode>(
                        tooltip: 'Language'.tr(context),
                        padding: EdgeInsets.zero,
                        position: PopupMenuPosition.under,
                        icon: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            disabledForegroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          onPressed: null,
                          icon: const Icon(Icons.language),
                          label: Row(
                            children: [
                              Text("${'Language'.tr(context)} (${getLocaleName(localeMode)})"),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        initialValue: localeMode,
                        onSelected: (m) =>
                            ref.read(localeModeProvider.notifier).setMode(m),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: AppLocaleMode.system,
                            child: Text('System'.tr(context)),
                          ),
                          PopupMenuItem(
                            value: AppLocaleMode.en,
                            child: Text('English'.tr(context)),
                          ),
                          PopupMenuItem(
                            value: AppLocaleMode.ar,
                            child: Text('Arabic'.tr(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Text(
                  //   'Sign in'.tr(context),
                  //   textAlign: TextAlign.center,
                  //   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  //         color: Colors.grey,
                  //       ),
                  // ),
                  const SizedBox(height: 20),



                  // ── Username ──
                  TextField(
                    onChanged: notifier.setUsername,
                    enabled: !form.isLoading,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email or username'.tr(context),
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                      errorText: form.fieldError('username'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Password ──
                  TextField(
                    onChanged: notifier.setPassword,
                    enabled: !form.isLoading,
                    obscureText: form.obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (form.canSubmit) notifier.submit();
                    },
                    decoration: InputDecoration(
                      labelText: 'Password'.tr(context),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      errorText: form.fieldError('password'),
                      suffixIcon: IconButton(
                        onPressed: notifier.togglePasswordVisibility,
                        icon: Icon(
                          form.obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Submit ──
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: form.canSubmit ? () {
                        if (PWAInstall().installPromptEnabled) {
                          PWAInstall().promptInstall_();
                        }
                        notifier.submit();
                      } : null,
                      child: form.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Login'.tr(context)),
                    ),
                  ),

                  // ── General Error ──
                  if (form.error != null &&
                      form.error!.action == ErrorAction.showFieldErrors)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        form.error!.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _ThemeChoiceButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
