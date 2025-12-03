import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:insurevis/screens/main-screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/screens/other-screens/notification_center.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:insurevis/providers/user_provider.dart';
import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/utils/claims_cache_utils.dart';
import 'package:insurevis/utils/claims_handler_utils.dart';
import 'package:insurevis/utils/claims_widget_utils.dart';

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
    final cachedClaims = await ClaimsCacheUtils.loadFromCache();

    if (cachedClaims != null && SupabaseService.isSignedIn) {
      setState(() {
        _recentClaims = cachedClaims.take(5).toList();
      });

      debugPrint('Loaded ${_recentClaims.length} recent claims from cache');
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
    await ClaimsCacheUtils.clearCache();

    setState(() {
      _recentClaims = [];
    });

    await _claimsStreamSub?.cancel();
    _claimsStreamSub = null;
  }

  /// Sync with server and update cache
  Future<void> _syncWithServer() async {
    if (!SupabaseService.isSignedIn) return;

    try {
      setState(() => _isLoading = true);

      final allClaims = await ClaimsHandlerUtils.syncWithServer();

      if (allClaims != null) {
        setState(() {
          _recentClaims = allClaims.take(5).toList();
          _isLoading = false;
        });

        debugPrint(
          'Synced ${allClaims.length} claims, showing ${_recentClaims.length} recent',
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error syncing claims: $e');
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

      ClaimsCacheUtils.saveToCache(updatedClaims);

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
        final demoClaims = ClaimsHandlerUtils.generateDemoClaims(demoUser);
        setState(() {
          _recentClaims = demoClaims.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading demo claims: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            text: "Insure",
            style: TextStyle(
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeH2,
              fontWeight: GlobalStyles.fontWeightBold,
              fontFamily: GlobalStyles.fontFamilyHeading,
            ),
            children: <TextSpan>[
              TextSpan(
                text: "Vis",
                style: TextStyle(
                  color: GlobalStyles.primaryMain,
                  fontSize: GlobalStyles.fontSizeH2,
                  fontWeight: GlobalStyles.fontWeightBold,
                  fontFamily: GlobalStyles.fontFamilyHeading,
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
                    style: TextStyle(
                      fontSize: GlobalStyles.fontSizeCaption,
                      fontWeight: GlobalStyles.fontWeightBold,
                      fontFamily: GlobalStyles.fontFamilyBody,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.bell,
                    color: GlobalStyles.textPrimary,
                    size: GlobalStyles.iconSizeLg,
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: GlobalStyles.surfaceMain.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: GlobalStyles.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: GlobalStyles.spacingXs),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: Icon(
              LucideIcons.settings,
              color: GlobalStyles.textPrimary,
              size: GlobalStyles.iconSizeLg,
            ),
          ),
          SizedBox(width: GlobalStyles.paddingTight),
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
                  icon: LucideIcons.camera,
                  label: "Scan Image",
                  iconColor: GlobalStyles.primaryMain,
                  onPressed: () {
                    Navigator.pushNamed(context, '/gallery');
                  },
                ),
                SizedBox(width: GlobalStyles.paddingTight),
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
                  icon: LucideIcons.clipboardList,
                  label: "Make Assessment",
                  iconColor: GlobalStyles.accent1,
                  onPressed: () {
                    Navigator.pushNamed(context, '/vehicle_info');
                  },
                ),
                SizedBox(width: GlobalStyles.paddingTight),
                _buildActionButton(
                  icon: LucideIcons.info,
                  label: "View FAQs",
                  iconColor: GlobalStyles.accent2,
                  onPressed: () {
                    Navigator.pushNamed(context, '/faq');
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: GlobalStyles.spacingLg),
          Container(
            height: GlobalStyles.spacingSm,
            color: GlobalStyles.backgroundAlternative,
          ),
          SizedBox(height: GlobalStyles.paddingTight),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: GlobalStyles.paddingTight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Claims",
                      style: TextStyle(
                        fontSize: GlobalStyles.fontSizeH4,
                        fontWeight: GlobalStyles.fontWeightBold,
                        fontFamily: GlobalStyles.fontFamilyHeading,
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
                        color: GlobalStyles.primaryMain,
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
                        color: GlobalStyles.primaryMain.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusMd,
                        ),
                        border: Border.all(
                          color: GlobalStyles.primaryMain.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.logIn,
                            size: GlobalStyles.iconSizeXl,
                            color: GlobalStyles.primaryMain,
                          ),
                          SizedBox(height: GlobalStyles.paddingTight),
                          Text(
                            'Sign in to view your claims',
                            style: TextStyle(
                              fontSize: GlobalStyles.fontSizeBody1,
                              fontWeight: GlobalStyles.fontWeightSemiBold,
                              color: GlobalStyles.textPrimary,
                              fontFamily: GlobalStyles.fontFamilyBody,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Access your insurance claims and track their status',
                            style: TextStyle(
                              fontSize: GlobalStyles.fontSizeBody2,
                              color: GlobalStyles.textSecondary,
                              fontFamily: GlobalStyles.fontFamilyBody,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: GlobalStyles.paddingNormal),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signin');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalStyles.primaryMain,
                              foregroundColor: GlobalStyles.surfaceMain,
                              padding: EdgeInsets.symmetric(
                                horizontal: GlobalStyles.paddingNormal,
                                vertical: GlobalStyles.paddingTight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  GlobalStyles.radiusMd,
                                ),
                              ),
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: GlobalStyles.fontSizeButton,
                                fontWeight: GlobalStyles.fontWeightSemiBold,
                                fontFamily: GlobalStyles.fontFamilyBody,
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
                            LucideIcons.fileText,
                            size: GlobalStyles.iconSizeXl,
                            color: GlobalStyles.textDisabled,
                          ),
                          SizedBox(height: GlobalStyles.paddingTight),
                          Text(
                            'No claims yet',
                            style: TextStyle(
                              fontSize: GlobalStyles.fontSizeBody1,
                              fontWeight: GlobalStyles.fontWeightSemiBold,
                              color: GlobalStyles.textSecondary,
                              fontFamily: GlobalStyles.fontFamilyBody,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Your insurance claims will appear here',
                            style: TextStyle(
                              fontSize: GlobalStyles.fontSizeBody2,
                              color: GlobalStyles.textTertiary,
                              fontFamily: GlobalStyles.fontFamilyBody,
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
                  SizedBox(height: GlobalStyles.paddingTight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.wifiOff,
                        size: GlobalStyles.iconSizeXs,
                        color: GlobalStyles.successMain,
                      ),
                      SizedBox(width: GlobalStyles.spacingXs),
                      Text(
                        'Synced with cache',
                        style: TextStyle(
                          fontSize: GlobalStyles.fontSizeCaption,
                          color: GlobalStyles.textSecondary,
                          fontFamily: GlobalStyles.fontFamilyBody,
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

  Widget _buildClaimTile(ClaimModel claim) {
    final statusColor = ClaimsWidgetUtils.statusColor(claim.status);
    final formattedStatus = ClaimsWidgetUtils.formatStatus(claim.status);
    final formattedCurrency = ClaimsWidgetUtils.formatCurrency(
      claim.estimatedDamageCost,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaimsWidgetUtils.buildClaimIcon(claim.status, statusColor),
          SizedBox(width: 12.w),
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
                        style: TextStyle(
                          fontSize: GlobalStyles.fontSizeBody2,
                          fontWeight: GlobalStyles.fontWeightSemiBold,
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      formattedCurrency,
                      style: TextStyle(
                        fontWeight: GlobalStyles.fontWeightBold,
                        fontSize: GlobalStyles.fontSizeBody2,
                        color: GlobalStyles.primaryMain,
                        fontFamily: GlobalStyles.fontFamilyBody,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: GlobalStyles.fontSizeCaption,
                        fontWeight: GlobalStyles.fontWeightMedium,
                        fontFamily: GlobalStyles.fontFamilyBody,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(claim.createdAt),
                      style: TextStyle(
                        color: GlobalStyles.textSecondary,
                        fontSize: GlobalStyles.fontSizeCaption,
                        fontFamily: GlobalStyles.fontFamilyBody,
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
        SizedBox(height: GlobalStyles.spacingSm),
        Text(
          label,
          style: TextStyle(
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeBody2,
            fontWeight: GlobalStyles.fontWeightBold,
            fontFamily: GlobalStyles.fontFamilyBody,
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
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: GlobalStyles.iconSizeLg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
