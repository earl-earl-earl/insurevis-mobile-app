import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum NotificationType { assessment, document, system, reminder }

enum NotificationPriority { low, medium, high, urgent }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    DateTime? timestamp,
    this.isRead = false,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now();

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.index,
      'priority': priority.index,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values[json['type']],
      priority: NotificationPriority.values[json['priority']],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      data:
          json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final List<AppNotification> _notifications = [];
  bool _notificationsEnabled = true;
  bool _pushNotificationsEnabled = true;
  static const String _notificationsKey = 'stored_notifications';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _pushNotificationsEnabledKey =
      'push_notifications_enabled';

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;

  int getUnreadCountByType(NotificationType type) =>
      unreadNotifications.where((n) => n.type == type).length;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;

  // Badge counts for different screens
  int get statusBadgeCount => getUnreadCountByType(NotificationType.assessment);
  int get documentsBadgeCount =>
      getUnreadCountByType(NotificationType.document);
  int get historyBadgeCount => getUnreadCountByType(NotificationType.system);

  NotificationProvider() {
    _loadNotificationsFromStorage();
  }

  // Load notifications from persistent storage
  Future<void> _loadNotificationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _pushNotificationsEnabled =
          prefs.getBool(_pushNotificationsEnabledKey) ?? true;

      _notifications.clear();
      for (final notificationStr in notificationsJson) {
        try {
          final notificationMap =
              jsonDecode(notificationStr) as Map<String, dynamic>;
          final notification = AppNotification.fromJson(notificationMap);
          _notifications.add(notification);
        } catch (e) {
          // Skip corrupted notification data
          continue;
        }
      }

      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      // Handle storage errors gracefully
      debugPrint('Error loading notifications: $e');
    }
  }

  // Save notifications to persistent storage
  Future<void> _saveNotificationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          _notifications
              .map((notification) => jsonEncode(notification.toJson()))
              .toList();

      await prefs.setStringList(_notificationsKey, notificationsJson);
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
      await prefs.setBool(
        _pushNotificationsEnabledKey,
        _pushNotificationsEnabled,
      );
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
  }) {
    if (!_notificationsEnabled) return;

    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      priority: priority,
      data: data,
    );

    _notifications.insert(0, notification); // Add to beginning

    // Limit notifications to 100 to prevent memory issues
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    _saveNotificationsToStorage();
    notifyListeners();

    // Send push notification if enabled and app is in background
    _sendPushNotification(notification);
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _saveNotificationsToStorage();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _saveNotificationsToStorage();
    notifyListeners();
  }

  void markAllAsReadByType(NotificationType type) {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].type == type && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _saveNotificationsToStorage();
    notifyListeners();
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _saveNotificationsToStorage();
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _saveNotificationsToStorage();
    notifyListeners();
  }

  void clearNotificationsByType(NotificationType type) {
    _notifications.removeWhere((n) => n.type == type);
    _saveNotificationsToStorage();
    notifyListeners();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    _saveNotificationsToStorage();
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    _saveNotificationsToStorage();
    notifyListeners();
  }

  void togglePushNotifications() {
    _pushNotificationsEnabled = !_pushNotificationsEnabled;
    _saveNotificationsToStorage();
    notifyListeners();
  }

  void setPushNotificationsEnabled(bool enabled) {
    _pushNotificationsEnabled = enabled;
    _saveNotificationsToStorage();
    notifyListeners();
  }

  // Send push notification (placeholder for real push notification service)
  void _sendPushNotification(AppNotification notification) {
    if (!_pushNotificationsEnabled) return;

    // In a real app, this would integrate with Firebase Cloud Messaging or similar
    // For now, this is a placeholder that could be implemented later
    debugPrint('Push notification sent: ${notification.title}');
  }

  // Clear old notifications (older than 30 days)
  void clearOldNotifications() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    _notifications.removeWhere((n) => n.timestamp.isBefore(cutoffDate));
    _saveNotificationsToStorage();
    notifyListeners();
  }

  // Predefined notification templates
  void addAssessmentCompleted(String assessmentId) {
    addNotification(
      title: 'Assessment Complete',
      message: 'Your vehicle damage assessment is ready for review',
      type: NotificationType.assessment,
      priority: NotificationPriority.high,
      data: {'assessmentId': assessmentId},
    );
  }

  void addAssessmentStarted(String assessmentId) {
    addNotification(
      title: 'Assessment Started',
      message: 'Your image is being analyzed. This usually takes 30 seconds.',
      type: NotificationType.assessment,
      priority: NotificationPriority.medium,
      data: {'assessmentId': assessmentId},
    );
  }

  void addDocumentSubmitted(String insuranceCompany) {
    addNotification(
      title: 'Documents Submitted',
      message: 'Your documents have been sent to $insuranceCompany',
      type: NotificationType.document,
      priority: NotificationPriority.medium,
      data: {'insuranceCompany': insuranceCompany},
    );
  }

  void addDocumentRequired() {
    addNotification(
      title: 'Documents Required',
      message: 'Please submit your insurance documents to proceed',
      type: NotificationType.document,
      priority: NotificationPriority.high,
    );
  }

  void addSystemUpdate() {
    addNotification(
      title: 'App Updated',
      message: 'New features and improvements are now available',
      type: NotificationType.system,
      priority: NotificationPriority.low,
    );
  }

  void addWelcomeNotification() {
    addNotification(
      title: 'Welcome to InsureVis!',
      message: 'Start by taking a photo of your vehicle damage',
      type: NotificationType.system,
      priority: NotificationPriority.medium,
    );
  }

  // Initialize with some sample notifications for testing
  void initializeSampleNotifications() {
    addWelcomeNotification();
    addDocumentRequired();

    // Add some sample assessment notifications
    Future.delayed(const Duration(seconds: 1), () {
      addAssessmentStarted('sample_1');
    });

    Future.delayed(const Duration(seconds: 2), () {
      addAssessmentCompleted('sample_2');
    });

    // Add more variety for testing
    Future.delayed(const Duration(seconds: 3), () {
      addSystemUpdate();
    });
  }

  // Method to add test notifications for demonstration
  void addTestNotifications() {
    // Add various types of notifications for testing
    addNotification(
      title: 'Test Assessment',
      message: 'This is a test assessment notification',
      type: NotificationType.assessment,
      priority: NotificationPriority.high,
    );

    addNotification(
      title: 'Test Document',
      message: 'This is a test document notification',
      type: NotificationType.document,
      priority: NotificationPriority.medium,
    );

    addNotification(
      title: 'Test System Alert',
      message: 'This is a test system notification',
      type: NotificationType.system,
      priority: NotificationPriority.low,
    );

    addNotification(
      title: 'Urgent Reminder',
      message: 'This is an urgent test notification',
      type: NotificationType.reminder,
      priority: NotificationPriority.urgent,
    );
  }
}
