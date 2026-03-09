import 'dart:async';

class NotificationsBus {
  NotificationsBus._();

  static final _c = StreamController<void>.broadcast();

  static Stream<void> get stream => _c.stream;

  static void notifyChanged() {
    if (!_c.isClosed) _c.add(null);
  }
}
