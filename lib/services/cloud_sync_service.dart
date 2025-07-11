import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CloudSyncService {
  static const String _baseUrl =
      'https://api.insurevis.com'; // Replace with actual API
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingUploadsKey = 'pending_uploads';
  static const String _userTokenKey = 'user_token';

  static CloudSyncService? _instance;
  static CloudSyncService get instance => _instance ??= CloudSyncService._();

  CloudSyncService._();

  // Sync state
  bool _isSyncing = false;
  bool _hasInternetConnection = true;
  final List<VoidCallback> _syncListeners = [];

  // Getters
  bool get isSyncing => _isSyncing;
  bool get hasInternetConnection => _hasInternetConnection;

  // Add sync state listener
  void addSyncListener(VoidCallback listener) {
    _syncListeners.add(listener);
  }

  // Remove sync state listener
  void removeSyncListener(VoidCallback listener) {
    _syncListeners.remove(listener);
  }

  // Notify listeners of sync state changes
  void _notifyListeners() {
    for (final listener in _syncListeners) {
      listener();
    }
  }

  // Initialize cloud sync service
  Future<void> initialize() async {
    await _checkInternetConnection();
    await _processPendingUploads();
  }

  // Check internet connectivity
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await http
          .get(
            Uri.parse('https://www.google.com'),
            headers: {'Connection': 'keep-alive'},
          )
          .timeout(Duration(seconds: 5));

      _hasInternetConnection = result.statusCode == 200;
      return _hasInternetConnection;
    } catch (e) {
      _hasInternetConnection = false;
      return false;
    }
  }

  // Sync assessment data to cloud
  Future<bool> syncAssessment(Map<String, dynamic> assessmentData) async {
    if (!_hasInternetConnection) {
      await _addToPendingUploads(assessmentData);
      return false;
    }

    try {
      _isSyncing = true;
      _notifyListeners();

      final token = await _getUserToken();
      if (token == null) {
        debugPrint('No user token available for cloud sync');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/assessments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(assessmentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _updateLastSyncTime();
        debugPrint('Assessment synced successfully');
        return true;
      } else {
        debugPrint('Failed to sync assessment: ${response.statusCode}');
        await _addToPendingUploads(assessmentData);
        return false;
      }
    } catch (e) {
      debugPrint('Error syncing assessment: $e');
      await _addToPendingUploads(assessmentData);
      return false;
    } finally {
      _isSyncing = false;
      _notifyListeners();
    }
  }

  // Download assessments from cloud
  Future<List<Map<String, dynamic>>> downloadAssessments() async {
    if (!_hasInternetConnection) {
      return [];
    }

    try {
      _isSyncing = true;
      _notifyListeners();

      final token = await _getUserToken();
      if (token == null) {
        debugPrint('No user token available for download');
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/assessments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _updateLastSyncTime();
        return List<Map<String, dynamic>>.from(data['assessments'] ?? []);
      } else {
        debugPrint('Failed to download assessments: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error downloading assessments: $e');
      return [];
    } finally {
      _isSyncing = false;
      _notifyListeners();
    }
  }

  // Upload image file to cloud storage
  Future<String?> uploadImage(String imagePath) async {
    if (!_hasInternetConnection) {
      return null;
    }

    try {
      final token = await _getUserToken();
      if (token == null) {
        return null;
      }

      final file = File(imagePath);
      if (!file.existsSync()) {
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/image'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        debugPrint('Failed to upload image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Download image from cloud storage
  Future<String?> downloadImage(String cloudUrl, String localPath) async {
    if (!_hasInternetConnection) {
      return null;
    }

    try {
      final response = await http.get(Uri.parse(cloudUrl));

      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        return localPath;
      } else {
        debugPrint('Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }

  // Perform full sync (upload pending, download new)
  Future<SyncResult> performFullSync() async {
    if (!await _checkInternetConnection()) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        uploadedCount: 0,
        downloadedCount: 0,
      );
    }

    try {
      _isSyncing = true;
      _notifyListeners();

      // Process pending uploads
      final uploadCount = await _processPendingUploads();

      // Download new assessments
      final cloudAssessments = await downloadAssessments();
      final downloadCount = cloudAssessments.length;

      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        uploadedCount: uploadCount,
        downloadedCount: downloadCount,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        uploadedCount: 0,
        downloadedCount: 0,
      );
    } finally {
      _isSyncing = false;
      _notifyListeners();
    }
  }

  // Add assessment to pending uploads queue
  Future<void> _addToPendingUploads(Map<String, dynamic> assessmentData) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingStr = prefs.getString(_pendingUploadsKey) ?? '[]';
    final pending = List<Map<String, dynamic>>.from(jsonDecode(pendingStr));

    // Add timestamp for tracking
    assessmentData['queued_at'] = DateTime.now().toIso8601String();
    pending.add(assessmentData);

    await prefs.setString(_pendingUploadsKey, jsonEncode(pending));
    debugPrint('Added assessment to pending uploads queue');
  }

  // Process all pending uploads
  Future<int> _processPendingUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingStr = prefs.getString(_pendingUploadsKey) ?? '[]';
    final pending = List<Map<String, dynamic>>.from(jsonDecode(pendingStr));

    if (pending.isEmpty) {
      return 0;
    }

    int successCount = 0;
    final failed = <Map<String, dynamic>>[];

    for (final assessment in pending) {
      final success = await syncAssessment(assessment);
      if (success) {
        successCount++;
      } else {
        failed.add(assessment);
      }
    }

    // Update pending uploads with only failed items
    await prefs.setString(_pendingUploadsKey, jsonEncode(failed));

    debugPrint(
      'Processed $successCount pending uploads, ${failed.length} failed',
    );
    return successCount;
  }

  // Get user authentication token
  Future<String?> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }

  // Set user authentication token
  Future<void> setUserToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTokenKey, token);
  }

  // Update last sync timestamp
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final syncStr = prefs.getString(_lastSyncKey);
    if (syncStr != null) {
      return DateTime.tryParse(syncStr);
    }
    return null;
  }

  // Get pending uploads count
  Future<int> getPendingUploadsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingStr = prefs.getString(_pendingUploadsKey) ?? '[]';
    final pending = List<Map<String, dynamic>>.from(jsonDecode(pendingStr));
    return pending.length;
  }

  // Clear all pending uploads
  Future<void> clearPendingUploads() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingUploadsKey);
  }

  // Get sync statistics
  Future<SyncStats> getSyncStats() async {
    final lastSync = await getLastSyncTime();
    final pendingCount = await getPendingUploadsCount();

    return SyncStats(
      lastSyncTime: lastSync,
      pendingUploads: pendingCount,
      hasInternetConnection: _hasInternetConnection,
      isSyncing: _isSyncing,
    );
  }

  // Force sync for specific assessment
  Future<bool> forceSyncAssessment(String assessmentId) async {
    // Implementation would depend on your specific assessment storage
    // This is a placeholder for the concept
    debugPrint('Force syncing assessment: $assessmentId');
    return true;
  }

  // Auto-sync when internet becomes available
  Future<void> enableAutoSync() async {
    // Check connection periodically and sync when available
    Timer.periodic(Duration(minutes: 5), (timer) async {
      if (await _checkInternetConnection()) {
        final pendingCount = await getPendingUploadsCount();
        if (pendingCount > 0) {
          await _processPendingUploads();
        }
      }
    });
  }
}

// Sync result data class
class SyncResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int downloadedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.uploadedCount,
    required this.downloadedCount,
  });
}

// Sync statistics data class
class SyncStats {
  final DateTime? lastSyncTime;
  final int pendingUploads;
  final bool hasInternetConnection;
  final bool isSyncing;

  SyncStats({
    required this.lastSyncTime,
    required this.pendingUploads,
    required this.hasInternetConnection,
    required this.isSyncing,
  });

  String get lastSyncText {
    if (lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String get statusText {
    if (isSyncing) return 'Syncing...';
    if (!hasInternetConnection) return 'Offline';
    if (pendingUploads > 0) return 'Pending sync';
    return 'Up to date';
  }
}
