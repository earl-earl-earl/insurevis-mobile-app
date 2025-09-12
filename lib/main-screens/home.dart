import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/notification_center.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:insurevis/providers/user_provider.dart';
import 'package:insurevis/providers/auth_provider.dart';

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
      color: GlobalStyles.backgroundColorStart,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Material app bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              automaticallyImplyLeading: false,
              title: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final userName =
                      authProvider.currentUser?.name.split(' ').first ?? 'User';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good day,',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
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
                          Icons.notifications_outlined,
                          color: Colors.white,
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
                SizedBox(width: 16.w),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),

                    // Material feature card
                    _buildMaterialFeatureCard(),

                    SizedBox(height: 24.h),

                    // How it works section
                    _buildHowItWorksSection(),

                    SizedBox(height: 24.h),

                    // Recent activity or tips section
                    _buildTipsSection(),

                    SizedBox(
                      height: 100.h,
                    ), // Space for floating button and bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialFeatureCard() {
    return Card(
      elevation: 4,
      color: GlobalStyles.primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: GlobalStyles.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with app logo/icon
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: GlobalStyles.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.security,
                    color: GlobalStyles.primaryColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'InsureVis',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'AI-Powered Vehicle Assessment',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Main message
            Text(
              'Capture, Analyze & Report',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Get instant vehicle damage assessment with our advanced AI technology',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),

            // Action hint
            Row(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: GlobalStyles.primaryColor,
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Tap the camera button to get started',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: GlobalStyles.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Card(
      margin: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: GlobalStyles.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            _buildStepItem(
              1,
              'Take Photos',
              'Capture clear images of vehicle damage',
              Icons.camera_alt,
            ),
            SizedBox(height: 12.h),
            _buildStepItem(
              2,
              'AI Analysis',
              'Our AI analyzes damage and estimates costs',
              Icons.psychology,
            ),
            SizedBox(height: 12.h),
            _buildStepItem(
              3,
              'Get Report',
              'Receive detailed assessment report instantly',
              Icons.description,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Card(
      margin: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tips for Best Results',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: GlobalStyles.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            _buildTipItem(
              'Ensure good lighting when taking photos',
              Icons.wb_sunny,
            ),
            SizedBox(height: 10.h),
            _buildTipItem(
              'Capture damage from multiple angles',
              Icons.threesixty,
            ),
            SizedBox(height: 10.h),
            _buildTipItem(
              'Keep the camera steady for clear images',
              Icons.center_focus_strong,
            ),
            SizedBox(height: 10.h),
            _buildTipItem(
              'Include reference objects for size context',
              Icons.straighten,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(
    int step,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: GlobalStyles.primaryColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Icon(icon, color: GlobalStyles.primaryColor, size: 24.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String tip, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: GlobalStyles.primaryColor, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
