import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:insurevis/models/insurevis_models.dart';

/// Utilities for managing claims cache and local storage
class ClaimsCacheUtils {
  static const String claimsStorageKey = 'cached_claims';
  static const String lastSyncKey = 'claims_last_sync';
  static const String sortPreferenceKey = 'claims_sort_preference';

  /// Load claims from local storage
  static Future<List<ClaimModel>?> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(claimsStorageKey);

      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        final claims =
            jsonList.map((json) => ClaimModel.fromJson(json)).toList();

        if (kDebugMode) print('Loaded ${claims.length} claims from cache');
        return claims;
      }
    } catch (e) {
      if (kDebugMode) print('Error loading claims from cache: $e');
    }
    return null;
  }

  /// Save claims to local storage
  static Future<void> saveToCache(List<ClaimModel> claims) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = claims.map((claim) => claim.toJson()).toList();
      await prefs.setString(claimsStorageKey, json.encode(jsonList));
      await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) print('Saved ${claims.length} claims to cache');
    } catch (e) {
      if (kDebugMode) print('Error saving claims to cache: $e');
    }
  }

  /// Load sort preference from storage
  static Future<int?> loadSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(sortPreferenceKey);
    } catch (e) {
      if (kDebugMode) print('Error loading sort preference: $e');
      return null;
    }
  }

  /// Save sort preference to storage
  static Future<void> saveSortPreference(int sortIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(sortPreferenceKey, sortIndex);
    } catch (e) {
      if (kDebugMode) print('Error saving sort preference: $e');
    }
  }

  /// Clear cache (for debugging or reset)
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(claimsStorageKey);
      await prefs.remove(lastSyncKey);

      if (kDebugMode) print('Cache cleared');
    } catch (e) {
      if (kDebugMode) print('Error clearing cache: $e');
    }
  }

  /// Get last sync timestamp
  static Future<int?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(lastSyncKey);
    } catch (e) {
      if (kDebugMode) print('Error getting last sync time: $e');
      return null;
    }
  }
}
