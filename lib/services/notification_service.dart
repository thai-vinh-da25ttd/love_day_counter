import 'package:firebase_messaging/firebase_messaging.dart';

import 'firestore_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize(String uid) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await FirestoreService.instance.saveFcmToken(
        uid: uid,
        token: token,
      );
    }

    _messaging.onTokenRefresh.listen((newToken) {
      FirestoreService.instance.saveFcmToken(
        uid: uid,
        token: newToken,
      );
    });
  }
}
