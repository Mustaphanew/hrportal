import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/payroll_models.dart';

/// Repository for payroll endpoints.
///
/// Endpoints:
/// - GET /payroll
/// - GET /payroll/{month}
class PayrollRepository {
  final ApiClient _client;

  PayrollRepository({required ApiClient client}) : _client = client;

  Future<PayrollData> getPayslips({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get<PayrollData>(
      ApiConstants.payroll,
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
      fromJson: (json) => PayrollData.fromJson(
        json as Map<String, dynamic>,
      ),
    );
    return response.data!;
  }

  Future<Payslip> getPayslipDetail(String month) async {
    final response = await _client.get<Payslip>(
      ApiConstants.payslipDetail(month),
      fromJson: (json) => Payslip.fromJson(
        json as Map<String, dynamic>,
      ),
    );
    return response.data!;
  }
}
