import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/providers/core_providers.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
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
          padding: const EdgeInsets.all(16),
          children: [
            // ── Profile Card ──
            profileAsync.when(
              data: (profile) => _ProfileCard(
                name: profile.name,
                jobTitle: profile.jobTitle ?? '',
                department: profile.department?.name ?? '',
                initials: profile.initials,
              ),
              loading: () => const SizedBox(
                height: 100,
                child: LoadingIndicator(),
              ),
              error: (e, _) => _ErrorCard(
                error: GlobalErrorHandler.handle(e),
                onRetry: () => ref.invalidate(profileProvider),
              ),
            ),
            const SizedBox(height: 16),

            // ── Quick Actions ──
            Text('الإجراءات السريعة',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _QuickActionsGrid(),
            const SizedBox(height: 24),

            // ── Attendance Summary ──
            Text('ملخص الحضور — الشهر الحالي',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ref.watch(dashboardAttendanceProvider).when(
                  data: (summary) => _AttendanceSummaryCard(summary: summary),
                  loading: () => const SizedBox(
                    height: 80,
                    child: LoadingIndicator(),
                  ),
                  error: (e, _) => _ErrorCard(
                    error: GlobalErrorHandler.handle(e),
                    onRetry: () =>
                        ref.invalidate(dashboardAttendanceProvider),
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
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من هذا الجهاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final auth = ref.read(authRepositoryProvider);
                await auth.logout();
                ref.read(authProvider.notifier).onLogout();
              } catch (e) {
                if (context.mounted) {
                  GlobalErrorHandler.show(
                      context, GlobalErrorHandler.handle(e));
                }
              }
            },
            child: Text(
              'خروج',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private Widgets ──────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String name;
  final String jobTitle;
  final String department;
  final String initials;

  const _ProfileCard({
    required this.name,
    required this.jobTitle,
    required this.department,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(initials,
                  style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(context).textTheme.titleMedium),
                  if (jobTitle.isNotEmpty)
                    Text(jobTitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  if (department.isNotEmpty)
                    Text(department,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            )),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        _ActionTile(
          icon: Icons.fingerprint,
          label: 'الحضور',
          onTap: () => context.go('/attendance'),
        ),
        _ActionTile(
          icon: Icons.beach_access,
          label: 'الإجازات',
          onTap: () => context.go('/leaves'),
        ),
        _ActionTile(
          icon: Icons.receipt_long,
          label: 'الرواتب',
          onTap: () => context.go('/payroll'),
        ),
        _ActionTile(
          icon: Icons.description,
          label: 'الطلبات',
          onTap: () => context.go('/requests'),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryStat(label: 'حضور', value: '${summary.presentDays}'),
            _SummaryStat(label: 'غياب', value: '${summary.absentDays}'),
            _SummaryStat(label: 'تأخير', value: '${summary.lateDays}'),
            _SummaryStat(label: 'إجازة', value: '${summary.leaveDays}'),
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
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 8),
            Expanded(child: Text(error.message)),
            TextButton(onPressed: onRetry, child: const Text('إعادة')),
          ],
        ),
      ),
    );
  }
}
