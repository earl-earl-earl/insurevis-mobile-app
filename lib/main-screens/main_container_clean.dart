import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/main-screens/home.dart';
import 'package:insurevis/main-screens/status_screen.dart';
import 'package:insurevis/main-screens/history_screen.dart';
import 'package:insurevis/main-screens/profile_screen.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final bool _isLoading = false;
  late PageController _pageController;
  late AnimationController _animationController;

  // Core screens with Profile back in navigation
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.gradientBackgroundStart,
      extendBody: true,
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),

          // Loading overlay with modern design
          if (_isLoading)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
              child: Center(
                child: Card(
                  color: GlobalStyles.backgroundColorStart,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: GlobalStyles.primaryColor,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  // Modern glassmorphic bottom navigation
  Widget _buildModernBottomNav() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 80.h,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_rounded, 0),
                  _buildNavItem(Icons.analytics_rounded, 1),
                  _buildCenterButton(),
                  _buildNavItem(Icons.history_rounded, 2),
                  _buildNavItem(Icons.person_rounded, 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? GlobalStyles.primaryColor.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          icon,
          color: isSelected ? GlobalStyles.primaryColor : Colors.white70,
          size: 24.sp,
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () {
        // Navigate to insurance processing/camera screen
        Navigator.pushNamed(context, '/camera');
      },
      child: Container(
        width: 56.w,
        height: 56.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.primaryColor,
              GlobalStyles.primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: GlobalStyles.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add_a_photo_rounded,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
    );
  }
}
