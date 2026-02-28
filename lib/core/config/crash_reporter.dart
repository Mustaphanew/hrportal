// Platform-aware crash reporter wrapper.
//
// On Web, `dart:isolate` is not supported, so we export a web-safe
// implementation.
// On all other platforms (Android/iOS/Desktop), we use the IO version.

export 'crash_reporter_io.dart'
    if (dart.library.html) 'crash_reporter_web.dart';
