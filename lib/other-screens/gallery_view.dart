import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:insurevis/other-screens/multiple_results_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> imageFiles = [];

        for (var file in result.files) {
          if (file.path != null) {
            imageFiles.add(File(file.path!));
          }
        }

        if (imageFiles.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(imageFiles);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  Future<void> _uploadSelectedImages() async {
    if (_selectedImages.isEmpty) return;

    try {
      List<String> imagePaths =
          _selectedImages.map((file) => file.path).toList();

      if (imagePaths.isNotEmpty && mounted) {
        // Navigate to MultipleResultsScreen to process and upload images
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MultipleResultsScreen(imagePaths: imagePaths),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundColorStart,
      appBar: _buildAppBar(),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickImages,
        backgroundColor: GlobalStyles.primaryColor,
        icon:
            _isLoading
                ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Icon(Icons.add_photo_alternate, color: Colors.white),
        label: Text(
          _isLoading ? 'Loading...' : 'Select Images',
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GlobalStyles.backgroundColorStart,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _selectedImages.isNotEmpty
            ? '${_selectedImages.length} images selected'
            : 'Select Images',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        if (_selectedImages.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: _clearAllImages,
            tooltip: 'Clear all',
          ),
          Container(
            margin: EdgeInsets.only(right: 8.w),
            child: ElevatedButton.icon(
              onPressed: _uploadSelectedImages,
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                textStyle: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    if (_selectedImages.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Selected images info header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          color: Colors.black.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(
                Icons.photo_library,
                color: GlobalStyles.primaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Selected Images',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedImages.length} images',
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
            ],
          ),
        ),

        // Photo grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(8.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
              childAspectRatio: 1.0,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return _buildImageTile(_selectedImages[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80.sp,
              color: Colors.white30,
            ),
            SizedBox(height: 24.h),
            Text(
              'No Images Selected',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Select images from your device to process and analyze for vehicle damage assessment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              ),
              icon: Icon(Icons.add_photo_alternate, size: 24.sp),
              label: Text(
                'Select Images',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(File imageFile, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GlobalStyles.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.file(
              imageFile,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade800,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 24.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Failed to load',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 14.sp),
                ),
              ),
            ),

            // Image number
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
