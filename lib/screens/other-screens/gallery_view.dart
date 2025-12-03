import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'dart:io';
import 'package:insurevis/screens/other-screens/multiple_results_screen.dart';
import 'package:insurevis/utils/gallery_utils.dart';

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
      final imageFiles = await GalleryUtils.pickImages();

      if (imageFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(imageFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: GlobalStyles.errorMain,
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
      _selectedImages
        ..clear()
        ..addAll(GalleryUtils.removeImage(_selectedImages, index));
    });
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages
        ..clear()
        ..addAll(GalleryUtils.clearAllImages());
    });
  }

  Future<void> _uploadSelectedImages() async {
    if (!GalleryUtils.hasImages(_selectedImages)) return;

    try {
      final imagePaths = GalleryUtils.convertFilesToPaths(_selectedImages);

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
            backgroundColor: GlobalStyles.errorMain,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.surfaceMain,
      appBar: _buildAppBar(),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _pickImages,
        backgroundColor: GlobalStyles.primaryMain,
        elevation: 4,
        child:
            _isLoading
                ? SizedBox(
                  width: GlobalStyles.iconSizeSm,
                  height: GlobalStyles.iconSizeSm,
                  child: CircularProgressIndicator(
                    color: GlobalStyles.surfaceMain,
                    strokeWidth: 2,
                  ),
                )
                : Icon(
                  LucideIcons.imagePlus,
                  color: GlobalStyles.surfaceMain,
                  size: GlobalStyles.iconSizeLg,
                ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GlobalStyles.surfaceMain,
      elevation: 0,
      shadowColor: GlobalStyles.shadowSm.color,
      leading: IconButton(
        icon: Icon(
          LucideIcons.arrowLeft,
          color: GlobalStyles.textPrimary,
          size: GlobalStyles.iconSizeMd,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _selectedImages.isNotEmpty
            ? '${_selectedImages.length} images selected'
            : 'Select Images',
        style: TextStyle(
          fontFamily: GlobalStyles.fontFamilyHeading,
          fontSize: GlobalStyles.fontSizeH4,
          fontWeight: GlobalStyles.fontWeightSemiBold,
          color: GlobalStyles.textPrimary,
          letterSpacing: GlobalStyles.letterSpacingH4,
        ),
      ),
      actions: [
        if (_selectedImages.isNotEmpty) ...[
          IconButton(
            icon: Icon(
              LucideIcons.trash2,
              color: GlobalStyles.textPrimary,
              size: GlobalStyles.iconSizeSm,
            ),
            onPressed: _clearAllImages,
            tooltip: 'Clear all',
          ),
          Container(
            margin: EdgeInsets.only(right: GlobalStyles.spacingSm),
            child: ElevatedButton.icon(
              onPressed: _uploadSelectedImages,
              icon: Icon(LucideIcons.upload, size: GlobalStyles.iconSizeSm),
              label: Text(
                'Upload',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontWeight: GlobalStyles.fontWeightMedium,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalStyles.primaryMain,
                foregroundColor: GlobalStyles.surfaceMain,
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.paddingTight,
                  vertical: GlobalStyles.paddingTight,
                ),
                textStyle: TextStyle(fontSize: GlobalStyles.fontSizeButton),
                elevation: 0,
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
          padding: EdgeInsets.all(GlobalStyles.paddingNormal),
          color: GlobalStyles.surfaceMain,
          child: Row(
            children: [
              Icon(
                LucideIcons.images,
                color: GlobalStyles.primaryMain,
                size: GlobalStyles.iconSizeSm,
              ),
              SizedBox(width: GlobalStyles.spacingSm),
              Text(
                'Selected Images',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyHeading,
                  fontSize: GlobalStyles.fontSizeH6,
                  fontWeight: GlobalStyles.fontWeightSemiBold,
                  color: GlobalStyles.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedImages.length} images',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeBody2,
                  color: GlobalStyles.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Photo grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(GlobalStyles.spacingSm),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: GlobalStyles.spacingXs.toDouble(),
              crossAxisSpacing: GlobalStyles.spacingXs.toDouble(),
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
        padding: EdgeInsets.all(GlobalStyles.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.images,
              size: GlobalStyles.iconSizeXl * 2,
              color: GlobalStyles.primaryMain,
            ),
            SizedBox(height: GlobalStyles.spacingLg),
            Text(
              'No Images Selected',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyHeading,
                fontSize: GlobalStyles.fontSizeH3,
                fontWeight: GlobalStyles.fontWeightSemiBold,
                color: GlobalStyles.textPrimary,
                letterSpacing: GlobalStyles.letterSpacingH3,
              ),
            ),
            SizedBox(height: GlobalStyles.spacingMd),
            Text(
              'Select images from your device to process and analyze for vehicle damage assessment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeBody1,
                color: GlobalStyles.textSecondary,
                height:
                    GlobalStyles.lineHeightBody1 / GlobalStyles.fontSizeBody1,
              ),
            ),
            SizedBox(height: GlobalStyles.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(File imageFile, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.primaryMain.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.file(
              imageFile,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: GlobalStyles.backgroundMain,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.imageOff,
                        color: GlobalStyles.textDisabled,
                        size: GlobalStyles.iconSizeMd,
                      ),
                      SizedBox(height: GlobalStyles.spacingXs),
                      Text(
                        'Failed to load',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          color: GlobalStyles.textDisabled,
                          fontSize: GlobalStyles.fontSizeCaption,
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
                  width: GlobalStyles.minTouchTarget,
                  height: GlobalStyles.minTouchTarget,
                  decoration: BoxDecoration(
                    color: GlobalStyles.errorMain,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GlobalStyles.surfaceMain,
                      width: 2,
                    ),
                    boxShadow: [GlobalStyles.shadowSm],
                  ),
                  child: Icon(
                    LucideIcons.x,
                    color: GlobalStyles.surfaceMain,
                    size: GlobalStyles.iconSizeXs,
                  ),
                ),
              ),
            ),

            // Image number
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.paddingTight,
                  vertical: GlobalStyles.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: GlobalStyles.textPrimary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.surfaceMain,
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontWeight: GlobalStyles.fontWeightSemiBold,
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
