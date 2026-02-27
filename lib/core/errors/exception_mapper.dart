import 'api_error_codes.dart';
import 'exceptions.dart';

/// Maps an API error envelope into a typed [ApiException].
///
/// The backend returns a machine-readable `code` plus a human `message`.
/// This mapper converts those codes into Dart exception classes that
/// the UI layer can handle deterministically.
class ExceptionMapper {
  ExceptionMapper._();

  /// Create the correct [ApiException] from an API error.
  ///
  /// [details] is passed-through (e.g. `{errors: {...}}` for validation).
  /// [statusCode] is used only for unknown codes.
  static ApiException fromResponse({
    required String code,
    required String message,
    String? traceId,
    Map<String, dynamic>? details,
    int? statusCode,
  }) {
    switch (code) {
      // ── 401 Authentication ───────────────────────────────────────
      case ApiErrorCodes.authRequired:
        return AuthRequiredException(
          message: message,
          traceId: traceId,
          details: details,
        );

      case ApiErrorCodes.tokenExpired:
        return TokenExpiredException(
          message: message,
          traceId: traceId,
          details: details,
        );

      case ApiErrorCodes.tokenInvalid:
        return TokenInvalidException(
          message: message,
          traceId: traceId,
          details: details,
        );

      // ── 403 Authorization ───────────────────────────────────────
      case ApiErrorCodes.accessDenied:
        return AccessDeniedException(
          message: message,
          traceId: traceId,
          details: details,
        );

      case ApiErrorCodes.insufficientPermissions:
        return InsufficientPermissionsException(
          message: message,
          traceId: traceId,
          details: details,
        );

      // ── 422 Validation / Business ────────────────────────────────
      case ApiErrorCodes.validationFailed:
        return ValidationException(
          message: message,
          traceId: traceId,
          details: details,
        );

      case ApiErrorCodes.businessRuleViolation:
        return BusinessRuleException(
          message: message,
          traceId: traceId,
          details: details,
        );

      // ── 404 Resource ─────────────────────────────────────────────
      case ApiErrorCodes.resourceNotFound:
        return ResourceNotFoundException(
          message: message,
          traceId: traceId,
          details: details,
        );

      // ── 409 Conflict ─────────────────────────────────────────────
      case ApiErrorCodes.resourceConflict:
        return ResourceConflictException(
          message: message,
          traceId: traceId,
          details: details,
        );

      // ── 429 Rate Limit ───────────────────────────────────────────
      case ApiErrorCodes.rateLimited:
        return RateLimitedException(
          message: message,
          traceId: traceId,
          details: details,
        );

      // ── 500 / 503 Server ─────────────────────────────────────────
      case ApiErrorCodes.serverError:
        return ServerException(
          message: message,
          traceId: traceId,
          details: details,
        );

      case ApiErrorCodes.serviceUnavailable:
        return ServiceUnavailableException(
          message: message,
          traceId: traceId,
          details: details,
        );

      // ── Unknown / future codes ───────────────────────────────────
      default:
        return ApiException(
          code: code,
          message: message,
          traceId: traceId,
          details: details,
          statusCode: statusCode,
        );
    }
  }
}
