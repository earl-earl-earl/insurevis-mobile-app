import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserStats stats;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.role = 'user',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.stats,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserStats? stats,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'stats': stats.toJson(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle both local storage format and Supabase format
    Map<String, dynamic> userStats = {};

    // If the JSON contains a 'user_stats' array (Supabase format)
    if (json['user_stats'] != null && json['user_stats'] is List) {
      final statsList = json['user_stats'] as List;
      if (statsList.isNotEmpty) {
        userStats = statsList.first as Map<String, dynamic>;
      }
    }
    // If the JSON contains a 'stats' object (local format)
    else if (json['stats'] != null) {
      userStats = json['stats'] as Map<String, dynamic>;
    }

    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            json['joinDate'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ??
            json['updatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      stats:
          userStats.isNotEmpty
              ? UserStats.fromJson(userStats)
              : UserStats(
                totalAssessments: 0,
                completedAssessments: 0,
                documentsSubmitted: 0,
                totalSaved: 0.0,
                lastActiveDate: DateTime.now(),
              ),
    );
  }
}

class UserStats {
  final int totalAssessments;
  final int completedAssessments;
  final int documentsSubmitted;
  final double totalSaved;
  final DateTime lastActiveDate;

  UserStats({
    required this.totalAssessments,
    required this.completedAssessments,
    required this.documentsSubmitted,
    required this.totalSaved,
    required this.lastActiveDate,
  });

  UserStats copyWith({
    int? totalAssessments,
    int? completedAssessments,
    int? documentsSubmitted,
    double? totalSaved,
    DateTime? lastActiveDate,
  }) {
    return UserStats(
      totalAssessments: totalAssessments ?? this.totalAssessments,
      completedAssessments: completedAssessments ?? this.completedAssessments,
      documentsSubmitted: documentsSubmitted ?? this.documentsSubmitted,
      totalSaved: totalSaved ?? this.totalSaved,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAssessments': totalAssessments,
      'completedAssessments': completedAssessments,
      'documentsSubmitted': documentsSubmitted,
      'totalSaved': totalSaved,
      'lastActiveDate': lastActiveDate.toIso8601String(),
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalAssessments:
          json['total_assessments'] ?? json['totalAssessments'] ?? 0,
      completedAssessments:
          json['completed_assessments'] ?? json['completedAssessments'] ?? 0,
      documentsSubmitted:
          json['documents_submitted'] ?? json['documentsSubmitted'] ?? 0,
      totalSaved: (json['total_saved'] ?? json['totalSaved'] ?? 0.0).toDouble(),
      lastActiveDate:
          json['last_active_date'] != null
              ? DateTime.parse(json['last_active_date'])
              : json['lastActiveDate'] != null
              ? DateTime.parse(json['lastActiveDate'])
              : DateTime.now(),
    );
  }
}

class UserProvider with ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Initialize with demo user data (replace with actual auth in production)
  Future<void> initializeUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load user from SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_profile');

      if (userData != null) {
        try {
          // Parse stored JSON string into a map and restore user
          final Map<String, dynamic> parsed = json.decode(userData);
          _currentUser = UserProfile.fromJson(parsed);
        } catch (e) {
          // If parsing fails, fall back to demo data
          debugPrint('Failed to parse saved user profile, using demo: $e');
          _currentUser = UserProfile.fromJson(_getDemoUserData());
          await _saveUserProfile();
        }
      } else {
        // Initialize with demo data
        _currentUser = UserProfile.fromJson(_getDemoUserData());
        await _saveUserProfile();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize user: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize with demo user data for development/testing
  Future<void> initializeDemoUser() async {
    if (_currentUser != null)
      return; // Don't reinitialize if user already exists
    await initializeUser();
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phone: phone,
        address: address,
        updatedAt: DateTime.now(),
      );

      await _saveUserProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update profile: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user statistics
  Future<void> updateStats({
    int? totalAssessments,
    int? completedAssessments,
    int? documentsSubmitted,
    double? totalSaved,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedStats = _currentUser!.stats.copyWith(
        totalAssessments: totalAssessments,
        completedAssessments: completedAssessments,
        documentsSubmitted: documentsSubmitted,
        totalSaved: totalSaved,
        lastActiveDate: DateTime.now(),
      );

      _currentUser = _currentUser!.copyWith(stats: updatedStats);
      await _saveUserProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update stats: $e';
      notifyListeners();
    }
  }

  // Increment assessment count
  Future<void> incrementAssessments() async {
    if (_currentUser == null) return;

    await updateStats(
      totalAssessments: _currentUser!.stats.totalAssessments + 1,
    );
  }

  // Increment completed assessments
  Future<void> incrementCompletedAssessments() async {
    if (_currentUser == null) return;

    await updateStats(
      completedAssessments: _currentUser!.stats.completedAssessments + 1,
    );
  }

  // Increment documents submitted
  Future<void> incrementDocumentsSubmitted() async {
    if (_currentUser == null) return;

    await updateStats(
      documentsSubmitted: _currentUser!.stats.documentsSubmitted + 1,
    );
  }

  // Add to total saved amount
  Future<void> addToTotalSaved(double amount) async {
    if (_currentUser == null) return;

    await updateStats(totalSaved: _currentUser!.stats.totalSaved + amount);
  }

  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');

      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to logout: $e';
      notifyListeners();
    }
  }

  // Private helper methods
  Future<void> _saveUserProfile() async {
    if (_currentUser == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Persist the user profile as a JSON string
      await prefs.setString(
        'user_profile',
        json.encode(_currentUser!.toJson()),
      );
    } catch (e) {
      // Handle error silently or log it
      debugPrint('Failed to save user profile: $e');
    }
  }

  Map<String, dynamic> _getDemoUserData() {
    final now = DateTime.now();
    final joinDate = now.subtract(const Duration(days: 90));

    return {
      'id': 'user_001',
      'name': 'John Doe',
      'email': 'john.doe@email.com',
      'phone': '+63 912 345 6789',
      'address': '123 Main St, Quezon City, Philippines',
      'role': 'user',
      'is_active': true,
      'created_at': joinDate.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'stats': {
        'totalAssessments': 12,
        'completedAssessments': 10,
        'documentsSubmitted': 8,
        'totalSaved': 45000.0,
        'lastActiveDate': now.toIso8601String(),
      },
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
