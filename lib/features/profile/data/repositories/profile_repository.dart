import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/employee_profile_model.dart';

/// Repository for employee profile endpoints.
///
/// Endpoints:
/// - GET  /employee/profile
/// - PUT  /employee/profile (optional update)
class ProfileRepository {
  final ApiClient _client;

  ProfileRepository({required ApiClient client}) : _client = client;

  Future<EmployeeProfile> getProfile() async {
    final response = await _client.get<EmployeeProfile>(
      ApiConstants.profile,
      fromJson: (json) => EmployeeProfile.fromJson(
        json as Map<String, dynamic>,
      ),
    );
    return response.data!;
  }

  /// Update profile fields.
  ///
  /// The contract may allow partial updates. Provide fields in [data].
  Future<EmployeeProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.put<EmployeeProfile>(
      ApiConstants.profile,
      data: data,
      fromJson: (json) => EmployeeProfile.fromJson(
        json as Map<String, dynamic>,
      ),
    );
    return response.data!;
  }
}
