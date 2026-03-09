import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/features/leave/data/models/leave_models.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../../../shared/controllers/global_error_handler.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../providers/leave_providers.dart';

class CreateLeaveScreen extends ConsumerWidget {
  const CreateLeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(leavesListProvider);
    final form = ref.watch(createLeaveFormProvider);
    final notifier = ref.read(createLeaveFormProvider.notifier);

    ref.listen<CreateLeaveFormState>(createLeaveFormProvider, (prev, next) {
      if (next.isSuccess && prev?.isSuccess != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request sent successfully'.tr(context))),
        );
        context.pop();
      }

      if (next.error != null && prev?.error != next.error) {
        GlobalErrorHandler.show(context, next.error!);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('Request leave'.tr(context))),
      body: listState.isLoading
          ? const Center(child: LoadingIndicator())
          : listState.error != null
          ? ErrorFullScreen(
              error: listState.error!,
              onRetry: () => ref.read(leavesListProvider.notifier).refresh(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  value: form.leaveTypeId,
                  isExpanded: true,
                  itemHeight: null, // يسمح بسطرين إذا احتاج
                  items: listState.leaveTypes.map((t) {
                    // ابحث عن الرصيد الموافق لنوع الإجازة
                    LeaveBalance? bal;
                    try {
                      bal = listState.balances.firstWhere(
                        (b) => (b.leaveType?.id ?? 0) == (t.id ?? 0),
                      );
                    } catch (_) {
                      bal = null;
                    }

                    final nf = NumberFormat('0.0'); // يعطي 30.0 مثل الصورة
                    final availableDays = bal?.available ?? 0.0;

                    final meta = t.isPaid
                        ? '${'Available'.tr(context)}: ${nf.format(availableDays)} ${'day'.tr(context)}'
                        : 'Unpaid — no balance'.tr(context);

                    return DropdownMenuItem<int>(
                      value: t.id ?? 0,
                      child: Text(
                        '${t.name} ($meta)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) notifier.setLeaveType(v);
                  },
                  decoration: InputDecoration(
                    labelText: 'Leave type'.tr(context),
                    errorText: form.fieldError('leave_type_id'),
                  ),
                ),

                const SizedBox(height: 12),

                _DateField(
                  label: 'Start date'.tr(context),
                  value: form.startDate,
                  errorText: form.fieldError('start_date'),
                  onPick: (date) => notifier.setStartDate(date),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'End date'.tr(context),
                  value: form.endDate,
                  errorText: form.fieldError('end_date'),
                  onPick: (date) => notifier.setEndDate(date),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: form.dayPart,
                  items: [
                    DropdownMenuItem(
                      value: 'full',
                      child: Text('Full day'.tr(context)),
                    ),
                    // DropdownMenuItem(
                    //   value: 'first_half',
                    //   child: Text('النصف الأول'),
                    // ),
                    // DropdownMenuItem(
                    //   value: 'second_half',
                    //   child: Text('النصف الثاني'),
                    // ),
                  ],
                  onChanged: (v) {
                    if (v != null) notifier.setDayPart(v);
                  },
                  decoration: InputDecoration(
                    labelText: 'Duration'.tr(context),
                    errorText: form.fieldError('day_part'),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  initialValue: form.reason,
                  maxLines: 3,
                  onChanged: notifier.setReason,
                  decoration: InputDecoration(
                    labelText: 'Reason (optional)'.tr(context),
                    errorText: form.fieldError('reason'),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: form.canSubmit ? () => notifier.submit() : null,
                  child: form.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Submit request'.tr(context)),
                ),
              ],
            ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final String? errorText;
  final ValueChanged<String> onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 2),
        );

        if (picked != null) {
          final d =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onPick(d);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(value.isEmpty ? 'Select date'.tr(context) : value),
            ),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}
