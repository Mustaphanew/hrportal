import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/request_models.dart';

/// Repository for employee requests.
///
/// Endpoints:
/// - GET  /requests
/// - POST /requests
class RequestRepository {
  final ApiClient _client;

  RequestRepository({required ApiClient client}) : _client = client;

  Future<RequestsData> getRequests({
    int page = 1,
    int perPage = 15,
    String? status,
  }) async {
    final response = await _client.get<RequestsData>(
      ApiConstants.requests,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      fromJson: (json) => RequestsData.fromJson(
        json as Map<String, dynamic>,
      ),
    );
    return response.data!;
  }

  Future<EmployeeRequest> createRequest({
    required String requestType,
    required String subject,
    String? description,
  }) async {
    final response = await _client.post<EmployeeRequest>(
      ApiConstants.requests,
      data: {
        'request_type': requestType,
        'subject': subject,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
      fromJson: (json) => EmployeeRequest.fromJson(
        json as Map<String, dynamic>,
      ),
    );
    return response.data!;
  }
}
