import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/camera.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Insurance-related state variables
  final int _totalClaims = 3;
  final int _pendingClaims = 1;
  final double _coverageAmount = 50000.0;
  final String _nextPaymentDate = "15 Jul 2025";
  @override
  void initState() {
    super.initState();
    // Initialize insurance data if needed
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
                // Greeting section
                SizedBox(height: 20.h),
                RichText(
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
                        text: 'dabiii!',
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(
                            0xFF9F8EE7,
                          ), // Light purple color for username
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Feature card
                _buildFeatureCard(),

                SizedBox(height: 20.h),

                // Scan button
                _buildScanButton(),

                SizedBox(height: 24.h), // Insurance Dashboard section
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
    return Container(
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
            color: Colors.black.withAlpha(51), // 0.2 * 255
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        // Add a semi-transparent overlay for better text readability
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.black.withAlpha(179), // 0.7 * 255
              Colors.black.withAlpha(77), // 0.3 * 255
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          children: [
            // Logo and text content
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Insurevis logo/text
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

                  // Main feature text
                  SizedBox(
                    width: 200.w, // Limit width for text
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                        children: [
                          TextSpan(text: 'Vehicle Inspection Technology '),
                          TextSpan(
                            text: 'at the palm of your hand.',
                            style: TextStyle(color: Color(0xFF9F8EE7)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 7.h),

                  // Explore now button
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
          ],
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
          color: Color(0xFF292832),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                color: GlobalStyles.secondaryColor,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Text(
              'Scan with your camera',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9F8EE7),
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

        // Insurance stats grid
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF292832),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Top row - Claims and Coverage
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      'Total Claims',
                      '$_totalClaims',
                      Icons.assessment,
                      GlobalStyles.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildDashboardCard(
                      'Coverage Amount',
                      '\$${(_coverageAmount / 1000).toStringAsFixed(0)}K',
                      Icons.security,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Bottom row - Pending and Payment
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      'Pending Claims',
                      '$_pendingClaims',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildDashboardCard(
                      'Next Payment',
                      _nextPaymentDate,
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Quick actions
              _buildQuickActions(),
            ],
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
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77), width: 1),
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          Text(title, style: TextStyle(fontSize: 12.sp, color: Colors.white60)),
        ],
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
                  // Navigate to claim filing
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
                  // Navigate to policy details
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
                  // Navigate to support
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
