import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TopicService {

  static Future<void> subscribe(String topic) async {
    if (kIsWeb) {
      // firebase_messaging: Topics غير مدعومة على الويب
      // الحل: اشترك من السيرفر عبر Admin SDK باستخدام token
      log('subscribeToTopic not supported on Web');
      return;
    }

    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      log('✅ Subscribed to $topic');
    } catch (e, s) {
      log('❌ Subscribe failed: $e', stackTrace: s);
    }
  }

  static Future<void> unsubscribe(String topic) async {
    if (kIsWeb) return;

    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      log('✅ Unsubscribed from $topic');
    } catch (e, s) {
      log('❌ Unsubscribe failed: $e', stackTrace: s);
    }
  }
}
