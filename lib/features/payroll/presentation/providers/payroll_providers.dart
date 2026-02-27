import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/models/payroll_models.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../shared/controllers/paginated_controller.dart';

class PayslipListController extends PaginatedController<Payslip> {
  final Ref _ref;

  PayslipListController(this._ref) : super(_ref);

  @override
  Future<PaginatedResult<Payslip>> fetchPage(int page) async {
    final repo = _ref.read(payrollRepositoryProvider);
    final data = await repo.getPayslips(page: page, perPage: 15);
    return PaginatedResult(items: data.payslips, pagination: data.pagination);
  }
}

/// Paginated list of payslips.
final payslipListProvider =
    StateNotifierProvider<PayslipListController, PaginatedState<Payslip>>((ref) {
  final controller = PayslipListController(ref);
  // Kick off initial load.
  controller.loadInitial();
  return controller;
});

/// Payslip details by month (`YYYY-MM`).
final payslipDetailProvider = FutureProvider.family<Payslip, String>((ref, month) async {
  final repo = ref.read(payrollRepositoryProvider);
  return repo.getPayslipDetail(month);
});
