import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:exequeue_mobile/features/queue/domain/entities/queue_alert.dart';
import 'package:exequeue_mobile/features/queue/domain/services/queue_foreground_alert_bus.dart';

const String queueAlertChannelId = 'queue_alerts';
const String queueAlertChannelName = 'Queue Alerts';
const String queueAlertChannelDescription =
    'Alerts when there are five queues ahead.';
const String queueAlertSoundName = 'queue_alert_sound';
const String queueAlertIosDefaultSoundName = 'default';
const String queueAlertFallbackTitle = 'ExeQueue Alert';
const String queueAlertFallbackBody =
    'Your queue is approaching. Please prepare to proceed to the cashier.';

final FlutterLocalNotificationsPlugin queueLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool hasInitializedQueueLocalNotifications = false;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await ensureQueueLocalNotificationsInitialized();
    if (message.notification == null) {
      await showQueueAlertNotification(message);
    }
  } catch (_) {
    // Firebase remains optional for local runs without credentials.
  }
}

abstract class QueueNotificationDataSource {
  Future<void> initialize();

  Future<void> subscribeToQueueTopic(String queueNumber);
}

class QueueNotificationDataSourceImpl implements QueueNotificationDataSource {
  QueueNotificationDataSourceImpl({
    required QueueForegroundAlertBus foregroundAlertBus,
    FirebaseMessaging Function()? messagingFactory,
  })  : _foregroundAlertBus = foregroundAlertBus,
        _messagingFactory = messagingFactory ?? _defaultMessagingFactory;

  final QueueForegroundAlertBus _foregroundAlertBus;
  final FirebaseMessaging Function() _messagingFactory;
  bool _hasInitialized = false;

  static FirebaseMessaging _defaultMessagingFactory() {
    return FirebaseMessaging.instance;
  }

  @override
  Future<void> initialize() async {
    if (_hasInitialized) {
      return;
    }
    try {
      await Firebase.initializeApp();
      await ensureQueueLocalNotificationsInitialized();
      final FirebaseMessaging messaging = _messagingFactory();
      await messaging.setAutoInitEnabled(true);
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final QueueAlert? foregroundAlert =
            createQueueAlertFromMessage(message);
        if (foregroundAlert != null) {
          _foregroundAlertBus.dispatch(foregroundAlert);
          return;
        }

        unawaited(showQueueAlertNotification(message));
      });
      _hasInitialized = true;
    } catch (_) {
      // Firebase credentials are environment-specific.
    }
  }

  @override
  Future<void> subscribeToQueueTopic(String queueNumber) async {
    try {
      final FirebaseMessaging messaging = _messagingFactory();
      await messaging.subscribeToTopic('queue_$queueNumber');
    } catch (_) {
      // Topic subscription remains optional until FCM is configured.
    }
  }
}

Future<void> ensureQueueLocalNotificationsInitialized() async {
  if (hasInitializedQueueLocalNotifications) {
    return;
  }
  final DarwinInitializationSettings darwinInitializationSettings =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: darwinInitializationSettings,
  );
  await queueLocalNotificationsPlugin.initialize(initializationSettings);
  const AndroidNotificationChannel notificationChannel =
      AndroidNotificationChannel(
    queueAlertChannelId,
    queueAlertChannelName,
    description: queueAlertChannelDescription,
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(queueAlertSoundName),
  );
  final AndroidFlutterLocalNotificationsPlugin? androidNotifications =
      queueLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidNotifications?.createNotificationChannel(notificationChannel);
  await androidNotifications?.requestNotificationsPermission();
  hasInitializedQueueLocalNotifications = true;
}

Future<void> showQueueAlertNotification(RemoteMessage message) async {
  final String title = resolveQueueAlertTitle(message);
  final String body = resolveQueueAlertBody(message);
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    queueAlertChannelId,
    queueAlertChannelName,
    channelDescription: queueAlertChannelDescription,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound(queueAlertSoundName),
    enableVibration: true,
    ticker: 'ExeQueue queue alert',
  );
  final NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: queueAlertIosDefaultSoundName,
    ),
  );
  final int notificationId = createQueueAlertNotificationId(message);
  final String payload = jsonEncode(message.data);
  await queueLocalNotificationsPlugin.show(
    notificationId,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

String resolveQueueAlertTitle(RemoteMessage message) {
  final String titleFromNotification =
      message.notification?.title?.trim() ?? '';
  final String titleFromData = (message.data['title'] ?? '').toString().trim();
  if (titleFromNotification.isNotEmpty) {
    return titleFromNotification;
  }
  if (titleFromData.isNotEmpty) {
    return titleFromData;
  }
  return queueAlertFallbackTitle;
}

String resolveQueueAlertBody(RemoteMessage message) {
  final String bodyFromNotification = message.notification?.body?.trim() ?? '';
  final String bodyFromData = (message.data['body'] ?? '').toString().trim();
  if (bodyFromNotification.isNotEmpty) {
    return bodyFromNotification;
  }
  if (bodyFromData.isNotEmpty) {
    return bodyFromData;
  }
  return queueAlertFallbackBody;
}

int createQueueAlertNotificationId(RemoteMessage message) {
  final String queueNumber =
      (message.data['queue_number'] ?? '').toString().trim();
  if (queueNumber.isEmpty) {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }
  return queueNumber.codeUnits.fold<int>(
    0,
    (int value, int codeUnit) => value + codeUnit,
  );
}

QueueAlert? createQueueAlertFromMessage(RemoteMessage message) {
  final String type = (message.data['type'] ?? '').toString().trim();
  final String queueNumber =
      (message.data['queue_number'] ?? '').toString().trim();
  final int? distance =
      int.tryParse((message.data['distance'] ?? '').toString().trim());

  if (type.isNotEmpty && type != 'queue_alert') {
    return null;
  }

  if (distance != null && (distance < 0 || distance > 5)) {
    return null;
  }

  if (queueNumber.isEmpty && type.isEmpty) {
    return null;
  }

  return QueueAlert(
    title: resolveQueueAlertTitle(message),
    body: resolveQueueAlertBody(message),
    queueNumber: queueNumber.isEmpty ? 'Your Queue' : queueNumber,
    distance: distance,
  );
}
