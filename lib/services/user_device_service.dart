// user_device_service.dart
// Service to manage FCM tokens for the signed-in user and upsert into `user_devices` table
// Assumes you use `supabase_flutter` and `firebase_messaging` packages.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDeviceService {
  final SupabaseClient supabase;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;

  UserDeviceService(this.supabase);

  /// Initialize the service: listen to auth changes and handle token lifecycle.
  Future<void> init() async {
    // If there's already a logged-in user at startup, register token now
    final user = supabase.auth.currentUser;
    if (user != null) {
      await _registerCurrentDevice(user.id);
    }

    // Listen for auth state changes
    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        await _registerCurrentDevice(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        // Consider deactivating all tokens for the signed-out user from client side
        final prevUserId = data.session?.user.id;
        if (prevUserId != null) {
          try {
            await supabase
                .from('user_devices')
                .update({'is_active': false})
                .eq('user_id', prevUserId);
          } catch (_) {}
        }
      }
    });

    // Token refresh: when FCM rotates tokens
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        await _upsertDeviceToken(currentUser.id, newToken);
      }
    });
  }

  Future<void> _registerCurrentDevice(String userId) async {
    try {
      // Request permission on iOS/macOS (no-op on Android)
      await _fcm.requestPermission();

      final token = await _fcm.getToken();
      if (token == null) return;

      await _upsertDeviceToken(userId, token);
    } catch (e) {
      // ignore errors but consider logging
    }
  }

  Future<void> _upsertDeviceToken(String userId, String fcmToken) async {
    final payload = {
      'user_id': userId,
      'fcm_token': fcmToken,
      'last_seen': DateTime.now().toUtc().toIso8601String(),
      'is_active': true,
      'metadata': {},
    };

    try {
      // Newer supabase_dart supports upsert via .upsert(payload, returning: ReturningOption.minimal) or
      // you can attempt an insert with onConflict by using .insert().upsert is available on the client
      // but the project's codebase uses .insert().select().single() in places, so we perform an insert
      // with .upsert fallback using PostgREST style: use .upsert if available.

      // Try upsert first
      await supabase.from('user_devices').upsert(payload);
    } catch (e) {
      // Fallback: try insert then update if conflict
      try {
        await supabase.from('user_devices').insert(payload);
      } catch (_) {
        // As a last resort, update existing row's last_seen/is_active
        try {
          await supabase
              .from('user_devices')
              .update({
                'last_seen': DateTime.now().toUtc().toIso8601String(),
                'is_active': true,
              })
              .match({'user_id': userId, 'fcm_token': fcmToken});
        } catch (_) {}
      }
    }
  }

  /// Deactivate a specific token for current user (e.g., on sign-out)
  Future<void> deactivateToken(String fcmToken) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('user_devices').update({'is_active': false}).match({
        'user_id': user.id,
        'fcm_token': fcmToken,
      });
    } catch (e) {
      // handle
    }
  }

  /// Deactivate all tokens for current user (use on logout if desired)
  Future<void> deactivateAllForCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase
          .from('user_devices')
          .update({'is_active': false})
          .eq('user_id', user.id);
    } catch (e) {
      // handle
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
  }
}
