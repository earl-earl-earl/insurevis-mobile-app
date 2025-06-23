import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/assessment_provider.dart';
import 'package:insurevis/other-screens/result-screen.dart';

class MultipleImageUpload extends StatefulWidget {
  const MultipleImageUpload({super.key});

  @override
  State<MultipleImageUpload> createState() => _MultipleImageUploadState();
}

class _MultipleImageUploadState extends State<MultipleImageUpload> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final Map<String, String> _uploadResults =
      {}; // Track upload status for each image
  final Map<String, bool> _uploadProgress = {}; // Track upload progress
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundColorStart,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColorStart,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Multiple Image Upload',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_selectedImages.isNotEmpty && !_isUploading)
            TextButton(
              onPressed: _uploadAllImages,
              child: Text(
                'Upload All',
                style: TextStyle(
                  color: GlobalStyles.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Container(
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
        child: Column(
          children: [
            // Image selection buttons
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isUploading
                              ? null
                              : () => _pickImages(ImageSource.camera),
                      icon: Icon(Icons.camera_alt),
                      label: Text('Take Photos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalStyles.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isUploading
                              ? null
                              : () => _pickImages(ImageSource.gallery),
                      icon: Icon(Icons.photo_library),
                      label: Text('From Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(
                          255,
                          255,
                          255,
                          0.2,
                        ),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ), // Selected images count
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          color: GlobalStyles.primaryColor,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${_selectedImages.length} image(s) selected',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    if (!_isUploading)
                      TextButton.icon(
                        onPressed: _clearAllImages,
                        icon: Icon(
                          Icons.clear_all,
                          color: Colors.redAccent,
                          size: 16.sp,
                        ),
                        label: Text(
                          'Clear All',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Images grid
            Expanded(
              child:
                  _selectedImages.isEmpty
                      ? _buildEmptyState()
                      : _buildImageGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.1),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 60.sp,
              color: GlobalStyles.primaryColor,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No images selected',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                color: const Color.fromRGBO(255, 255, 255, 0.5),
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Tap the buttons above to select multiple images',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color.fromRGBO(255, 255, 255, 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.0,
        ),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          final image = _selectedImages[index];
          final isUploading = _uploadProgress[image.path] ?? false;
          final uploadResult = _uploadResults[image.path];

          return _buildImageTile(image, index, isUploading, uploadResult);
        },
      ),
    );
  }

  Widget _buildImageTile(
    XFile image,
    int index,
    bool isUploading,
    String? uploadResult,
  ) {
    Color borderColor = const Color.fromRGBO(255, 255, 255, 0.3);
    Widget? overlayWidget;
    if (isUploading) {
      borderColor = GlobalStyles.primaryColor;
      overlayWidget = Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryColor.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  color: GlobalStyles.primaryColor,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, color: Colors.white, size: 16.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (uploadResult != null) {
      if (uploadResult == 'success') {
        borderColor = Colors.green;
        overlayWidget = Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 16.sp),
          ),
        );
      } else {
        borderColor = Colors.red;
        overlayWidget = Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error, color: Colors.white, size: 16.sp),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: uploadResult == 'success' ? () => _viewResult(image) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(image.path), fit: BoxFit.cover),

              // Remove button
              if (!isUploading && uploadResult != 'success')
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),

              // Overlay for upload status
              if (overlayWidget != null) overlayWidget,

              // Individual upload button
              if (!isUploading && uploadResult == null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _uploadSingleImage(image),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GlobalStyles.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.upload,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        // For gallery, allow user to select multiple images one by one
        // Since pickMultipleImages might not be available in all versions
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
          });

          // Show option to add more images
          _showAddMoreDialog();
        }
      } else {
        // Take single photo with camera
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddMoreDialog() {
    showDialog(
      context: context,
      useSafeArea: true,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF292832),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  color: GlobalStyles.primaryColor,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text('Add More Images?', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Would you like to select more images from the gallery?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('No', style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
                child: Text(
                  'Yes',
                  style: TextStyle(color: GlobalStyles.primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      final image = _selectedImages[index];
      _selectedImages.removeAt(index);
      _uploadResults.remove(image.path);
      _uploadProgress.remove(image.path);
    });
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
      _uploadResults.clear();
      _uploadProgress.clear();
    });
  }

  Future<void> _uploadAllImages() async {
    if (_selectedImages.isEmpty || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    for (final image in _selectedImages) {
      if (_uploadResults[image.path] == null) {
        await _uploadSingleImage(image);
      }
    }

    setState(() {
      _isUploading = false;
    });

    _showUploadSummary();
  }

  Future<void> _uploadSingleImage(XFile image) async {
    setState(() {
      _uploadProgress[image.path] = true;
    });

    try {
      final result = await _sendImageToAPI(image);

      setState(() {
        _uploadResults[image.path] = result ? 'success' : 'error';
        _uploadProgress[image.path] = false;
      });
      if (result && mounted) {
        // Add to assessment provider
        final assessmentProvider = Provider.of<AssessmentProvider>(
          context,
          listen: false,
        );
        await assessmentProvider.addAssessment(image.path);
      }
    } catch (e) {
      setState(() {
        _uploadResults[image.path] = 'error';
        _uploadProgress[image.path] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<bool> _sendImageToAPI(XFile image) async {
    final url = Uri.parse(
      'https://rooster-faithful-terminally.ngrok-free.app/predict',
    );

    try {
      print("Uploading image: ${image.path}");

      final ioClient =
          HttpClient()..badCertificateCallback = (cert, host, port) => true;
      final client = IOClient(ioClient);
      final request =
          http.MultipartRequest('POST', url)
            ..files.add(
              await http.MultipartFile.fromPath('image_file', image.path),
            )
            ..headers.addAll({
              'Accept': 'application/json',
              'ngrok-skip-browser-warning':
                  'true', // Skip ngrok browser warning
              'User-Agent': 'InsurevisApp/1.0',
            });

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      print("Error uploading image: $e");
      return false;
    }
  }

  void _showUploadSummary() {
    final successCount =
        _uploadResults.values.where((r) => r == 'success').length;
    final errorCount = _uploadResults.values.where((r) => r == 'error').length;
    showDialog(
      context: context,
      useSafeArea: true,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF292832),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.upload_rounded,
                  color: GlobalStyles.primaryColor,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text('Upload Summary', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Successfully uploaded: $successCount',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                if (errorCount > 0) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Failed uploads: $errorCount',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(color: GlobalStyles.primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  void _viewResult(XFile image) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(imagePath: image.path),
        ),
      );
    }
  }
}
