import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/camera.dart';
import 'package:insurevis/other-screens/notification_center.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:insurevis/providers/user_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    // Initialize UserProvider with demo data if no user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) {
        userProvider.initializeDemoUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: GlobalStyles.backgroundColorStart),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting section with notification bell
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        final userName =
                            userProvider.currentUser?.name.split(' ').first ??
                            'User';
                        return RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Hey, ',
                                style: TextStyle(
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: '$userName!',
                                style: TextStyle(
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9F8EE7),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Notification bell with badge
                    Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, child) {
                        final unreadCount = notificationProvider.unreadCount;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const NotificationCenter(),
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 45.w,
                                height: 45.h,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 20.w,
                                      minHeight: 20.h,
                                    ),
                                    child: Text(
                                      unreadCount > 99
                                          ? '99+'
                                          : unreadCount.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Feature card with glassmorphic effect
                _buildFeatureCard(),

                SizedBox(height: 20.h),

                // Scan button
                _buildScanButton(),

                SizedBox(height: 24.h),

                // Insurance Dashboard section
                _buildInsuranceDashboard(),

                SizedBox(height: 10.h), // Space for bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 155.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/camera_bg.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.2),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: Colors.white70,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Insurevis',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '.',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: GlobalStyles.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  SizedBox(
                    width: 200.w,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Vehicle Inspection Technology ',
                          ),
                          TextSpan(
                            text: 'at the palm of your hand.',
                            style: TextStyle(color: Color(0xFF9F8EE7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Row(
                    children: [
                      Text(
                        'Explore now',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '>>',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: GlobalStyles.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.primaryColor,
              GlobalStyles.primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: GlobalStyles.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.center_focus_strong, color: Colors.white, size: 24.sp),
            SizedBox(width: 12.w),
            Text(
              'Start Vehicle Scan',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dashboard header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Insurance Overview',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: GlobalStyles.primaryColor.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16.sp,
                    color: GlobalStyles.primaryColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Insurance stats grid with glassmorphic container
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Top row - Claims and Coverage
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final user = userProvider.currentUser;
                      final stats = user?.stats;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDashboardCard(
                                  'Total Assessments',
                                  '${stats?.totalAssessments ?? 0}',
                                  Icons.assessment,
                                  GlobalStyles.primaryColor,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildDashboardCard(
                                  'Insurance Status',
                                  'Active',
                                  Icons.security,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),

                          // Bottom row - Documents and Savings
                          Row(
                            children: [
                              Expanded(
                                child: _buildDashboardCard(
                                  'Documents Submitted',
                                  '${stats?.documentsSubmitted ?? 0}',
                                  Icons.description,
                                  Colors.orange,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildDashboardCard(
                                  'Total Saved',
                                  '₱${(stats?.totalSaved ?? 0).toStringAsFixed(0)}',
                                  Icons.savings,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  // Quick actions
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20.sp),
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'File Claim',
                Icons.add_circle_outline,
                Colors.red,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to claim filing')),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActionButton(
                'View Policy',
                Icons.description,
                Colors.blue,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to policy details')),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActionButton(
                'Support',
                Icons.support_agent,
                Colors.green,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navigate to customer support'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
