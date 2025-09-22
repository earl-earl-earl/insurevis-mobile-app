import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:insurevis/models/firebase_msg.dart';

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type.index,
    'priority': priority.index,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values[(json['type'] ?? 0) as int],
      priority: NotificationPriority.values[(json['priority'] ?? 1) as int],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
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
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _pushNotificationsEnabledKey =
      'push_notifications_enabled';

  bool _dbSyncInProgress = false;
  Timer? _pollingTimer;
  dynamic _realtimeChannel;

  // Add refresh functionality for pull-to-refresh
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  NotificationProvider() {
    _loadSettingsFromStorage();
    Future.microtask(() => _fetchNotificationsFromDatabase());

    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        if (event.event == AuthChangeEvent.signedIn) {
          _fetchNotificationsFromDatabase();
          // Fire-and-forget async start - don't block auth state listener
          unawaited(_startRealtimeChannel());
        } else if (event.event == AuthChangeEvent.signedOut) {
          _stopRealtimeChannel();
          _stopPolling();
          _clearInMemoryNotifications(); // Clear notifications on logout
        }
      });
    } catch (_) {}
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;

  /// Load only notification settings from SharedPreferences
  /// DO NOT load notifications themselves - only from database
  Future<void> _loadSettingsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _pushNotificationsEnabled =
          prefs.getBool(_pushNotificationsEnabledKey) ?? true;
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  /// Save only notification settings to SharedPreferences
  /// DO NOT save notifications themselves
  Future<void> _saveSettingsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
      await prefs.setBool(
        _pushNotificationsEnabledKey,
        _pushNotificationsEnabled,
      );
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// Clear all in-memory notifications (used on logout)
  void _clearInMemoryNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  /// Fetch notifications from database - this is the ONLY source of truth
  Future<void> _fetchNotificationsFromDatabase() async {
    if (_dbSyncInProgress) return;
    _dbSyncInProgress = true;
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        _clearInMemoryNotifications();
        return;
      }

      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);

      final rows = res as List? ?? [];

      // Clear existing in-memory notifications and rebuild from database
      _notifications.clear();

      for (final row in rows) {
        try {
          final map = Map<String, dynamic>.from(row as Map);
          final id = map['id']?.toString() ?? '';
          if (id.isEmpty) continue;

          final ts =
              map['created_at']?.toString() ?? DateTime.now().toIso8601String();
          final jsonMap = {
            'id': id,
            'title': map['title'] ?? '',
            'message': map['body'] ?? map['message'] ?? '',
            'type': 2,
            'priority':
                map['priority'] is int
                    ? map['priority']
                    : int.tryParse(map['priority']?.toString() ?? '') ?? 0,
            'timestamp': ts,
            'isRead': map['is_read'] ?? map['isRead'] ?? false,
            'data':
                map['payload'] != null
                    ? Map<String, dynamic>.from(map['payload'])
                    : null,
          };

          _notifications.add(AppNotification.fromJson(jsonMap));
        } catch (_) {
          continue;
        }
      }

      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (_notifications.length > 100)
        _notifications.removeRange(100, _notifications.length);

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications from DB: $e');
    } finally {
      _dbSyncInProgress = false;
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      await _fetchNotificationsFromDatabase();
    });
  }

  Future<void> _startRealtimeChannel() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      try {
        _realtimeChannel?.unsubscribe();
      } catch (_) {}

      final channel = Supabase.instance.client.channel('public:notifications');
      final dyn = channel as dynamic;

      try {
        // Listen for INSERT events
        dyn.on(
          'postgres_changes',
          {
            'event': 'INSERT',
            'schema': 'public',
            'table': 'notifications',
            'filter': 'user_id=eq.${user.id}',
          },
          (payload, [ref]) {
            try {
              final newRow = payload['new'];
              if (newRow == null) return;
              final map = Map<String, dynamic>.from(newRow as Map);
              final id =
                  map['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString();
              if (_notifications.any((n) => n.id == id)) return;

              final jsonMap = {
                'id': id,
                'title': map['title'] ?? '',
                'message': map['body'] ?? map['message'] ?? '',
                'type': 2,
                'priority':
                    map['priority'] is int
                        ? map['priority']
                        : int.tryParse(map['priority']?.toString() ?? '') ?? 0,
                'timestamp':
                    map['created_at']?.toString() ??
                    DateTime.now().toIso8601String(),
                'isRead': map['is_read'] ?? false,
                'data':
                    map['payload'] != null
                        ? Map<String, dynamic>.from(map['payload'])
                        : null,
              };

              _notifications.insert(0, AppNotification.fromJson(jsonMap));
              notifyListeners();
            } catch (_) {}
          },
        );

        // Listen for UPDATE events
        dyn.on(
          'postgres_changes',
          {
            'event': 'UPDATE',
            'schema': 'public',
            'table': 'notifications',
            'filter': 'user_id=eq.${user.id}',
          },
          (payload, [ref]) {
            try {
              final newRow = payload['new'];
              if (newRow == null) return;
              final map = Map<String, dynamic>.from(newRow as Map);
              final id = map['id']?.toString();
              if (id == null) return;

              final index = _notifications.indexWhere((n) => n.id == id);
              if (index >= 0) {
                final jsonMap = {
                  'id': id,
                  'title': map['title'] ?? '',
                  'message': map['body'] ?? map['message'] ?? '',
                  'type': 2,
                  'priority':
                      map['priority'] is int
                          ? map['priority']
                          : int.tryParse(map['priority']?.toString() ?? '') ??
                              0,
                  'timestamp':
                      map['created_at']?.toString() ??
                      DateTime.now().toIso8601String(),
                  'isRead': map['is_read'] ?? false,
                  'data':
                      map['payload'] != null
                          ? Map<String, dynamic>.from(map['payload'])
                          : null,
                };

                _notifications[index] = AppNotification.fromJson(jsonMap);
                notifyListeners();
              }
            } catch (_) {}
          },
        );

        // Listen for DELETE events
        dyn.on(
          'postgres_changes',
          {
            'event': 'DELETE',
            'schema': 'public',
            'table': 'notifications',
            'filter': 'user_id=eq.${user.id}',
          },
          (payload, [ref]) {
            try {
              final oldRow = payload['old'];
              if (oldRow == null) return;
              final map = Map<String, dynamic>.from(oldRow as Map);
              final id = map['id']?.toString();
              if (id == null) return;

              // Remove from local notifications list
              _notifications.removeWhere((n) => n.id == id);
              notifyListeners();
            } catch (_) {}
          },
        );

        // Attempt to subscribe with retries in case of transient realtime/timeouts
        try {
          // Some realtime client implementations may throw a RealtimeSubscribeException
          // when subscribe times out. Handle that explicitly and retry a few times
          // with exponential backoff before falling back to polling.
          const int maxAttempts = 3;
          int attempt = 0;
          while (true) {
            attempt++;
            try {
              dyn.subscribe();
              _realtimeChannel = dyn;
              break;
            } catch (e) {
              // If it's a timed out subscribe, retry, otherwise rethrow to outer catch
              final errStr = e.toString();
              final isTimeout =
                  errStr.contains('timedOut') ||
                  errStr.toLowerCase().contains('timeout') ||
                  errStr.contains('RealtimeSubscribeException');

              if (!isTimeout || attempt >= maxAttempts) {
                rethrow;
              }

              // Wait with exponential backoff (in milliseconds)
              final backoffMs = 250 * (1 << (attempt - 1));
              await Future.delayed(Duration(milliseconds: backoffMs));
            }
          }
        } catch (e) {
          debugPrint('Realtime .on/subscribe not available: $e');
          _startPolling();
        }
      } catch (e) {
        debugPrint('Realtime .on/subscribe not available: $e');
        _startPolling();
      }
    } catch (e) {
      debugPrint('Realtime subscription failed, falling back to polling: $e');
      _startPolling();
    }
  }

  void _stopRealtimeChannel() {
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    } catch (_) {}
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> refreshNotifications() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    _isRefreshing = true;
    notifyListeners(); // Notify UI that refresh started

    try {
      await _fetchNotificationsFromDatabase();
      debugPrint('Notifications refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
      // You might want to show an error message to the user here
    } finally {
      _isRefreshing = false;
      notifyListeners(); // Notify UI that refresh completed
    }
  }

  /// REMOVED: addNotification method - no longer creating local notifications
  /// Use server-side edge functions to create notifications in the database

  /// Show local system notification only - DO NOT save to memory or database
  /// This is for immediate feedback only (like toast notifications)
  void showLocalSystemNotification({
    required String title,
    required String message,
  }) {
    if (!_notificationsEnabled) return;

    // Show local system tray notification only
    try {
      FirebaseMsg.showLocalNotification(title, message);
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Convenience helper to create a notification when a claim is submitted.
  /// Shows a local system tray notification immediately but does NOT save
  /// the notification to local storage or memory. The server edge function
  /// will handle creating the persistent notification in the database.
  Future<void> addClaimSubmitted(String claimId) async {
    final title = 'Claim submitted';
    final message = 'Your claim $claimId has been submitted successfully.';

    // Show immediate local/system notification only
    showLocalSystemNotification(title: title, message: message);

    // Post to edge function to create persistent notification in database
    try {
      final user = SupabaseService.currentUser;
      final payload = {
        'title': title,
        'body': message,
        'type': 'document',
        'channel': 'in_app',
        'priority': NotificationPriority.medium.index,
        'is_read': false,
        'referenceId': claimId,
        'user_id': user?.id,
        'metadata': {'source': 'client', 'client_claim_id': claimId},
        'payload': {
          'status': 'claim_success',
          'claimId': claimId,
          'submittedAt': DateTime.now().toIso8601String(),
          'source': 'mobile_app',
        },
      };

      final functionUrl =
          'https://vvnsludqdidnqpbzzgeb.supabase.co/functions/v1/send-notification';

      String? accessToken;
      try {
        final session = Supabase.instance.client.auth.currentSession;
        accessToken = session?.accessToken;
      } catch (_) {
        accessToken = null;
      }

      final headers = {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

      final resp = await http.post(
        Uri.parse(functionUrl),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint('Function POST failed: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error posting claim-submitted to function: $e');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _stopRealtimeChannel();
    super.dispose();
  }

  void markAsRead(String notificationId) {
    _markAsReadLocalAndRemote(notificationId);
  }

  Future<void> _markAsReadLocalAndRemote(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }

    // Persist the read state to the database
    try {
      await _updateNotificationInDatabase(notificationId, {'is_read': true});
    } catch (e) {
      debugPrint('Error marking notification read in DB: $e');
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead)
        _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();

    // Persist bulk read state on server
    Future(() async {
      try {
        final user = SupabaseService.currentUser;
        if (user == null) return;
        final supabase = Supabase.instance.client;
        await supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', user.id)
            .eq('is_read', false)
            .select();
      } catch (e) {
        debugPrint('Error marking all notifications read in DB: $e');
      }
    });
  }

  void removeNotification(String notificationId) {
    // Remove locally immediately for snappy UI
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();

    // Remove from server
    Future(() async {
      try {
        await _deleteNotificationFromDatabase(notificationId);
      } catch (e) {
        debugPrint('Error deleting notification from DB: $e');
      }
    });
  }

  void clearAllNotifications() {
    // Clear locally first
    _notifications.clear();
    notifyListeners();

    // Delete from server
    Future(() async {
      try {
        final user = SupabaseService.currentUser;
        final supabase = Supabase.instance.client;
        if (user != null) {
          await supabase
              .from('notifications')
              .delete()
              .eq('user_id', user.id)
              .select();
        }
      } catch (e) {
        debugPrint('Error clearing notifications on DB: $e');
      }
    });
  }

  Future<void> _updateNotificationInDatabase(
    String notificationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;
      final supabase = Supabase.instance.client;

      await supabase
          .from('notifications')
          .update(updates)
          .eq('id', notificationId)
          .select();
    } catch (e) {
      debugPrint('Update in DB failed: $e');
    }
  }

  Future<void> _deleteNotificationFromDatabase(String notificationId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;
      final supabase = Supabase.instance.client;

      await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .select();
    } catch (e) {
      debugPrint('Delete in DB failed: $e');
    }
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    _saveSettingsToStorage();
    notifyListeners();
  }

  void togglePushNotifications() {
    _pushNotificationsEnabled = !_pushNotificationsEnabled;
    _saveSettingsToStorage();
    notifyListeners();
  }

  // ignore: unused_element
  void _sendPushNotification(AppNotification notification) {
    if (!_pushNotificationsEnabled) return;
    debugPrint('Push notification sent: ${notification.title}');
  }
}
