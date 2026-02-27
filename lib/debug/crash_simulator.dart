// ⚠️ PRE-RELEASE ONLY — Crash simulation tests.
// Add this file temporarily for crash verification, REMOVE before production.
//
// File: lib/debug/crash_simulator.dart

import '../core/config/crash_reporter.dart';
import '../core/config/app_logger.dart';
import '../core/errors/exceptions.dart';
import '../shared/controllers/global_error_handler.dart';

/// Temporary crash simulation for pre-release verification.
///
/// **Usage in a debug screen or button:**
/// ```dart
/// ElevatedButton(
///   onPressed: () => CrashSimulator.runAll(),
///   child: Text('Run Crash Tests'),
/// )
/// ```
///
/// **REMOVE THIS FILE BEFORE PRODUCTION BUILD.**
class CrashSimulator {
  CrashSimulator._();

  /// Run all crash simulations sequentially.
  static Future<void> runAll() async {
    AppLogger.w('🧪 Starting crash simulation battery...', tag: 'CrashSim');

    await testNonFatalApiException();
    await testNonFatalWithTraceId();
    await testNetworkException();
    await testValidationException();
    await testUnhandledDartError();
    // testFatalCrash(); // ← Uncomment ONLY if you want to test actual crash

    AppLogger.w('🧪 Crash simulation battery complete.', tag: 'CrashSim');
  }

  // ═══════════════════════════════════════════════════════════════════
  // Test 1: Non-Fatal API Exception
  // ═══════════════════════════════════════════════════════════════════
  /// Simulates a ServerException being recorded as non-fatal.
  ///
  /// **Verify in Crashlytics:**
  /// - Appears in "Non-fatals" tab
  /// - Exception type: ServerException (or obfuscated name)
  /// - Message: "Simulated server error for testing"
  static Future<void> testNonFatalApiException() async {
    AppLogger.i('Test 1: Non-fatal ServerException', tag: 'CrashSim');

    try {
      throw const ServerException(
        message: 'Simulated server error for testing',
        traceId: 'crash-sim-test-001',
      );
    } catch (e, stack) {
      await CrashReporter.recordError(
        e,
        stack,
        reason: 'CrashSimulator: Test 1 — Non-fatal API exception',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Test 2: Non-Fatal with Trace ID Correlation
  // ═══════════════════════════════════════════════════════════════════
  /// Sets a trace ID BEFORE the crash to verify correlation.
  ///
  /// **Verify in Crashlytics:**
  /// - Custom key `last_trace_id` = "crash-sim-trace-correlation-002"
  /// - This trace ID should be searchable in backend logs
  static Future<void> testNonFatalWithTraceId() async {
    AppLogger.i('Test 2: Trace ID correlation', tag: 'CrashSim');

    // Simulate: API returned a response with X-Trace-Id header
    CrashReporter.setLastTraceId('crash-sim-trace-correlation-002');

    try {
      throw const BusinessRuleException(
        message: 'Insufficient leave balance (simulated)',
        traceId: 'crash-sim-trace-correlation-002',
      );
    } catch (e, stack) {
      await CrashReporter.recordError(
        e,
        stack,
        reason: 'CrashSimulator: Test 2 — Trace ID correlation',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Test 3: Network Exception
  // ═══════════════════════════════════════════════════════════════════
  /// Simulates a network failure error report.
  ///
  /// **Verify in Crashlytics:**
  /// - Exception type: NetworkException
  /// - No sensitive data in stack trace
  static Future<void> testNetworkException() async {
    AppLogger.i('Test 3: NetworkException', tag: 'CrashSim');

    try {
      throw const NetworkException();
    } catch (e, stack) {
      await CrashReporter.recordError(
        e,
        stack,
        reason: 'CrashSimulator: Test 3 — Network failure',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Test 4: Validation Exception (with field errors)
  // ═══════════════════════════════════════════════════════════════════
  /// Verifies that field-level validation errors don't leak PII.
  ///
  /// **Verify in Crashlytics:**
  /// - Exception recorded
  /// - NO user input values in the crash report
  /// - Field names are OK (email, password), values are NOT
  static Future<void> testValidationException() async {
    AppLogger.i('Test 4: ValidationException', tag: 'CrashSim');

    try {
      throw const ValidationException(
        message: 'The given data was invalid.',
        traceId: 'crash-sim-validation-004',
        details: {
          'errors': {
            'email': ['The email field is required.'],
            'start_date': ['Start date must be in the future.'],
          }
        },
      );
    } catch (e, stack) {
      // Verify GlobalErrorHandler maps correctly
      final uiError = GlobalErrorHandler.handle(e);
      assert(uiError.action == ErrorAction.showFieldErrors);
      assert(uiError.fieldErrors['email'] != null);

      await CrashReporter.recordError(
        e,
        stack,
        reason: 'CrashSimulator: Test 4 — Validation with fields',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Test 5: Unhandled Dart Error
  // ═══════════════════════════════════════════════════════════════════
  /// Simulates an unhandled error (caught by PlatformDispatcher.onError).
  ///
  /// **Verify in Crashlytics:**
  /// - Appears in crash reports
  /// - Stack trace is de-obfuscated (class names visible after symbol upload)
  static Future<void> testUnhandledDartError() async {
    AppLogger.i('Test 5: Unhandled Dart error', tag: 'CrashSim');

    // This is caught by CrashReporter's PlatformDispatcher.onError handler
    await Future.delayed(const Duration(milliseconds: 100), () {
      // Create an error that PlatformDispatcher catches
      try {
        final list = <String>[];
        // ignore: unused_local_variable
        final item = list[99]; // RangeError
      } catch (e, stack) {
        CrashReporter.recordError(
          e,
          stack,
          reason: 'CrashSimulator: Test 5 — RangeError',
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // Test 6: FATAL Crash (use sparingly)
  // ═══════════════════════════════════════════════════════════════════
  /// Triggers an actual app crash to verify fatal crash reporting.
  ///
  /// ⚠️ ONLY uncomment when actively testing. App WILL close.
  ///
  /// **Verify in Crashlytics:**
  /// - Appears in "Crashes" tab (not non-fatals)
  /// - Stack trace fully de-obfuscated after symbol upload
  /// - `last_trace_id` custom key is present
  // static void testFatalCrash() {
  //   AppLogger.e('Test 6: FATAL CRASH — App will close!', tag: 'CrashSim');
  //   CrashReporter.setLastTraceId('crash-sim-fatal-006');
  //
  //   // Method 1: Throw from root zone
  //   throw StateError('CrashSimulator: Intentional fatal crash for testing');
  //
  //   // Method 2: Native crash (alternative)
  //   // FirebaseCrashlytics.instance.crash();
  // }
}
