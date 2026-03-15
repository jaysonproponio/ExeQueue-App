import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Local UI work can continue without Firebase project credentials.
  }
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> ensureInitialized() async {
    try {
      await Firebase.initializeApp();
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
    } catch (_) {
      // Firebase config is environment-specific and optional at scaffold time.
    }
  }

  static Future<void> subscribeToQueueTopic(String queueNumber) async {
    try {
      await _messaging.subscribeToTopic('queue_$queueNumber');
    } catch (_) {
      // Ignore topic subscription failures until FCM is configured.
    }
  }

  static Future<void> unsubscribeFromQueueTopic(String queueNumber) async {
    try {
      await _messaging.unsubscribeFromTopic('queue_$queueNumber');
    } catch (_) {
      // Ignore topic subscription failures until FCM is configured.
    }
  }
}
