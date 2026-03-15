import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/providers/core_providers.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';
import 'package:hr_portal/core/localization/locale_provider.dart';
import 'package:hr_portal/core/theme/app_spacing.dart';
import 'package:hr_portal/core/theme/theme_mode_provider.dart';
import 'package:hr_portal/features/profile/data/models/employee_profile_model.dart';
import 'package:hr_portal/shared/widgets/app_components.dart';

import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/controllers/global_error_handler.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localeMode = ref.watch(localeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'.tr(context)),
        actions: [

          PopupMenuButton<ThemeMode>(
            tooltip: 'Theme'.tr(context),
            position: PopupMenuPosition.under,
            icon: const Icon(Icons.brightness_6_outlined),
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
          PopupMenuButton<AppLocaleMode>(
            tooltip: 'Language'.tr(context),
            position: PopupMenuPosition.under,
            icon: const Icon(Icons.language),
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
          
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications'.tr(context),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout'.tr(context),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(dashboardAttendanceProvider);
        },
        child: ListView(
          padding: AppSpacing.paddingAllMd,
          children: [
            // ── Profile Card ──
            profileAsync.when(
              data: (profile) => _ProfileCard(
                profile: profile,
              ),
              loading: () =>
                  const SizedBox(height: 100, child: LoadingIndicator()),
              error: (e, _) => _ErrorCard(
                error: GlobalErrorHandler.handle(e),
                onRetry: () => ref.invalidate(profileProvider),
              ),
            ),
            AppSpacing.verticalMd,

            // ── Quick Actions ──
            SectionHeader(title: 'Quick actions'.tr(context)),
            _QuickActionsGrid(),
            AppSpacing.verticalLg,

            // ── Attendance Summary ──
            SectionHeader(title: 'Attendance summary — current month'.tr(context)),
            ref
                .watch(dashboardAttendanceProvider)
                .when(
                  data: (summary) => _AttendanceSummaryCard(summary: summary),
                  loading: () =>
                      const SizedBox(height: 80, child: LoadingIndicator()),
                  error: (e, _) => _ErrorCard(
                    error: GlobalErrorHandler.handle(e),
                    onRetry: () => ref.invalidate(dashboardAttendanceProvider),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dCtx) => AlertDialog(
        title: Text('Logout'.tr(context)),
        content: Text('Do you want to log out from this device?'.tr(context)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
            },
            child: Text('Cancel'.tr(context)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onError,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(dCtx).pop();
              try {
                final auth = ref.read(authRepositoryProvider);
                await auth.logout();
                ref.read(authProvider.notifier).onLogout();
              } catch (e) {
                if (dCtx.mounted) {
                  GlobalErrorHandler.show(
                    dCtx,
                    GlobalErrorHandler.handle(e),
                  );
                }
              }
            },
            child: Text(
              'Sign out'.tr(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private Widgets ──────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final EmployeeProfile profile;

  const _ProfileCard({
    required this.profile,
  });

  String _getGreeting(BuildContext context) {
    final now = DateTime.now();
    if (now.hour < 12) {
      return 'Good morning'.tr(context);
    } else if (now.hour < 18) {
      return 'Good afternoon'.tr(context);
    } else {
      return 'Good evening'.tr(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: Row(
          children: [
            if (profile.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CacheImg(url: profile.photoUrl!, imgWidth: 58),
              )
            else
              CircleAvatar(
                radius: 28,
                child: Text(profile.initials, style: const TextStyle(fontSize: 18)),
              ),
            AppSpacing.horizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_getGreeting(context)} 👋",
                    style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
                  ),
                  Text(
                    profile.name,
                    style: textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (profile.jobTitle != null)
                    Text(
                      profile.jobTitle!,
                      style: textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= AppBreakpoints.mobile ? 4 : 2;
        return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.5,
      children: [
        _ActionTile(
          icon: Icons.fingerprint,
          label: 'Attendance',
          onTap: () => context.go('/attendance'),
        ),
        _ActionTile(
          icon: Icons.beach_access,
          label: 'Leaves',
          onTap: () => context.go('/leaves'),
        ),
        _ActionTile(
          icon: Icons.receipt_long,
          label: 'Payroll',
          onTap: () => context.go('/payroll'),
        ),
        _ActionTile(
          icon: Icons.description,
          label: 'Requests',
          onTap: () => context.go('/requests'),
        ),
      ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              AppSpacing.horizontalMd,
              Flexible(
                child: Text(label.tr(context),
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final dynamic summary;
  const _AttendanceSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryStat(
              label: 'Present'.tr(context),
              value: '${summary.presentDays}',
            ),
            _SummaryStat(
              label: 'Absent'.tr(context),
              value: '${summary.absentDays}',
            ),
            _SummaryStat(
              label: 'Late'.tr(context),
              value: '${summary.lateDays}',
            ),
            _SummaryStat(
              label: 'Leave'.tr(context),
              value: '${summary.leaveDays}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final UiError error;
  final VoidCallback onRetry;
  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            AppSpacing.horizontalSm,
            Expanded(child: Text(error.message.tr(context))),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry'.tr(context)),
            ),
          ],
        ),
      ),
    );
  }
}
