import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/camera.dart'; // Import the new GalleryScreen
import 'package:insurevis/other-screens/gallery_view.dart';
import 'dart:math' as math;
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // List to store recent photos from gallery
  List<AssetEntity> _recentPhotos = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadRecentImages();
  }

  // Load recent images from the device gallery
  Future<void> _loadRecentImages() async {
    // Request permission
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      // Get only the recent albums with photos
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );

      if (albums.isNotEmpty) {
        // Get the recent photos from the "Recent" album
        final recentAlbum = albums.first;
        final recentAssets = await recentAlbum.getAssetListRange(
          start: 0,
          end: 9, // Get only the first 9 images
        );

        setState(() {
          _recentPhotos = recentAssets;
          _hasPermission = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasPermission = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.gradientBackgroundStart,
      appBar: _buildHeader(), // Use AppBar as header
      body: Container(
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
                  // Remove the SizedBox and _buildHeader() from here

                  // Feature card
                  _buildFeatureCard(),

                  SizedBox(height: 20.h),

                  // Scan button
                  _buildScanButton(),

                  SizedBox(height: 24.h),

                  // Images section
                  _buildImagesSection(),

                  SizedBox(height: 10.h), // Space for bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: RichText(
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
                color: Color(0xFF9F8EE7), // Light purple color for username
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Notification bell
        Container(
          width: 40.w,
          height: 40.w,
          margin: EdgeInsets.only(right: 10.w),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 30.sp,
          ),
        ),
      ],
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
            color: Colors.black.withOpacity(0.2),
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
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.3),
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

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images header with View All button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Images',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            InkWell(
              onTap: () {
                // Navigate to the new GalleryScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GalleryScreen(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 16.sp,
                      color: GlobalStyles.primaryColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Images grid container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF292832),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(10.w),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasPermission
                  ? _buildNoPermissionView()
                  : _recentPhotos.isEmpty
                  ? _buildNoImagesView()
                  : _buildImageGrid(),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 1.0,
      ),
      itemCount: _recentPhotos.length,
      itemBuilder: (context, index) {
        final asset = _recentPhotos[index];
        return FutureBuilder<Uint8List?>(
          future: asset.thumbnailData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior:
                    Clip.antiAlias, // Ensure image respects rounded corners
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The actual image
                    Image.memory(snapshot.data!, fit: BoxFit.cover),

                    if (asset.type == AssetType.video)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 14.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            } else {
              // Loading placeholder
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade800,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildNoPermissionView() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_photography, size: 48.sp, color: Colors.white30),
          SizedBox(height: 16.h),
          Text(
            'Gallery access denied',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please enable gallery access in settings to view your recent images',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: Colors.white38),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadRecentImages,
            child: const Text('Allow Access'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalStyles.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagesView() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_album_outlined, size: 48.sp, color: Colors.white30),
          SizedBox(height: 16.h),
          Text(
            'No images found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Take some photos or sync your device to see them here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
