import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/main-screens/home.dart';
import 'package:insurevis/main-screens/status_screen.dart';
import 'package:insurevis/main-screens/history_screen.dart';
import 'package:insurevis/main-screens/profile_screen.dart';
import 'package:insurevis/main-screens/documents_screen.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:insurevis/providers/auth_provider.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _selectedDrawerIndex = -1;
  late PageController _pageController;
  late AnimationController _animationController;

  bool _isLoading = false;

  // Core screens including profile in navigation
  final List<Widget> _screens = [
    const Home(),
    const StatusScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Initialize sample notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notificationProvider.initializeSampleNotifications();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Enhanced navigation with improved feedback
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    _animationController.reset();
    _animationController.forward();
  }

  // Enhanced navigation to drawer screens with loading states
  void _navigateToScreen(Widget screen, {String? screenName}) async {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);

    setState(() => _isLoading = true);

    // Show loading feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${screenName ?? 'screen'}...'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: GlobalStyles.primaryColor.withAlpha(230), // 0.9 * 255
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );

      setState(() {
        _isLoading = false;
        _selectedDrawerIndex = -1;
      });
    }
  }

  // Enhanced side drawer with comprehensive UX improvements
  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: GlobalStyles.backgroundColorStart,
      elevation: 16,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.backgroundColorStart,
              GlobalStyles.backgroundColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced user header with improved visual hierarchy
              _buildUserHeader(),

              // Main navigation section
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  children: [
                    // Primary actions
                    _buildSectionHeader('Quick Actions'),
                    Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, child) {
                        return _buildDrawerItem(
                          icon: Icons.upload_file_outlined,
                          title: 'Documents',
                          subtitle: 'Submit insurance documents',
                          index: 0,
                          badge: notificationProvider.documentsBadgeCount,
                          onTap: () {
                            setState(() => _selectedDrawerIndex = 0);
                            _navigateToScreen(
                              const DocumentsScreen(),
                              screenName: 'Documents',
                            );
                          },
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      subtitle: 'Manage your account settings',
                      index: 1,
                      onTap: () {
                        setState(() => _selectedDrawerIndex = 1);
                        _navigateToScreen(
                          const ProfileScreen(),
                          screenName: 'Profile',
                        );
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Utility section
                    _buildSectionHeader('Utilities'),
                    _buildDrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences & configuration',
                      index: 2,
                      onTap: () {
                        setState(() => _selectedDrawerIndex = 2);
                        Navigator.pop(context);
                        _showEnhancedSettingsDialog();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get assistance & tutorials',
                      index: 3,
                      onTap: () {
                        setState(() => _selectedDrawerIndex = 3);
                        Navigator.pop(context);
                        _showEnhancedHelpDialog();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'App information & version',
                      index: 4,
                      onTap: () {
                        setState(() => _selectedDrawerIndex = 4);
                        Navigator.pop(context);
                        _showEnhancedAboutDialog();
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Account section
                    _buildSectionHeader('Account'),
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Securely logout from your account',
                      index: 5,
                      isDestructive: true,
                      onTap: () {
                        setState(() => _selectedDrawerIndex = 5);
                        Navigator.pop(context);
                        _showEnhancedLogoutDialog();
                      },
                    ),
                  ],
                ),
              ),

              // Enhanced footer with swipe hint
              _buildDrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced user header with stats
  Widget _buildUserHeader() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GlobalStyles.primaryColor.withAlpha(242), // 0.95 * 255
            GlobalStyles.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: GlobalStyles.primaryColor.withAlpha(77), // 0.3 * 255
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Enhanced avatar with online indicator
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51), // 0.2 * 255
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 35.r,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 42.sp,
                          color: GlobalStyles.primaryColor,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 16.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Use user data from AuthProvider
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.currentUser;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                user?.email ?? 'user@email.com',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(
                                    230,
                                  ), // 0.9 * 255
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(64), // 0.25 * 255
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withAlpha(77), // 0.3 * 255
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: 12.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Premium Member',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // Enhanced stats row - use real user data
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final stats = authProvider.currentUser?.stats;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '${stats?.totalAssessments ?? 0}',
                      'Reports',
                      Icons.description,
                    ),
                    _buildStatItem(
                      '${stats?.completedAssessments ?? 0}',
                      'Claims',
                      Icons.assignment,
                    ),
                    _buildStatItem(
                      '₱${(stats?.totalSaved ?? 0).toStringAsFixed(0)}',
                      'Saved',
                      Icons.savings,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced stat items with icons
  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: Colors.white, size: 16.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  // Section headers for better organization
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Enhanced drawer items with better feedback
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
    required VoidCallback onTap,
    bool isDestructive = false,
    int? badge,
  }) {
    final isSelected = _selectedDrawerIndex == index;
    final color = isDestructive ? Colors.red : GlobalStyles.primaryColor;

    return Semantics(
      label: title,
      hint: subtitle,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border:
              isSelected
                  ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  // Icon container with badge support
                  Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color:
                              isDestructive
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                          border:
                              isSelected
                                  ? Border.all(
                                    color: color.withValues(alpha: 0.3),
                                    width: 1,
                                  )
                                  : null,
                        ),
                        child: Icon(icon, color: color, size: 20.sp),
                      ),
                      if (badge != null && badge > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16.w,
                              minHeight: 16.h,
                            ),
                            child: Text(
                              badge.toString(),
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
                  SizedBox(width: 16.w),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isDestructive ? Colors.red : Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color:
                                isDestructive
                                    ? Colors.red.withValues(alpha: 0.7)
                                    : Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selection indicator
                  if (isSelected)
                    Icon(Icons.arrow_forward_ios, color: color, size: 16.sp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced drawer footer
  Widget _buildDrawerFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.swipe_left, color: Colors.white54, size: 16.sp),
          SizedBox(width: 8.w),
          Text(
            'Swipe to close drawer',
            style: TextStyle(color: Colors.white54, fontSize: 12.sp),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: Icon(Icons.close, color: Colors.white70, size: 20.sp),
            tooltip: 'Close drawer',
          ),
        ],
      ),
    );
  }

  // Enhanced Settings Dialog
  void _showEnhancedSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: GlobalStyles.backgroundColorStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.settings,
                  color: GlobalStyles.primaryColor,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Settings',
                  style: TextStyle(color: Colors.white, fontSize: 18.sp),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEnhancedSettingItem(
                    'Push Notifications',
                    true,
                    Icons.notifications,
                  ),
                  _buildEnhancedSettingItem('Dark Mode', true, Icons.dark_mode),
                  _buildEnhancedSettingItem(
                    'Auto-sync Data',
                    false,
                    Icons.sync,
                  ),
                  _buildEnhancedSettingItem(
                    'Data Saver Mode',
                    false,
                    Icons.data_saver_on,
                  ),
                  _buildEnhancedSettingItem(
                    'Biometric Login',
                    true,
                    Icons.fingerprint,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: GlobalStyles.primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildEnhancedSettingItem(String title, bool value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              // Add setting change logic here
            },
            activeColor: GlobalStyles.primaryColor,
            activeTrackColor: GlobalStyles.primaryColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  // Enhanced Help Dialog
  void _showEnhancedHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: GlobalStyles.backgroundColorStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(Icons.help, color: GlobalStyles.primaryColor, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Help & Support',
                  style: TextStyle(color: Colors.white, fontSize: 18.sp),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEnhancedHelpItem(
                      '📱',
                      'Taking Photos',
                      'Best practices for capturing vehicle damage clearly',
                      () => _showHelpDetail('Photo Guide'),
                    ),
                    _buildEnhancedHelpItem(
                      '📋',
                      'Document Upload',
                      'Step-by-step guide for submitting documents',
                      () => _showHelpDetail('Upload Guide'),
                    ),
                    _buildEnhancedHelpItem(
                      '🔍',
                      'Understanding Reports',
                      'How to interpret AI damage assessment results',
                      () => _showHelpDetail('Report Guide'),
                    ),
                    _buildEnhancedHelpItem(
                      '💬',
                      'Contact Support',
                      'Get direct help from our support team',
                      () => _showContactOptions(),
                    ),
                    _buildEnhancedHelpItem(
                      '🎯',
                      'Quick Tutorial',
                      'Interactive walkthrough of app features',
                      () => _startTutorial(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: GlobalStyles.primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildEnhancedHelpItem(
    String emoji,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          child: Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 24.sp)),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14.sp),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced About Dialog
  void _showEnhancedAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: GlobalStyles.backgroundColorStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(Icons.info, color: GlobalStyles.primaryColor, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'About InsureVis',
                  style: TextStyle(color: Colors.white, fontSize: 18.sp),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App version and logo
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64.w,
                            height: 64.h,
                            decoration: BoxDecoration(
                              color: GlobalStyles.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              Icons.security,
                              color: GlobalStyles.primaryColor,
                              size: 32.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'InsureVis v1.0.0',
                            style: TextStyle(
                              color: GlobalStyles.primaryColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Description
                    Text(
                      'AI-powered vehicle damage assessment tool for insurance claims. Capture, analyze, and report vehicle damage with precision and speed.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),

                    // Features section
                    Text(
                      'Key Features:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...[
                      ('🤖', 'AI Damage Detection'),
                      ('', 'PDF Report Generation'),
                      ('📁', 'Document Management'),
                      ('📊', 'Multi-image Analysis'),
                      ('🔒', 'Secure Data Handling'),
                    ].map(
                      (feature) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          children: [
                            Text(feature.$1, style: TextStyle(fontSize: 16.sp)),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                feature.$2,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Additional info
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developer: InsureVis Team',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Last Updated: June 2025',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Privacy Policy | Terms of Service',
                            style: TextStyle(
                              color: GlobalStyles.primaryColor,
                              fontSize: 12.sp,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: GlobalStyles.primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  // Enhanced Logout Dialog
  void _showEnhancedLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: GlobalStyles.backgroundColorStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(Icons.logout, color: Colors.red, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white, fontSize: 18.sp),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to sign out of your account?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Any unsaved changes will be lost.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  // Add logout logic here
                  _performLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  // Helper methods for dialog actions
  void _showHelpDetail(String topic) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $topic...'),
        backgroundColor: GlobalStyles.primaryColor,
      ),
    );
  }

  void _showContactOptions() {
    Navigator.pop(context);
    // Implement contact options
  }

  void _startTutorial() {
    Navigator.pop(context);
    // Implement tutorial
  }

  void _performLogout() {
    // Add actual logout logic
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideDrawer(),
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    GlobalStyles.primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildEnhancedBottomNav(),
      floatingActionButton:
          _selectedIndex == 0 ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Floating action button for camera
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, '/camera');
      },
      backgroundColor: GlobalStyles.primaryColor,
      elevation: 6,
      child: Icon(Icons.camera_alt, color: Colors.white, size: 28.sp),
    );
  }

  // Simple material-like bottom navigation without ripple effect
  Widget _buildEnhancedBottomNav() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: GlobalStyles.backgroundColorStart,
        selectedItemColor: GlobalStyles.primaryColor,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          _buildBottomNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
          _buildBottomNavItem(
            1,
            Icons.access_time_outlined,
            Icons.access_time,
            'Status',
          ),
          _buildBottomNavItem(
            2,
            Icons.history_outlined,
            Icons.history,
            'History',
          ),
          _buildBottomNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    // Get badge count for notifications
    int? badgeCount;
    switch (index) {
      case 1: // Status screen
        badgeCount = context.watch<NotificationProvider>().statusBadgeCount;
        break;
      case 2: // History screen
        badgeCount = context.watch<NotificationProvider>().historyBadgeCount;
        break;
      default:
        badgeCount = null;
    }

    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
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
      activeIcon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(activeIcon),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
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
      label: label,
    );
  }
}
