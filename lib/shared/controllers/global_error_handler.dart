import 'package:flutter/material.dart';

import '../../core/errors/exceptions.dart';

/// Describes what the UI should do in response to an error.
enum ErrorAction {
  /// Show inline field errors (ValidationException).
  showFieldErrors,

  /// Show a non-blocking snackbar message.
  showSnackbar,

  /// Show a blocking dialog requiring dismissal.
  showDialog,

  /// Navigate to login (session expired).
  redirectToLogin,

  /// Show a full-screen offline/error state.
  showFullScreen,
}

/// Processed error ready for UI consumption.
class UiError {
  final ErrorAction action;
  final String title;
  final String message;
  final Map<String, List<String>> fieldErrors;
  final String? traceId;

  const UiError({
    required this.action,
    required this.title,
    required this.message,
    this.fieldErrors = const {},
    this.traceId,
  });
}

/// Maps [ApiException] subtypes to [UiError] for presentation.
///
/// Usage in any provider/controller:
/// ```dart
/// } on ApiException catch (e) {
///   state = AsyncError(GlobalErrorHandler.handle(e), StackTrace.current);
/// }
/// ```
///
/// Usage in UI:
/// ```dart
/// ref.listen(someProvider, (_, next) {
///   if (next is AsyncError) {
///     final uiError = next.error as UiError;
///     GlobalErrorHandler.show(context, uiError, ref);
///   }
/// });
/// ```
class GlobalErrorHandler {
  GlobalErrorHandler._();

  /// Convert an [ApiException] into a UI-ready [UiError].
  static UiError handle(Object error) {
    if (error is ValidationException) {
      return UiError(
        action: ErrorAction.showFieldErrors,
        title: 'بيانات غير صحيحة',
        message: error.message,
        fieldErrors: error.fieldErrors,
        traceId: error.traceId,
      );
    }

    if (error is TokenExpiredException || error is TokenInvalidException) {
      return UiError(
        action: ErrorAction.redirectToLogin,
        title: 'انتهت الجلسة',
        message: 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.',
        traceId: (error as ApiException).traceId,
      );
    }

    if (error is AuthRequiredException) {
      return UiError(
        action: ErrorAction.redirectToLogin,
        title: 'غير مصادق',
        message: 'يرجى تسجيل الدخول.',
        traceId: error.traceId,
      );
    }

    if (error is AccessDeniedException ||
        error is InsufficientPermissionsException) {
      return UiError(
        action: ErrorAction.showDialog,
        title: 'غير مصرح',
        message: (error as ApiException).message,
        traceId: (error as ApiException).traceId,
      );
    }

    if (error is ResourceConflictException) {
      return UiError(
        action: ErrorAction.showSnackbar,
        title: 'تعارض',
        message: error.message,
        traceId: error.traceId,
      );
    }

    if (error is BusinessRuleException) {
      return UiError(
        action: ErrorAction.showDialog,
        title: 'غير مسموح',
        message: error.message,
        traceId: error.traceId,
      );
    }

    if (error is ResourceNotFoundException) {
      return UiError(
        action: ErrorAction.showSnackbar,
        title: 'غير موجود',
        message: error.message,
        traceId: error.traceId,
      );
    }

    if (error is RateLimitedException) {
      return UiError(
        action: ErrorAction.showSnackbar,
        title: 'طلبات كثيرة',
        message: 'يرجى الانتظار قليلاً ثم المحاولة مرة أخرى.',
        traceId: error.traceId,
      );
    }

    if (error is NetworkException) {
      return UiError(
        action: ErrorAction.showFullScreen,
        title: 'لا يوجد اتصال',
        message: 'تحقق من اتصال الإنترنت وحاول مرة أخرى.',
      );
    }

    if (error is TimeoutException) {
      return UiError(
        action: ErrorAction.showSnackbar,
        title: 'انتهت المهلة',
        message: 'الخادم بطيء. حاول مرة أخرى.',
      );
    }

    if (error is ServerException || error is ServiceUnavailableException) {
      return UiError(
        action: ErrorAction.showFullScreen,
        title: 'خطأ في الخادم',
        message: 'حدث خطأ فني. حاول لاحقاً.',
        traceId: (error as ApiException).traceId,
      );
    }

    // Unknown error fallback
    if (error is ApiException) {
      return UiError(
        action: ErrorAction.showSnackbar,
        title: 'خطأ',
        message: error.message,
        traceId: error.traceId,
      );
    }

    return UiError(
      action: ErrorAction.showSnackbar,
      title: 'خطأ غير متوقع',
      message: error.toString(),
    );
  }

  /// Present the [UiError] to the user via the appropriate mechanism.
  static void show(BuildContext context, UiError error) {
    switch (error.action) {
      case ErrorAction.showFieldErrors:
        // Field errors are handled inline by form widgets.
        // Show a summary snackbar as well.
        _showSnackbar(context, error.message, isError: true);
        break;

      case ErrorAction.showSnackbar:
        _showSnackbar(context, error.message, isError: true);
        break;

      case ErrorAction.showDialog:
        _showErrorDialog(context, error.title, error.message);
        break;

      case ErrorAction.redirectToLogin:
        // Handled by SessionManager → GoRouter redirect.
        // Show a brief message.
        _showSnackbar(context, error.message, isError: true);
        break;

      case ErrorAction.showFullScreen:
        // The screen itself should check for this state and show
        // the ErrorFullScreen widget. Snackbar as fallback.
        _showSnackbar(context, error.message, isError: true);
        break;
    }
  }

  static void _showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void _showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
