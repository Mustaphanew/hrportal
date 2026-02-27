// ⚠️ API CONTRACT v1.0.0 — Fields match §10.8 exactly.

import 'package:equatable/equatable.dart';

import '../../../../core/network/pagination.dart';

/// Employee request item.
///
/// Contract: §10.8 EmployeeRequest
class EmployeeRequest extends Equatable {
  final int id;
  final String status; // pending|approved|rejected|cancelled|draft
  final String createdAt; // Y-m-d H:i:s
  final String updatedAt; // Y-m-d H:i:s

  final String? requestType;
  final String? subject;
  final String? description;

  final String? responseNotes;
  final int? respondedBy;
  final String? respondedAt; // Y-m-d H:i:s

  const EmployeeRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.requestType,
    this.subject,
    this.description,
    this.responseNotes,
    this.respondedBy,
    this.respondedAt,
  });

  factory EmployeeRequest.fromJson(Map<String, dynamic> json) {
    return EmployeeRequest(
      id: json['id'] as int,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      requestType: json['request_type'] as String?,
      subject: json['subject'] as String?,
      description: json['description'] as String?,
      responseNotes: json['response_notes'] as String?,
      respondedBy: json['responded_by'] as int?,
      respondedAt: json['responded_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'request_type': requestType,
        'subject': subject,
        'description': description,
        'response_notes': responseNotes,
        'responded_by': respondedBy,
        'responded_at': respondedAt,
      };

  @override
  List<Object?> get props => [id];
}

/// Parsed data from GET /requests.
///
/// Contract: §8.1 — `{ requests, pagination }`
class RequestsData {
  final List<EmployeeRequest> requests;
  final Pagination pagination;

  const RequestsData({
    required this.requests,
    required this.pagination,
  });

  factory RequestsData.fromJson(Map<String, dynamic> json) {
    return RequestsData(
      requests: (json['requests'] as List)
          .map((e) => EmployeeRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}
