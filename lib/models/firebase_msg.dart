import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FirebaseMsg {
  final msgService = FirebaseMessaging.instance;

  // Flutter local notifications plugin
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android channel (for Android 8+)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'insurevis_notifications', // id
    'InsureVis Notifications', // title
    description: 'This channel is used for InsureVis FCM notifications.',
    importance: Importance.high,
  );

  Future<void> initFCM() async {
    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);

    // Create channel on Android
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Request permissions for iOS/macOS (firebase_messaging also requests permissions)
    await msgService.requestPermission();

    // On Android 13+ we must request POST_NOTIFICATIONS at runtime.
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        if (sdkInt >= 33) {
          final status = await Permission.notification.request();
          print('Notification permission status: $status');
        }
      } catch (e) {
        print(
          'Could not check Android SDK version for notification permission: $e',
        );
      }
    }

    var token = await msgService.getToken();
    print("Firebase Messaging Token: $token");

    // Setup background & foreground handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_firebaseForegroundHandler);
  }

  // Show a local notification (used by handlers)
  static Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;

    final title = notification?.title ?? '';
    final body = notification?.body ?? '';

    // Use non-const so we can reference runtime channel properties
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    final notificationId =
        message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    await _localNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}

// Helper to get Android SDK version without adding device_info_plus as a dependency here.
// We attempt to read from Platform.environment where possible, but fall back gracefully.
// ...existing code...

// Top-level background handler required by firebase_messaging
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  await FirebaseMsg.showNotification(message);
}

// Foreground handler (when app is in foreground)
Future<void> _firebaseForegroundHandler(RemoteMessage message) async {
  print('Received a foreground message: ${message.messageId}');
  await FirebaseMsg.showNotification(message);
}
