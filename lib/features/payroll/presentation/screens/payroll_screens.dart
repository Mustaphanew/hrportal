import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/localization/app_localizations.dart';
import 'package:hr_portal/core/theme/app_spacing.dart';
import 'package:hr_portal/shared/widgets/app_components.dart';

import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/controllers/global_error_handler.dart';
import '../../data/models/payroll_models.dart';
import '../providers/payroll_providers.dart';

// ═══════════════════════════════════════════════════════════════════
// Payroll List Screen
// ═══════════════════════════════════════════════════════════════════

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Payroll'.tr(context))),
      body: PaginatedListView<Payslip>(
        state: ref.watch(payslipListProvider),
        onRefresh: () =>
            ref.read(payslipListProvider.notifier).refresh(),
        onLoadMore: () =>
            ref.read(payslipListProvider.notifier).loadMore(),
        emptyIcon: Icons.receipt_long,
        emptyTitle: 'No payslips'.tr(context),
        itemBuilder: (context, payslip) => _PayslipTile(payslip: payslip),
      ),
    );
  }
}

class _PayslipTile extends StatelessWidget {
  final Payslip payslip;
  const _PayslipTile({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final period = payslip.periodStart != null &&
            payslip.periodStart!.length >= 7
        ? payslip.periodStart!.substring(0, 7)
        : 'Unknown'.tr(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.payments, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text('${'Period'.tr(context)} $period'),
        subtitle: Text(
          '${'Gross'.tr(context)}: ${payslip.totalGross.toStringAsFixed(2)}'
          '  •  ${'Net'.tr(context)}: ${payslip.totalNet.toStringAsFixed(2)}'
          '${payslip.currency != null ? ' ${payslip.currency}' : ''}',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (payslip.periodStart != null &&
              payslip.periodStart!.length >= 7) {
            final month = payslip.periodStart!.substring(0, 7);
            context.go('/payroll/$month');
          }
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Payslip Detail Screen
// ═══════════════════════════════════════════════════════════════════

class PayslipDetailScreen extends ConsumerWidget {
  final String month;
  const PayslipDetailScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(payslipDetailProvider(month));

    return Scaffold(
      appBar: AppBar(
        title: Text('Payslip — {month}'.tr(context, params: {'month': month})),
      ),
      body: detailAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorFullScreen(
          error: GlobalErrorHandler.handle(e),
          onRetry: () => ref.invalidate(payslipDetailProvider(month)),
        ),
        data: (payslip) => ListView(
          padding: AppSpacing.paddingAllMd,
          children: [
            // ── Summary Card ──
            Card(
              child: Padding(
                padding: AppSpacing.paddingAllMd,
                child: Column(
                  children: [
                    _Row(
                      label: 'Total gross'.tr(context),
                      value: payslip.totalGross,
                    ),
                    const Divider(),
                    _Row(
                      label: 'Deductions'.tr(context),
                      value: payslip.totalDeductions,
                    ),
                    const Divider(thickness: 2),
                    _Row(
                      label: 'Net pay'.tr(context),
                      value: payslip.totalNet,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalMd,

            // ── Lines ──
            if (payslip.lines != null && payslip.lines!.isNotEmpty) ...[
              SectionHeader(title: 'Details'.tr(context)),
              ...payslip.lines!.map((line) => ListTile(
                    title: Text(
                      line.ruleName ?? line.ruleCode ?? 'Item'.tr(context),
                    ),
                    subtitle: Text(
                      line.isEarning
                          ? 'Earning'.tr(context)
                          : 'Deduction'.tr(context),
                    ),
                    trailing: Text(
                      '${line.isEarning ? '+' : '-'}${line.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: line.isEarning ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
            ],

            // ── Meta ──
            if (payslip.paymentMethod != null || payslip.paidAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: Padding(
                    padding: AppSpacing.paddingAllMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (payslip.paymentMethod != null)
                          Text(
                            '${'Payment method'.tr(context)}: ${payslip.paymentMethod}',
                          ),
                        if (payslip.paidAt != null)
                          Text('${'Paid at'.tr(context)}: ${payslip.paidAt}'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _Row({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          Flexible(child: Text(value.toStringAsFixed(2), style: style)),
        ],
      ),
    );
  }
}
