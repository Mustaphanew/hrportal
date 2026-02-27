import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/controllers/global_error_handler.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);

    // Show error snackbar/dialog when error changes.
    ref.listen<LoginFormState>(loginFormProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        if (next.error!.action != ErrorAction.showFieldErrors) {
          GlobalErrorHandler.show(context, next.error!);
        }
      }
    });

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
                    'البوابة الذاتية للموظفين',
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تسجيل الدخول',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // ── Username ──
                  TextField(
                    onChanged: notifier.setUsername,
                    enabled: !form.isLoading,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني أو اسم المستخدم',
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
                      labelText: 'كلمة المرور',
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
                      onPressed: form.canSubmit ? notifier.submit : null,
                      child: form.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('دخول'),
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
