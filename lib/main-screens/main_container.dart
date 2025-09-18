import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/main-screens/claims_screen.dart';
import 'package:insurevis/main-screens/home.dart';
// import 'package:insurevis/main-screens/status_screen.dart';
// import 'package:insurevis/main-screens/history_screen.dart';
// import 'package:insurevis/main-screens/profile_screen.dart';

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

  // Core screens including profile
  final List<Widget> _screens = [
    const Home(),
    // const StatusScreen(),
    const ClaimsScreen(),
    // const ProfileScreen(),
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
      backgroundColor: GlobalStyles.backgroundColorStart,
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
      bottomNavigationBar: _buildSimpleBottomNav(),
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
      child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28.sp),
    );
  }

  // Simple material-like bottom navigation without ripple effect
  // Simple material-like bottom navigation with a top divider
  Widget _buildSimpleBottomNav() {
    // We wrap everything in a Column
    return Column(
      mainAxisSize: MainAxisSize.min, // Important to keep the column compact
      children: [
        // This is the line you want to add
        Divider(
          height: 1.0, // Total space the divider takes vertically
          thickness: 1.0, // The thickness of the line itself
          color: Color(0x232A2A2A), // Choose a subtle color
        ),
        // Your original BottomNavigationBar code follows
        Theme(
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
            unselectedItemColor: Colors.black38,
            type: BottomNavigationBarType.fixed,
            // Setting elevation to 0 is good practice when adding a manual divider
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 35.sp),
                activeIcon: Icon(Icons.home_rounded, size: 35.sp),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined, size: 35.sp),
                activeIcon: Icon(Icons.assignment_rounded, size: 35.sp),
                label: 'Claims',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
