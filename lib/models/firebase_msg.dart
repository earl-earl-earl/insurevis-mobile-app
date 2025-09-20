import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
// Note: Supabase DB insertion for received FCM messages is now handled by
// the server-side edge function. We keep local persistence here only.

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
    // When a user taps a notification and opens the app
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      print('User opened app from notification: ${message.messageId}');
      await storeRemoteMessageAsNotification(message);
      // Call in-memory callback if set
      if (onMessageOpenedCallback != null) {
        try {
          onMessageOpenedCallback!(message);
        } catch (e) {
          print('onMessageOpenedCallback error: $e');
        }
      }
    });
  }

  /// Optional callbacks that the app can set to receive RemoteMessage
  /// while the app is running. These won't be called in the background
  /// isolate, but are useful when the app is in the foreground.
  static void Function(RemoteMessage message)? onMessageCallback;
  static void Function(RemoteMessage message)? onMessageOpenedCallback;

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

  /// Show a simple local notification using the already-initialized
  /// FlutterLocalNotificationsPlugin. This is used by internal callers
  /// (for example, NotificationProvider) to display a system-tray
  /// notification without going through FCM.
  static Future<void> showLocalNotification(String title, String body) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      final platformDetails = NotificationDetails(android: androidDetails);

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        1 << 31,
      );

      await _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: null,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }
}

// Helper to get Android SDK version without adding device_info_plus as a dependency here.
// We attempt to read from Platform.environment where possible, but fall back gracefully.
// ...existing code...

// Top-level background handler required by firebase_messaging
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  await FirebaseMsg.showNotification(message);
  // Persist background message so NotificationProvider can load it
  await storeRemoteMessageAsNotification(message);
}

// Foreground handler (when app is in foreground)
Future<void> _firebaseForegroundHandler(RemoteMessage message) async {
  print('Received a foreground message: ${message.messageId}');
  await FirebaseMsg.showNotification(message);
  // Persist foreground message so it appears in the notification center
  await storeRemoteMessageAsNotification(message);
  // Call in-memory callback if set
  if (FirebaseMsg.onMessageCallback != null) {
    try {
      FirebaseMsg.onMessageCallback!(message);
    } catch (e) {
      print('onMessageCallback error: $e');
    }
  }
}

extension on RemoteMessage {
  Map<String, dynamic> toAppNotificationJson() {
    final notif = notification;
    // Default to system notification type if not specified in data
    int typeIndex = 2; // NotificationType.system
    if (data.containsKey('type')) {
      try {
        final t = data['type'];
        if (t is String) {
          switch (t.toLowerCase()) {
            case 'assessment':
              typeIndex = 0;
              break;
            case 'document':
              typeIndex = 1;
              break;
            case 'reminder':
              typeIndex = 3;
              break;
            default:
              typeIndex = 2;
          }
        } else if (t is int) {
          typeIndex = t;
        }
      } catch (_) {}
    }

    int priorityIndex = 1; // medium
    if (data.containsKey('priority')) {
      try {
        final p = data['priority'];
        if (p is String) {
          switch (p.toLowerCase()) {
            case 'low':
              priorityIndex = 0;
              break;
            case 'medium':
              priorityIndex = 1;
              break;
            case 'high':
              priorityIndex = 2;
              break;
            case 'urgent':
              priorityIndex = 3;
              break;
          }
        } else if (p is int) {
          priorityIndex = p;
        }
      } catch (_) {}
    }

    final id = messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return {
      'id': id,
      'title': notif?.title ?? data['title'] ?? '',
      'message': notif?.body ?? data['body'] ?? '',
      'type': typeIndex,
      'priority': priorityIndex,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
      'data': data.isNotEmpty ? Map<String, dynamic>.from(data) : null,
    };
  }
}

// Persist a RemoteMessage into SharedPreferences using the same format
// that NotificationProvider expects so messages appear in the app.
const String _notificationsKey = 'stored_notifications';

Future<void> storeRemoteMessageAsNotification(RemoteMessage message) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_notificationsKey) ?? [];
    final jsonMap = message.toAppNotificationJson();
    final encoded = jsonEncode(jsonMap);

    // Prepend new notification
    final updated = [encoded, ...current];

    // Trim to 100 entries
    if (updated.length > 100) {
      updated.removeRange(100, updated.length);
    }

    await prefs.setStringList(_notificationsKey, updated);
    print('Stored notification from FCM: ${jsonMap['title']}');
    // NOTE: DB persistence for FCM messages is intentionally omitted here.
    // The edge function `send-notification` will insert the notification row
    // into the database when sending the FCM message to the user's devices.
    // This avoids duplicate rows from both server and client inserts.
  } catch (e) {
    print('Error storing FCM message: $e');
  }
}
