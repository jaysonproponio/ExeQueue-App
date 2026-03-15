import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase remains optional for scaffold-level local runs.
  }
}

abstract class QueueNotificationDataSource {
  Future<void> initialize();

  Future<void> subscribeToQueueTopic(String queueNumber);
}

class QueueNotificationDataSourceImpl implements QueueNotificationDataSource {
  QueueNotificationDataSourceImpl({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<void> initialize() async {
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
      // Firebase credentials are environment-specific.
    }
  }

  @override
  Future<void> subscribeToQueueTopic(String queueNumber) async {
    try {
      await _messaging.subscribeToTopic('queue_$queueNumber');
    } catch (_) {
      // Topic subscription remains optional until FCM is configured.
    }
  }
}
