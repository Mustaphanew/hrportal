import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(title: const Text('الطلبات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/requests/create'),
        icon: const Icon(Icons.add),
        label: const Text('طلب جديد'),
      ),
      body: PaginatedListView<EmployeeRequest>(
        state: ref.watch(requestsListProvider),
        onRefresh: () =>
            ref.read(requestsListProvider.notifier).refresh(),
        onLoadMore: () =>
            ref.read(requestsListProvider.notifier).loadMore(),
        emptyIcon: Icons.description,
        emptyTitle: 'لا توجد طلبات',
        emptySubtitle: 'اضغط + لإنشاء طلب جديد',
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
      'approved' => 'موافق',
      'rejected' => 'مرفوض',
      'pending' => 'معلق',
      'processing' => 'قيد المعالجة',
      'completed' => 'مكتمل',
      'cancelled' => 'ملغي',
      _ => request.status,
    };

    final typeLabel = switch (request.requestType) {
      'salary_certificate' => 'شهادة راتب',
      'experience_letter' => 'شهادة خبرة',
      'vacation_settlement' => 'تصفية إجازة',
      'loan_request' => 'طلب سلفة',
      'expense_claim' => 'مطالبة مصروفات',
      'training_request' => 'طلب تدريب',
      'other' => 'أخرى',
      _ => request.requestType ?? 'طلب',
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.description, color: statusColor),
        ),
        title: Text(request.subject ?? typeLabel),
        subtitle: Text('$typeLabel  •  ${request.createdAt.substring(0, 10)}'),
        trailing: Chip(
          label: Text(statusLabel,
              style: TextStyle(color: statusColor, fontSize: 12)),
          side: BorderSide(color: statusColor),
          backgroundColor: statusColor.withOpacity(0.1),
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
    ('salary_certificate', 'شهادة راتب'),
    ('experience_letter', 'شهادة خبرة'),
    ('vacation_settlement', 'تصفية إجازة'),
    ('loan_request', 'طلب سلفة'),
    ('expense_claim', 'مطالبة مصروفات'),
    ('training_request', 'طلب تدريب'),
    ('other', 'أخرى'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(createRequestFormProvider);
    final notifier = ref.read(createRequestFormProvider.notifier);

    ref.listen<CreateRequestFormState>(createRequestFormProvider, (prev, next) {
      if (next.isSuccess && prev?.isSuccess != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تقديم الطلب بنجاح'),
            backgroundColor: Colors.green,
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
      appBar: AppBar(title: const Text('طلب جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Type ──
            DropdownButtonFormField<String>(
              value: form.requestType.isEmpty ? null : form.requestType,
              decoration: InputDecoration(
                labelText: 'نوع الطلب *',
                border: const OutlineInputBorder(),
                errorText: form.fieldError('request_type'),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(
                        value: t.$1,
                        child: Text(t.$2),
                      ))
                  .toList(),
              onChanged: form.isLoading
                  ? null
                  : (v) {
                      if (v != null) notifier.setRequestType(v);
                    },
            ),
            const SizedBox(height: 16),

            // ── Subject ──
            TextField(
              onChanged: notifier.setSubject,
              enabled: !form.isLoading,
              decoration: InputDecoration(
                labelText: 'الموضوع *',
                border: const OutlineInputBorder(),
                errorText: form.fieldError('subject'),
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ──
            TextField(
              onChanged: notifier.setDescription,
              enabled: !form.isLoading,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'التفاصيل (اختياري)',
                border: const OutlineInputBorder(),
                errorText: form.fieldError('description'),
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
                    : const Text('تقديم'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
