import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification messages are displayed by Android automatically when the app
  // is in the background/terminated. Data-only messages can be handled here.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'love_messages',
    'Gửi yêu thương',
    description: 'Thông báo khi người ấy gửi yêu thương.',
    importance: Importance.high,
  );

  Future<void> initialize(String uid) async {
    if (!_initialized) {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Sửa: Thêm tên tham số `settings:` cho initialize
      await _local.initialize(
        settings: const InitializationSettings(android: android),
      );

      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
      );
      _initialized = true;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await FirestoreService.instance.saveFcmToken(uid: uid, token: token);
    }

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
      FirestoreService.instance.saveFcmToken(uid: uid, token: newToken);
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Love Day ❤️';
    final body = notification?.body ?? message.data['body'] ?? 'Người ấy gửi yêu thương cho bạn.';

    // Sửa: Thêm đầy đủ tên tham số `id:`, `title:`, `body:`, `notificationDetails:` cho show
    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'love_messages',
          'Gửi yêu thương',
          channelDescription: 'Thông báo khi người ấy gửi yêu thương.',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 120, 80, 120]),
        ),
      ),
    );
    await HapticFeedback.lightImpact();
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
  }
}