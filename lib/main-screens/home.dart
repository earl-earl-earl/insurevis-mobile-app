import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<ClaimModel>> _recentClaimsFuture = Future.value([]);
  Timer? _refreshTimer;
  StreamSubscription<dynamic>? _claimsStreamSub;
  @override
  void initState() {
    super.initState();
    // Initialize UserProvider with demo data if no user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndFetchClaims();
    });
  }

  Future<void> _initAndFetchClaims() async {
    // Do not initialize demo users here. Prefer the authenticated supabase
    // user when present; otherwise rely on whatever userProvider currently has.

    if (!mounted) return;

    final claims = await _loadRecentClaims();
    if (!mounted) return;
    setState(() {
      _recentClaimsFuture = Future.value(claims);
    });

    // Setup Supabase realtime subscription for claims belonging to this user
    // Cancel any existing subscription first
    try {
      await _claimsStreamSub?.cancel();
    } catch (e) {
      // ignore
    }
    _claimsStreamSub = null;

    // Only set up realtime subscription when there's an authenticated
    // Supabase user. Demo/local users (stored in UserProvider) use a
    // placeholder id (e.g. 'user_001') which is not a UUID and will
    // cause the Supabase query to fail. Require an authenticated
    // Supabase user here to avoid unnecessary queries.
    final supabaseUser = SupabaseService.currentUser;
    if (supabaseUser != null) {
      final userId = supabaseUser.id;
      try {
        // Use the streaming API which yields list updates for the table rows
        _claimsStreamSub = Supabase.instance.client
            .from('claims')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .listen((event) async {
              // event will be the updated list of rows for this query
              if (!mounted) return;
              final refreshed = await _loadRecentClaims();
              if (!mounted) return;
              setState(() {
                _recentClaimsFuture = Future.value(refreshed);
              });
            });
      } catch (e) {
        debugPrint('Error setting up claims realtime stream: $e');
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    // Clean up realtime stream subscription
    try {
      _claimsStreamSub?.cancel();
    } catch (e) {
      // ignore
    }
    super.dispose();
  }

  Future<List<ClaimModel>> _loadRecentClaims() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final demoUser = userProvider.currentUser;

      // If we have an authenticated Supabase user, fetch from Supabase.
      final supabaseUser = SupabaseService.currentUser;
      if (supabaseUser != null) {
        final userId = supabaseUser.id;
        final claims = await ClaimsService.getUserClaims(userId);
        return claims.take(3).toList();
      }

      // No authenticated Supabase user -> fall back to demo/local store.
      // Map demo user id to a demo-only local set of claims so the UI isn't
      // empty for local/demo users. If there's no demo user available, return
      // an empty list which will show a Sign-in CTA in the UI.
      if (demoUser != null) {
        final demoClaims = _generateDemoClaims(demoUser);
        return demoClaims.take(3).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error loading recent claims: $e');
      return [];
    }
  }

  // Generate a small set of demo ClaimModel instances for a local/demo user
  List<ClaimModel> _generateDemoClaims(dynamic demoUser) {
    // demoUser is expected to be UserProfile from UserProvider, but we keep
    // the signature dynamic to avoid tight coupling in this file.
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
    return Container(
      color: GlobalStyles.backgroundColorStart,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: RichText(
              text: TextSpan(
                text: "Insure",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w900,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: "Vis",
                    style: TextStyle(
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
                        style: TextStyle(
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
                    MaterialPageRoute(
                      builder: (context) {
                        return Scaffold(
                          body: ProfileScreen(),
                          appBar: GlobalStyles.buildCustomAppBar(
                            context: context,
                            icon: Icons.arrow_back_rounded,
                            color: Color(0xFF2A2A2A),
                            appBarBackgroundColor: Colors.transparent,
                          ),
                        );
                      },
                    ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(height: 8.h),

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
                    _buildActionButton(
                      icon: Icons.description_rounded,
                      label: "File Claim",
                      iconColor: Colors.green,
                      onPressed: () {
                        Navigator.pushNamed(context, '/claim_create');
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
                    SizedBox(width: 15.w),
                    _buildActionButton(
                      icon: Icons.shield_rounded,
                      label: "View Policy",
                      iconColor: Colors.purple,
                      onPressed: () {
                        Navigator.pushNamed(context, '/policy');
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
                          "Recent",
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 24.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    FutureBuilder<List<ClaimModel>>(
                      future: _recentClaimsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            height: 60.h,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: GlobalStyles.primaryColor,
                              ),
                            ),
                          );
                        }

                        final claims = snapshot.data ?? [];
                        if (claims.isEmpty) {
                          // If the user isn't signed in, offer a sign-in CTA so
                          // they can view their real claims from Supabase.
                          final supabaseUser = SupabaseService.currentUser;
                          if (supabaseUser == null) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/signin');
                                    },
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'No recent claims — Sign in to view your claims',
                                        style: TextStyle(
                                          color: GlobalStyles.primaryColor,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Text(
                            'No recent claims',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14.sp,
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (var i = 0; i < claims.length; i++) ...[
                              _buildClaimTile(claims[i]),
                              if (i < claims.length - 1)
                                Divider(
                                  height: 1.h,
                                  thickness: 1.h,
                                  color: Colors.grey[300],
                                ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        return Icons.send_rounded;
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
      // Fallback: use simple formatting
      return '₱' + (amount.toStringAsFixed(2));
    }
  }

  Widget _buildClaimTile(ClaimModel claim) {
    // Non-clickable claim tile — preserve appearance but remove InkWell
    return Container(
      // margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      claim.claimNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                      ),
                    ),
                    Text(
                      _formatCurrency(claim.estimatedDamageCost),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '${claim.incidentLocation} • ${claim.vehicleMake ?? ''} ${claim.vehicleModel ?? ''}'
                      .trim(),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12.sp),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          claim.status,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Text(
                        _formatStatus(claim.status),
                        style: TextStyle(
                          color: _statusColor(claim.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      claim.incidentDate.toIso8601String().split('T').first,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.sp,
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
          style: TextStyle(
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
