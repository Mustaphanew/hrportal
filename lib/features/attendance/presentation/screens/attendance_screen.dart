import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';

import '../../../../shared/controllers/global_error_handler.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/attendance_models.dart';
import '../providers/attendance_providers.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for check-in/out errors and show dialog/snackbar.
    ref.listen<CheckActionState>(checkActionProvider, (prev, next) {
      final error = next.error;
      if (error != null) {
        GlobalErrorHandler.show(context, error);
        ref.read(checkActionProvider.notifier).clearError();
      }

      // Success: show a simple snackbar.
      if (next.record != null && (prev?.record?.id != next.record!.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance record updated successfully'.tr(context)),
          ),
        );
      }
    });

    final checkAction = ref.watch(checkActionProvider);

    final historyState = ref.watch(attendanceHistoryProvider);
    final historyController = ref.read(attendanceHistoryProvider.notifier);
    final summary = historyController.summary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance'.tr(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: checkAction.isLoading
                        ? null
                        : () => ref.read(checkActionProvider.notifier).checkIn(),
                    icon: const Icon(Icons.login),
                    label: Text('Check in'.tr(context)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: checkAction.isLoading
                        ? null
                        : () => ref.read(checkActionProvider.notifier).checkOut(),
                    icon: const Icon(Icons.logout),
                    label: Text('Check out'.tr(context)),
                  ),
                ),
              ],
            ),
          ),

          if (checkAction.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),

          if (summary != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SummaryCard(summary: summary),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: PaginatedListView<AttendanceRecord>(
              state: historyState,
              onRefresh: () => ref
                  .read(attendanceHistoryProvider.notifier)
                  .refresh(),
              onLoadMore: () =>
                  ref.read(attendanceHistoryProvider.notifier).loadMore(),
              itemBuilder: (context, record) => _RecordTile(record: record), emptyIcon: null, emptyTitle: '',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AttendanceSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'Present'.tr(context), value: '${summary.presentDays}'),
            _Stat(label: 'Absent'.tr(context), value: '${summary.absentDays}'),
            _Stat(label: 'Late'.tr(context), value: '${summary.lateDays}'),
            _Stat(label: 'Leave'.tr(context), value: '${summary.leaveDays}'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: style.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: style.bodySmall),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        record.status == 'present'
            ? Icons.check_circle_outline
            : Icons.remove_circle_outline,
      ),
      title: Text(record.date),
      subtitle: Text(
        '${'Status'.tr(context)}: ${record.status}'
        '${record.checkInTime != null ? ' • ${'In'.tr(context)}: ${record.checkInTime}' : ''}'
        '${record.checkOutTime != null ? ' • ${'Out'.tr(context)}: ${record.checkOutTime}' : ''}',
      ),
      trailing: record.isComplete ? const Icon(Icons.done) : null,
    );
  }
}
