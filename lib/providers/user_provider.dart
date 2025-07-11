import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { individual, business, agent }

enum MembershipType { basic, premium, enterprise }

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final UserRole role;
  final MembershipType membershipType;
  final DateTime joinDate;
  final bool isEmailVerified;
  final Map<String, dynamic> preferences;
  final UserStats stats;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    required this.role,
    required this.membershipType,
    required this.joinDate,
    this.isEmailVerified = false,
    this.preferences = const {},
    required this.stats,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    UserRole? role,
    MembershipType? membershipType,
    DateTime? joinDate,
    bool? isEmailVerified,
    Map<String, dynamic>? preferences,
    UserStats? stats,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      membershipType: membershipType ?? this.membershipType,
      joinDate: joinDate ?? this.joinDate,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'role': role.index,
      'membershipType': membershipType.index,
      'joinDate': joinDate.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'preferences': preferences,
      'stats': stats.toJson(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      role: UserRole.values[json['role']],
      membershipType: MembershipType.values[json['membershipType']],
      joinDate: DateTime.parse(json['joinDate']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      stats: UserStats.fromJson(json['stats']),
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
      totalAssessments: json['totalAssessments'] ?? 0,
      completedAssessments: json['completedAssessments'] ?? 0,
      documentsSubmitted: json['documentsSubmitted'] ?? 0,
      totalSaved: (json['totalSaved'] ?? 0.0).toDouble(),
      lastActiveDate:
          json['lastActiveDate'] != null
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
  bool get isPremiumUser =>
      _currentUser?.membershipType == MembershipType.premium ||
      _currentUser?.membershipType == MembershipType.enterprise;

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
        // Load saved user data
        _currentUser = UserProfile.fromJson(
          Map<String, dynamic>.from(
            // In a real app, you'd use json.decode here
            _getDemoUserData(),
          ),
        );
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
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phone: phone,
        profileImageUrl: profileImageUrl,
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

  // Update user preferences
  Future<void> updatePreferences(Map<String, dynamic> newPreferences) async {
    if (_currentUser == null) return;

    try {
      final updatedPreferences = Map<String, dynamic>.from(
        _currentUser!.preferences,
      );
      updatedPreferences.addAll(newPreferences);

      _currentUser = _currentUser!.copyWith(preferences: updatedPreferences);
      await _saveUserProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update preferences: $e';
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
      // In a real app, you'd use json.encode here
      await prefs.setString('user_profile', _currentUser!.toJson().toString());
    } catch (e) {
      // Handle error silently or log it
      debugPrint('Failed to save user profile: $e');
    }
  }

  Map<String, dynamic> _getDemoUserData() {
    return {
      'id': 'user_001',
      'name': 'Regine Torremoro',
      'email': 'regine@email.com',
      'phone': '+63 912 345 6789',
      'profileImageUrl': null,
      'role': UserRole.individual.index,
      'membershipType': MembershipType.premium.index,
      'joinDate':
          DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
      'isEmailVerified': true,
      'preferences': {
        'notifications': true,
        'darkMode': false,
        'language': 'en',
        'autoSync': true,
        'biometricLogin': true,
      },
      'stats': {
        'totalAssessments': 12,
        'completedAssessments': 10,
        'documentsSubmitted': 8,
        'totalSaved': 45000.0,
        'lastActiveDate': DateTime.now().toIso8601String(),
      },
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
