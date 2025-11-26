import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:insurevis/main-screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/notification_center.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:insurevis/providers/user_provider.dart';
// auth_provider not required in this screen
import 'package:insurevis/services/claims_service.dart';
import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  List<ClaimModel> _recentClaims = [];
  bool _isLoading = false;
  Timer? _refreshTimer;
  StreamSubscription<AuthState>? _authStreamSub;
  StreamSubscription<dynamic>? _claimsStreamSub;

  // Cache keys - same as in ClaimsScreen
  static const String _claimsStorageKey = 'cached_claims';
  static const String _lastSyncKey = 'claims_last_sync';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHomeClaims();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh claims when app resumes
    if (state == AppLifecycleState.resumed && SupabaseService.isSignedIn) {
      _syncWithServer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh claims when returning to this screen
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && SupabaseService.isSignedIn) {
      // Small delay to ensure navigation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && SupabaseService.isSignedIn) {
          _syncWithServer();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _authStreamSub?.cancel();
    _claimsStreamSub?.cancel();
    super.dispose();
  }

  /// Initialize home claims by loading from cache first, then syncing
  Future<void> _initializeHomeClaims() async {
    // Load from cache immediately for fast UI
    await _loadFromCache();

    // Setup auth monitoring
    _setupAuthMonitoring();

    // Sync with server if user is authenticated
    if (SupabaseService.isSignedIn) {
      _syncWithServer();
      _setupRealtimeUpdates();
    } else {
      // Show demo claims for non-authenticated users
      _loadDemoClaimsIfNeeded();
    }
  }

  /// Load claims from local cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_claimsStorageKey);

      if (cachedData != null && SupabaseService.isSignedIn) {
        final List<dynamic> jsonList = json.decode(cachedData);
        final allClaims =
            jsonList.map((json) => ClaimModel.fromJson(json)).toList();

        setState(() {
          _recentClaims =
              allClaims.take(5).toList(); // Only show 5 recent claims on home
        });

        debugPrint('Loaded ${_recentClaims.length} recent claims from cache');
      }
    } catch (e) {
      debugPrint('Error loading claims from cache: $e');
    }
  }

  /// Setup authentication state monitoring
  void _setupAuthMonitoring() {
    _authStreamSub = SupabaseService.authStateChanges.listen((state) {
      if (!mounted) return;

      if (state.event == AuthChangeEvent.signedIn) {
        // User signed in - load their real claims
        _syncWithServer();
        _setupRealtimeUpdates();
      } else if (state.event == AuthChangeEvent.signedOut) {
        // User signed out - clear real claims and show demo
        _clearAuthenticatedClaims();
        _loadDemoClaimsIfNeeded();
      }
    });
  }

  /// Clear authenticated user claims and cache
  Future<void> _clearAuthenticatedClaims() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_claimsStorageKey);
      await prefs.remove(_lastSyncKey);

      setState(() {
        _recentClaims = [];
      });

      // Cancel realtime subscription
      await _claimsStreamSub?.cancel();
      _claimsStreamSub = null;
    } catch (e) {
      debugPrint('Error clearing authenticated claims: $e');
    }
  }

  /// Sync with server and update cache
  Future<void> _syncWithServer() async {
    if (!SupabaseService.isSignedIn) return;

    try {
      setState(() => _isLoading = true);

      final user = SupabaseService.currentUser!;
      final allClaims = await ClaimsService.getUserClaims(user.id);

      // Save to cache
      await _saveToCache(allClaims);

      setState(() {
        _recentClaims = allClaims.take(5).toList();
        _isLoading = false;
      });

      debugPrint(
        'Synced ${allClaims.length} claims, showing ${_recentClaims.length} recent',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error syncing claims: $e');
    }
  }

  /// Save claims to local cache
  Future<void> _saveToCache(List<ClaimModel> claims) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = claims.map((claim) => claim.toJson()).toList();
      await prefs.setString(_claimsStorageKey, json.encode(jsonList));
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving claims to cache: $e');
    }
  }

  /// Setup real-time updates for authenticated users
  void _setupRealtimeUpdates() {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      // Cancel existing subscription
      _claimsStreamSub?.cancel();

      // Setup new subscription
      _claimsStreamSub = Supabase.instance.client
          .from('claims')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .listen((event) {
            if (!mounted) return;
            _handleRealtimeUpdate(event);
          });

      debugPrint('Real-time updates enabled for home claims');
    } catch (e) {
      debugPrint('Error setting up realtime updates: $e');
    }
  }

  /// Handle real-time updates
  void _handleRealtimeUpdate(List<Map<String, dynamic>> data) {
    try {
      final updatedClaims =
          data.map((json) => ClaimModel.fromJson(json)).toList();

      // Save to cache
      _saveToCache(updatedClaims);

      setState(() {
        _recentClaims = updatedClaims.take(5).toList();
      });

      debugPrint('Real-time update: ${_recentClaims.length} recent claims');
    } catch (e) {
      debugPrint('Error handling real-time update: $e');
    }
  }

  /// Load demo claims for non-authenticated users
  void _loadDemoClaimsIfNeeded() {
    if (SupabaseService.isSignedIn) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final demoUser = userProvider.currentUser;

      if (demoUser != null) {
        final demoClaims = _generateDemoClaims(demoUser);
        setState(() {
          _recentClaims = demoClaims.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading demo claims: $e');
    }
  }

  // Generate a small set of demo ClaimModel instances for a local/demo user
  List<ClaimModel> _generateDemoClaims(dynamic demoUser) {
    final now = DateTime.now();

    return [
      ClaimModel(
        id: 'demo-claim-1',
        userId: demoUser.id ?? 'demo_user',
        claimNumber: 'CLM-DEMO-001',
        incidentDate: now.subtract(const Duration(days: 3)),
        incidentLocation: 'Demo City',
        incidentDescription: 'Minor bumper scratch in demo',
        vehicleMake: 'DemoMake',
        vehicleModel: 'DemoModel',
        vehicleYear: 2018,
        vehiclePlateNumber: 'DEMO-001',
        estimatedDamageCost: 1200.0,
        status: 'draft',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      ClaimModel(
        id: 'demo-claim-2',
        userId: demoUser.id ?? 'demo_user',
        claimNumber: 'CLM-DEMO-002',
        incidentDate: now.subtract(const Duration(days: 10)),
        incidentLocation: 'Demo District',
        incidentDescription: 'Windshield chip (demo)',
        vehicleMake: 'DemoMake',
        vehicleModel: 'DemoModel',
        vehicleYear: 2020,
        vehiclePlateNumber: 'DEMO-002',
        estimatedDamageCost: 4500.0,
        status: 'submitted',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 9)),
      ),
      ClaimModel(
        id: 'demo-claim-3',
        userId: demoUser.id ?? 'demo_user',
        claimNumber: 'CLM-DEMO-003',
        incidentDate: now.subtract(const Duration(days: 30)),
        incidentLocation: 'Demo Suburb',
        incidentDescription: 'Demo rear-end collision, small',
        vehicleMake: 'DemoMake',
        vehicleModel: 'DemoModel',
        vehicleYear: 2016,
        vehiclePlateNumber: 'DEMO-003',
        estimatedDamageCost: 15200.0,
        status: 'approved',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            text: "Insure",
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 30.sp,
              fontWeight: FontWeight.w900,
            ),
            children: <TextSpan>[
              TextSpan(
                text: "Vis",
                style: GoogleFonts.inter(
                  color: GlobalStyles.primaryColor,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Material notification button with badge
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationCenter(),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    color: Color(0xFF2A2A2A),
                    size: 28.sp,
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 5.w),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: Icon(
              Icons.settings_rounded,
              color: Color(0xFF2A2A2A),
              size: 28.sp,
            ),
          ),
          SizedBox(width: 14.w),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Material feature card
                _buildActionButton(
                  icon: Icons.photo_rounded,
                  label: "Scan Image",
                  iconColor: GlobalStyles.primaryColor,
                  onPressed: () {
                    Navigator.pushNamed(context, '/gallery');
                  },
                ),
                SizedBox(width: 15.w),
                // _buildActionButton(
                //   icon: Icons.description_rounded,
                //   label: "File Claim",
                //   iconColor: Colors.green,
                //   onPressed: () {
                //     Navigator.pushNamed(context, '/claim_create');
                //   },
                // ),
                // SizedBox(width: 15.w),
                _buildActionButton(
                  icon: Icons.assessment,
                  label: "Make Assessment",
                  iconColor: Colors.green,
                  onPressed: () {
                    Navigator.pushNamed(context, '/vehicle_info');
                  },
                ),
                SizedBox(width: 15.w),
                _buildActionButton(
                  icon: Icons.question_answer_rounded,
                  label: "View FAQs",
                  iconColor: Colors.orange,
                  onPressed: () {
                    Navigator.pushNamed(context, '/faq');
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Container(height: 7.h, color: Color(0x18444444)),
          SizedBox(height: 15.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Claims",
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Add a "View All" button that navigates to the claims screen
                  ],
                ),
                SizedBox(height: 12.h),

                // Claims loading and display
                if (_isLoading && _recentClaims.isEmpty) ...[
                  SizedBox(
                    height: 60.h,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: GlobalStyles.primaryColor,
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                ] else if (_recentClaims.isEmpty) ...[
                  // Empty state
                  if (!SupabaseService.isSignedIn) ...[
                    // Sign-in CTA for non-authenticated users
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: GlobalStyles.primaryColor.withValues(
                          alpha: 0.05,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: GlobalStyles.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 48.sp,
                            color: GlobalStyles.primaryColor,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Sign in to view your claims',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Access your insurance claims and track their status',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signin');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalStyles.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // No claims for authenticated user
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 48.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'No claims yet',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Your insurance claims will appear here',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // Display recent claims
                  Column(
                    children: [
                      for (var i = 0; i < _recentClaims.length; i++) ...[
                        _buildClaimTile(_recentClaims[i]),
                        if (i < _recentClaims.length - 1) SizedBox(height: 4.h),
                      ],
                    ],
                  ),
                ],

                // Cache indicator for authenticated users (optional)
                if (SupabaseService.isSignedIn &&
                    _recentClaims.isNotEmpty &&
                    !_isLoading) ...[
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.offline_bolt,
                        size: 12.sp,
                        color: Colors.green[600],
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Synced with cache',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.orange;
      case 'under review':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.upload_rounded;
      case 'under review':
        return Icons.search_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatStatus(String status) {
    if (status.trim().isEmpty) return '';
    final parts = status.replaceAll('_', ' ').split(' ');
    final capitalized = parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
    return capitalized;
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '-';
    try {
      final f = NumberFormat.currency(
        locale: 'en_PH',
        symbol: '₱',
        decimalDigits: 2,
      );
      return f.format(amount);
    } catch (_) {
      return '₱${amount.toStringAsFixed(2)}';
    }
  }

  Widget _buildClaimIcon(String status, Color color) {
    return Container(
      height: 45.sp,
      width: 45.sp,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(_statusIcon(status), color: color, size: 22.sp),
    );
  }

  Widget _buildClaimTile(ClaimModel claim) {
    // Static claim tile without gesture detector
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          _buildClaimIcon(claim.status, _statusColor(claim.status)),
          SizedBox(width: 12.w),
          // Details column takes remaining width
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        claim.claimNumber,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _formatCurrency(claim.estimatedDamageCost),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: GlobalStyles.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatStatus(claim.status),
                      style: GoogleFonts.inter(
                        color: _statusColor(claim.status),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(claim.createdAt),
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        _ActionButtonWidget(
          icon: icon,
          iconColor: iconColor,
          onPressed: onPressed,
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Color(0xFF2A2A2A),
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Private stateful widget for the animated action button
class _ActionButtonWidget extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _ActionButtonWidget({
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  State<_ActionButtonWidget> createState() => _ActionButtonWidgetState();
}

class _ActionButtonWidgetState extends State<_ActionButtonWidget>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox(
          height: 60.sp,
          width: 60.sp,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.expand(),
              ),
              if (_pressed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.expand(),
                ),
              Center(
                child: Icon(widget.icon, color: widget.iconColor, size: 30.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
