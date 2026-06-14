import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_messaging_config.dart';

class FirebasePushService {
  FirebasePushService({
    FirebaseMessaging? messaging,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  bool _foregroundListenerStarted = false;

  Future<String?> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM PERMISSION STATUS: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: permisos denegados por el usuario.');
        return null;
      }

      _startForegroundListener();

      return getCurrentToken();
    } catch (error, stackTrace) {
      debugPrint('FCM ERROR INITIALIZING: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  Future<String?> getCurrentToken() async {
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? FirebaseMessagingConfig.webVapidKey : null,
      );

      debugPrint('FCM TOKEN: $token');

      return token;
    } catch (error, stackTrace) {
      debugPrint('FCM ERROR GETTING TOKEN: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('FCM TOKEN DELETED');
    } catch (error) {
      debugPrint('FCM ERROR DELETING TOKEN: $error');
    }
  }

  void _startForegroundListener() {
    if (_foregroundListenerStarted) {
      return;
    }

    _foregroundListenerStarted = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM FOREGROUND MESSAGE: ${message.messageId}');
      debugPrint('FCM TITLE: ${message.notification?.title}');
      debugPrint('FCM BODY: ${message.notification?.body}');
      debugPrint('FCM DATA: ${message.data}');
    });
  }
}