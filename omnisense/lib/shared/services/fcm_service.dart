// lib/shared/services/fcm_service.dart
import 'dart:ui' show Color;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── Background Handler ────────────────────────────────────────────────────────
// Must be a top-level function (not a class method) per FCM requirements.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in the isolate by the FCM plugin.
  final data   = message.data;
  final status = data['status'] as String? ?? '';

  if (status == 'Unknown_Entity') {
    final localNotifications = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await localNotifications.initialize(
      const InitializationSettings(android: androidInit),
    );

    await localNotifications.show(
      message.hashCode,
      '⚠ SECURITY BREACH DETECTED',
      'Unknown entity attempted access. '
      'Name: ${data['name'] ?? 'N/A'}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'omnisense_alerts',
          'Security Alerts',
          channelDescription: 'High-priority security breach notifications',
          importance:      Importance.max,
          priority:        Priority.high,
          playSound:       true,
          enableVibration: true,
          color:           Color(0xFFDC143C),
          icon:            '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

/// Service managing Firebase Cloud Messaging initialization and handlers.
class FcmService {
  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications;

  FcmService()
      : _fcm               = FirebaseMessaging.instance,
        _localNotifications = FlutterLocalNotificationsPlugin();

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Request notification permissions
    await _fcm.requestPermission(
      alert:    true,
      badge:    true,
      sound:    true,
      criticalAlert: false,
    );

    // Initialize local notifications plugin (Android)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create the high-priority notification channel
    const channel = AndroidNotificationChannel(
      'omnisense_alerts',
      'Security Alerts',
      description:    'High-priority security breach notifications',
      importance:     Importance.max,
      playSound:      true,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Register background handler (must be top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Subscribe to security alerts FCM topic
    await _fcm.subscribeToTopic('security_alerts');

    // Log the device FCM token for debugging / server config
    final token = await _fcm.getToken();
    // ignore: avoid_print
    print('[FCM] Device token: $token');
  }

  // ── Foreground Message Handler ────────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data   = message.data;
    final status = data['status'] as String? ?? '';

    if (status == 'Unknown_Entity') {
      await _showAlert(
        id:    message.hashCode,
        title: '⚠ SECURITY BREACH — LIVE',
        body:  'Unknown entity detected! Name: ${data['name'] ?? 'N/A'}',
      );
    }
  }

  // ── Show Local Notification ────────────────────────────────────────────────

  Future<void> _showAlert({
    required int    id,
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'omnisense_alerts',
          'Security Alerts',
          channelDescription: 'High-priority security breach notifications',
          importance:      Importance.max,
          priority:        Priority.high,
          playSound:       true,
          enableVibration: true,
          color:           Color(0xFFDC143C),
          icon:            '@mipmap/ic_launcher',
          ticker:          'Security Alert',
        ),
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigate to dashboard when notification is tapped.
    // Implement using a global navigator key or a deep-link handler.
  }
}
