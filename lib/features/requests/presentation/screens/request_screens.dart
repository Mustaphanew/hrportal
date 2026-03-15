import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';
import 'package:hr_portal/core/theme/app_spacing.dart';
import 'package:hr_portal/shared/widgets/app_components.dart';

import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/controllers/global_error_handler.dart';
import '../../data/models/request_models.dart';
import '../providers/request_providers.dart';

// ═══════════════════════════════════════════════════════════════════
// Requests List Screen
// ═══════════════════════════════════════════════════════════════════

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Requests'.tr(context))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/requests/create'),
        icon: const Icon(Icons.add),
        label: Text('New request'.tr(context)),
      ),
      body: PaginatedListView<EmployeeRequest>(
        state: ref.watch(requestsListProvider),
        onRefresh: () =>
            ref.read(requestsListProvider.notifier).refresh(),
        onLoadMore: () =>
            ref.read(requestsListProvider.notifier).loadMore(),
        emptyIcon: Icons.description,
        emptyTitle: 'No requests'.tr(context),
        emptySubtitle: 'Tap + to create a new request'.tr(context),
        itemBuilder: (context, request) => _RequestTile(request: request),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final EmployeeRequest request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      'approved' || 'completed' => Colors.green,
      'rejected' => Colors.red,
      'pending' || 'processing' => Colors.orange,
      'cancelled' => Colors.grey,
      _ => Colors.grey,
    };

    final statusLabel = switch (request.status) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      'pending' => 'Pending',
      'processing' => 'Processing',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => request.status,
    };

    final typeLabel = switch (request.requestType) {
      'salary_certificate' => 'Salary certificate',
      'experience_letter' => 'Experience letter',
      'vacation_settlement' => 'Vacation settlement',
      'loan_request' => 'Loan request',
      'expense_claim' => 'Expense claim',
      'training_request' => 'Training request',
      'other' => 'Other',
      _ => request.requestType ?? 'Request',
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.description, color: statusColor),
        ),
        title: Text(
          request.subject ?? typeLabel.tr(context),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          '${typeLabel.tr(context)}  •  ${request.createdAt.substring(0, 10)}',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Chip(
            label: Text(
              statusLabel.tr(context),
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
            side: BorderSide(color: statusColor),
            backgroundColor: statusColor.withOpacity(0.1),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Create Request Screen
// ═══════════════════════════════════════════════════════════════════

class CreateRequestScreen extends ConsumerWidget {
  const CreateRequestScreen({super.key});

  static const _types = [
    ('salary_certificate', 'Salary certificate'),
    ('experience_letter', 'Experience letter'),
    ('vacation_settlement', 'Vacation settlement'),
    ('loan_request', 'Loan request'),
    ('expense_claim', 'Expense claim'),
    ('training_request', 'Training request'),
    ('other', 'Other'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(createRequestFormProvider);
    final notifier = ref.read(createRequestFormProvider.notifier);

    ref.listen<CreateRequestFormState>(createRequestFormProvider, (prev, next) {
      if (next.isSuccess && prev?.isSuccess != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request submitted successfully'.tr(context)),
          ),
        );
        context.pop();
      }
      if (next.error != null &&
          prev?.error != next.error &&
          next.error!.action != ErrorAction.showFieldErrors) {
        GlobalErrorHandler.show(context, next.error!);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('New request'.tr(context))),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAllMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Type ──
            DropdownButtonFormField<String>(
              value: form.requestType.isEmpty ? null : form.requestType,
              decoration: InputDecoration(
                labelText: 'Request type *'.tr(context),
                errorText: form.fieldError('request_type'),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(
                        value: t.$1,
                        child: Text(t.$2.tr(context)),
                      ))
                  .toList(),
              onChanged: form.isLoading
                  ? null
                  : (v) {
                      if (v != null) notifier.setRequestType(v);
                    },
            ),
            AppSpacing.verticalMd,

            // ── Subject ──
            TextField(
              onChanged: notifier.setSubject,
              enabled: !form.isLoading,
              decoration: InputDecoration(
                labelText: 'Subject *'.tr(context),
                errorText: form.fieldError('subject'),
              ),
            ),
            AppSpacing.verticalMd,

            // ── Description ──
            TextField(
              onChanged: notifier.setDescription,
              enabled: !form.isLoading,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Details (optional)'.tr(context),
                errorText: form.fieldError('description'),
              ),
            ),
            AppSpacing.verticalLg,

            // ── Submit ──
            SizedBox(
              height: 48,
              child: AppLoadingButton(
                isLoading: form.isLoading,
                enabled: form.canSubmit,
                onPressed: notifier.submit,
                label: 'Submit'.tr(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
