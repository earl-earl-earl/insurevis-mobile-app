import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _GalleryScreenState extends State<GalleryScreen>
    with TickerProviderStateMixin {
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  late AnimationController _fabAnimationController;
  late AnimationController _gridAnimationController;
  late Animation<double> _fabScale;
  late Animation<double> _gridFade;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _gridFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gridAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _gridAnimationController.dispose();
    super.dispose();
  }

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
        // Play grid animation when images are added
        _gridAnimationController.reset();
        _gridAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: GlobalStyles.errorMain,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(GlobalStyles.spacingMd),
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
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedImages
        ..clear()
        ..addAll(GalleryUtils.removeImage(_selectedImages, index));
    });
  }

  void _clearAllImages() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: GlobalStyles.surfaceMain,
            title: Text(
              'Clear All Images?',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyHeading,
                fontSize: GlobalStyles.fontSizeH5,
                fontWeight: GlobalStyles.fontWeightSemiBold,
                color: GlobalStyles.textPrimary,
              ),
            ),
            content: Text(
              'This action cannot be undone. All ${_selectedImages.length} selected images will be removed.',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeBody1,
                color: GlobalStyles.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: GlobalStyles.textSecondary,
                    fontWeight: GlobalStyles.fontWeightMedium,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImages
                      ..clear()
                      ..addAll(GalleryUtils.clearAllImages());
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All images cleared'),
                      backgroundColor: GlobalStyles.successMain,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(GlobalStyles.spacingMd),
                    ),
                  );
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: GlobalStyles.errorMain,
                    fontWeight: GlobalStyles.fontWeightMedium,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _uploadSelectedImages() async {
    if (!GalleryUtils.hasImages(_selectedImages)) return;

    HapticFeedback.mediumImpact();
    try {
      final imagePaths = GalleryUtils.convertFilesToPaths(_selectedImages);

      if (imagePaths.isNotEmpty && mounted) {
        // Navigate to MultipleResultsScreen to process and upload images
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    MultipleResultsScreen(imagePaths: imagePaths),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic)),
                ),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing images: $e'),
            backgroundColor: GlobalStyles.errorMain,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(GlobalStyles.spacingMd),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: _buildAppBar(),
      body: _buildContent(),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: _isLoading ? null : _pickImages,
          backgroundColor: GlobalStyles.primaryMain,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
          ),
          child:
              _isLoading
                  ? SizedBox(
                    width: GlobalStyles.iconSizeSm,
                    height: GlobalStyles.iconSizeSm,
                    child: CircularProgressIndicator(
                      color: GlobalStyles.surfaceMain,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        GlobalStyles.surfaceMain,
                      ),
                    ),
                  )
                  : Icon(
                    LucideIcons.imagePlus,
                    color: GlobalStyles.surfaceMain,
                    size: GlobalStyles.iconSizeLg,
                  ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GlobalStyles.surfaceMain,
      elevation: 0.5,
      shadowColor: GlobalStyles.shadowSm.color,
      leading: IconButton(
        icon: Icon(
          LucideIcons.arrowLeft,
          color: GlobalStyles.textPrimary,
          size: GlobalStyles.iconSizeMd,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        tooltip: 'Go back',
      ),
      title: Text(
        'Upload Images',
        style: TextStyle(
          fontFamily: GlobalStyles.fontFamilyHeading,
          fontSize: GlobalStyles.fontSizeH4,
          fontWeight: GlobalStyles.fontWeightSemiBold,
          color: GlobalStyles.textPrimary,
          letterSpacing: GlobalStyles.letterSpacingH4,
        ),
      ),
      centerTitle: false,
      actions: [
        if (_selectedImages.isNotEmpty) ...[
          IconButton(
            icon: Icon(
              LucideIcons.trash2,
              color: GlobalStyles.errorMain,
              size: GlobalStyles.iconSizeSm,
            ),
            onPressed: _clearAllImages,
            tooltip: 'Clear all images',
            splashRadius: GlobalStyles.iconSizeMd,
          ),
          Container(
            margin: EdgeInsets.only(right: GlobalStyles.spacingSm),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _uploadSelectedImages,
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: GlobalStyles.paddingNormal,
                    vertical: GlobalStyles.paddingTight,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        GlobalStyles.primaryMain,
                        GlobalStyles.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: GlobalStyles.primaryMain.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.upload,
                        color: GlobalStyles.surfaceMain,
                        size: GlobalStyles.iconSizeSm,
                      ),
                      SizedBox(width: GlobalStyles.spacingSm),
                      Text(
                        'Process',
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontWeight: GlobalStyles.fontWeightSemiBold,
                          color: GlobalStyles.surfaceMain,
                          fontSize: GlobalStyles.fontSizeButton,
                        ),
                      ),
                    ],
                  ),
                ),
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
        // Selected images info header with glass effect
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: GlobalStyles.paddingNormal,
            vertical: GlobalStyles.paddingNormal,
          ),
          decoration: BoxDecoration(
            color: GlobalStyles.surfaceMain,
            border: Border(
              bottom: BorderSide(
                color: GlobalStyles.textPrimary.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            boxShadow: [GlobalStyles.shadowSm],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(GlobalStyles.spacingXs),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                ),
                child: Icon(
                  LucideIcons.images,
                  color: GlobalStyles.primaryMain,
                  size: GlobalStyles.iconSizeSm,
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Images',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyHeading,
                      fontSize: GlobalStyles.fontSizeBody1,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                      color: GlobalStyles.textPrimary,
                    ),
                  ),
                  SizedBox(height: GlobalStyles.spacingXs),
                  Text(
                    'Ready for processing',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeCaption,
                      color: GlobalStyles.textTertiary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.paddingTight,
                  vertical: GlobalStyles.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                  border: Border.all(
                    color: GlobalStyles.primaryMain.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_selectedImages.length}',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    fontSize: GlobalStyles.fontSizeBody1,
                    fontWeight: GlobalStyles.fontWeightBold,
                    color: GlobalStyles.primaryMain,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Photo grid with fade animation
        Expanded(
          child: FadeTransition(
            opacity: _gridFade,
            child: GridView.builder(
              padding: EdgeInsets.all(GlobalStyles.spacingMd),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: GlobalStyles.spacingMd.toDouble(),
                crossAxisSpacing: GlobalStyles.spacingMd.toDouble(),
                childAspectRatio: 1.0,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return _buildAnimatedImageTile(_selectedImages[index], index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedImageTile(File imageFile, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _buildImageTile(imageFile, index),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(GlobalStyles.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                padding: EdgeInsets.all(GlobalStyles.spacingLg),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GlobalStyles.primaryMain.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  LucideIcons.images,
                  size: GlobalStyles.iconSizeXl * 1.5,
                  color: GlobalStyles.primaryMain,
                ),
              ),
            ),
            SizedBox(height: GlobalStyles.spacingXl),
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
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: GlobalStyles.paddingNormal,
                vertical: GlobalStyles.paddingTight,
              ),
              decoration: BoxDecoration(
                color: GlobalStyles.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                border: Border.all(
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Tap the + button to start',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeCaption,
                  color: GlobalStyles.primaryMain,
                  fontWeight: GlobalStyles.fontWeightMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(File imageFile, int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onLongPress: () => _removeImage(index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
            border: Border.all(
              color: GlobalStyles.primaryMain.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: GlobalStyles.textPrimary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image with shimmer effect on load
                Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  frameBuilder: (
                    context,
                    child,
                    frame,
                    wasSynchronouslyLoaded,
                  ) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: child,
                    );
                  },
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

                // Overlay on hover/interaction
                Container(
                  decoration: BoxDecoration(
                    color: GlobalStyles.textPrimary.withValues(alpha: 0.0),
                  ),
                ),

                // Remove button with smooth animation
                Positioned(
                  top: GlobalStyles.spacingSm,
                  right: GlobalStyles.spacingSm,
                  child: _buildRemoveButton(index),
                ),

                // Image number badge
                Positioned(
                  bottom: GlobalStyles.spacingSm,
                  left: GlobalStyles.spacingSm,
                  child: _buildImageBadge(index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _removeImage(index),
        customBorder: CircleBorder(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: GlobalStyles.errorMain,
            shape: BoxShape.circle,
            border: Border.all(color: GlobalStyles.surfaceMain, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: GlobalStyles.errorMain.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(LucideIcons.x, color: GlobalStyles.surfaceMain, size: 14),
        ),
      ),
    );
  }

  Widget _buildImageBadge(int index) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GlobalStyles.paddingTight,
        vertical: GlobalStyles.spacingXs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GlobalStyles.textPrimary.withValues(alpha: 0.8),
            GlobalStyles.textPrimary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
        boxShadow: [
          BoxShadow(
            color: GlobalStyles.textPrimary.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontFamily: GlobalStyles.fontFamilyHeading,
          color: GlobalStyles.surfaceMain,
          fontSize: GlobalStyles.fontSizeCaption,
          fontWeight: GlobalStyles.fontWeightBold,
        ),
      ),
    );
  }
}
