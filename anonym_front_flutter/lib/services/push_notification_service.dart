import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Keep background handler best effort if Firebase is not configured yet.
  }
}

class PushNotificationService {
  PushNotificationService(this._messaging);

  final FirebaseMessaging? _messaging;
  bool _isInitialized = false;

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Stream<String> get onTokenRefresh =>
      _messaging?.onTokenRefresh ?? const Stream<String>.empty();
  Stream<RemoteMessage> get onMessage => _isSupportedPlatform
      ? FirebaseMessaging.onMessage
      : const Stream<RemoteMessage>.empty();
  Stream<RemoteMessage> get onMessageOpenedApp => _isSupportedPlatform
      ? FirebaseMessaging.onMessageOpenedApp
      : const Stream<RemoteMessage>.empty();

  static Future<void> initializeFirebase() async {
    if (!_isSupportedPlatform) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {
      // Firebase config files may not be present in local/dev env yet.
    }
  }

  Future<bool> initializeForDevice() async {
    if (!_isSupportedPlatform || _messaging == null) return false;
    if (_isInitialized) return true;
    try {
      await _messaging.setAutoInitEnabled(true);
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = settings.authorizationStatus;
      final isAuthorized =
          status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
      if (!isAuthorized) {
        return false;
      }
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _isInitialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getToken() async {
    if (!_isSupportedPlatform || _messaging == null) return null;
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<RemoteMessage?> getInitialMessage() async {
    if (!_isSupportedPlatform || _messaging == null) return null;
    try {
      return await _messaging.getInitialMessage();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    if (!_isSupportedPlatform || _messaging == null) return;
    try {
      await _messaging.deleteToken();
    } catch (_) {
      // Ignore cleanup failures.
    }
  }
}
