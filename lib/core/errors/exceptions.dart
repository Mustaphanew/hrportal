import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════
// Base
// ═══════════════════════════════════════════════════════════════════

/// Base class for all API exceptions.
///
/// Every exception carries the original [code], human-readable [message],
/// [traceId] for debugging, and optional [details] (e.g. validation errors).
class ApiException extends Equatable implements Exception {
  final String code;
  final String message;
  final String? traceId;
  final Map<String, dynamic>? details;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.traceId,
    this.details,
    this.statusCode,
  });

  /// Validation field errors, if this is a [ValidationException].
  ///
  /// Returns `{'field_name': ['Error 1', 'Error 2']}` or empty map.
  Map<String, List<String>> get fieldErrors {
    final errors = details?['errors'];
    if (errors is Map) {
      return errors.map((key, value) => MapEntry(
            key.toString(),
            (value as List).map((e) => e.toString()).toList(),
          ));
    }
    return {};
  }

  @override
  List<Object?> get props => [code, message, traceId, statusCode];

  @override
  String toString() => 'ApiException($code: $message)';
}

// ═══════════════════════════════════════════════════════════════════
// Authentication (401)
// ═══════════════════════════════════════════════════════════════════

class AuthRequiredException extends ApiException {
  const AuthRequiredException({
    super.message = 'Authentication required.',
    super.traceId,
    super.details,
  }) : super(code: 'AUTH_REQUIRED', statusCode: 401);
}

class TokenExpiredException extends ApiException {
  const TokenExpiredException({
    super.message = 'Token has expired.',
    super.traceId,
    super.details,
  }) : super(code: 'TOKEN_EXPIRED', statusCode: 401);
}

class TokenInvalidException extends ApiException {
  const TokenInvalidException({
    super.message = 'Invalid authentication token.',
    super.traceId,
    super.details,
  }) : super(code: 'TOKEN_INVALID', statusCode: 401);
}

// ═══════════════════════════════════════════════════════════════════
// Authorization (403)
// ═══════════════════════════════════════════════════════════════════

class AccessDeniedException extends ApiException {
  const AccessDeniedException({
    super.message = 'Access denied.',
    super.traceId,
    super.details,
  }) : super(code: 'ACCESS_DENIED', statusCode: 403);
}

class InsufficientPermissionsException extends ApiException {
  const InsufficientPermissionsException({
    super.message = 'Insufficient permissions.',
    super.traceId,
    super.details,
  }) : super(code: 'INSUFFICIENT_PERMISSIONS', statusCode: 403);
}

// ═══════════════════════════════════════════════════════════════════
// Validation (422)
// ═══════════════════════════════════════════════════════════════════

class ValidationException extends ApiException {
  const ValidationException({
    super.message = 'The given data was invalid.',
    super.traceId,
    super.details,
  }) : super(code: 'VALIDATION_FAILED', statusCode: 422);
}

class BusinessRuleException extends ApiException {
  const BusinessRuleException({
    super.message = 'Business rule violation.',
    super.traceId,
    super.details,
  }) : super(code: 'BUSINESS_RULE_VIOLATION', statusCode: 422);
}

// ═══════════════════════════════════════════════════════════════════
// Resource (404)
// ═══════════════════════════════════════════════════════════════════

class ResourceNotFoundException extends ApiException {
  const ResourceNotFoundException({
    super.message = 'The requested resource was not found.',
    super.traceId,
    super.details,
  }) : super(code: 'RESOURCE_NOT_FOUND', statusCode: 404);
}

// ═══════════════════════════════════════════════════════════════════
// Conflict (409)
// ═══════════════════════════════════════════════════════════════════

class ResourceConflictException extends ApiException {
  const ResourceConflictException({
    super.message = 'Resource conflict.',
    super.traceId,
    super.details,
  }) : super(code: 'RESOURCE_CONFLICT', statusCode: 409);
}

// ═══════════════════════════════════════════════════════════════════
// Rate Limit (429)
// ═══════════════════════════════════════════════════════════════════

class RateLimitedException extends ApiException {
  const RateLimitedException({
    super.message = 'Too many requests. Please try again later.',
    super.traceId,
    super.details,
  }) : super(code: 'RATE_LIMITED', statusCode: 429);
}

// ═══════════════════════════════════════════════════════════════════
// Server (500 / 503)
// ═══════════════════════════════════════════════════════════════════

class ServerException extends ApiException {
  const ServerException({
    super.message = 'An internal error occurred.',
    super.traceId,
    super.details,
  }) : super(code: 'SERVER_ERROR', statusCode: 500);
}

class ServiceUnavailableException extends ApiException {
  const ServiceUnavailableException({
    super.message = 'Service temporarily unavailable.',
    super.traceId,
    super.details,
  }) : super(code: 'SERVICE_UNAVAILABLE', statusCode: 503);
}

// ═══════════════════════════════════════════════════════════════════
// Network (client-side — no API code)
// ═══════════════════════════════════════════════════════════════════

class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'No internet connection.',
  }) : super(code: 'NETWORK_ERROR', statusCode: null);
}

class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'Connection timed out.',
  }) : super(code: 'TIMEOUT', statusCode: null);
}
