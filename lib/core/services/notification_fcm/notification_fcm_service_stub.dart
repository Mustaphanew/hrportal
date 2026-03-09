// notification_fcm_service_stub.dart
//
// Web/unsupported platforms implementation.
// لا شيء هنا — فقط لمنع أخطاء الـ compilation عندما تبني Web.

class NotificationFCMService {
  static void registerBackgroundHandler() {
    // no-op on web
  }

  Future<void> initFCM() async {
    // no-op on web
  }

  Future<void> handleInitialMessageAfterAppReady() async {
    // no-op on web
  }
}
