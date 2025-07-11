import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'package:insurevis/other-screens/multiple_results_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<AssetEntity> _allPhotos = [];
  List<AssetPathEntity> _albums = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  int _selectedAlbumIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // For pagination
  int _currentPage = 0;
  final int _pageSize = 50;
  bool _isLoadingMore = false;
  bool _hasMorePhotos = true;

  // For multi-selection
  final Set<AssetEntity> _selectedAssets = <AssetEntity>{};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePhotos) {
      _loadMorePhotos();
    }
  }

  Future<void> _loadAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      if (albums.isNotEmpty) {
        setState(() {
          _albums = albums;
          _hasPermission = true;
        });
        await _loadPhotosFromAlbum(_selectedAlbumIndex);
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

      // Show more detailed error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery access is required to select photos'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => PhotoManager.openSetting(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadPhotosFromAlbum(int albumIndex) async {
    if (_albums.isEmpty) return;

    setState(() {
      _isLoading = true;
      _selectedAlbumIndex = albumIndex;
      _currentPage = 0;
      _allPhotos.clear();
      _hasMorePhotos = true;
    });

    await _loadMorePhotos();
  }

  Future<void> _loadMorePhotos() async {
    if (_albums.isEmpty || _isLoadingMore || !_hasMorePhotos) return;

    setState(() {
      _isLoadingMore = true;
    });

    final album = _albums[_selectedAlbumIndex];
    final start = _currentPage * _pageSize;
    final end = start + _pageSize;
    try {
      final photos = await album.getAssetListRange(start: start, end: end);

      setState(() {
        if (photos.isEmpty) {
          _hasMorePhotos = false;
        } else {
          _allPhotos.addAll(photos);
          _currentPage++;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading photos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectPhoto(AssetEntity asset) async {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
        if (_selectedAssets.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedAssets.add(asset);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _uploadSelectedImages() async {
    if (_selectedAssets.isEmpty) return;

    try {
      List<String> imagePaths = [];

      for (AssetEntity asset in _selectedAssets) {
        final file = await asset.file;
        if (file != null) {
          imagePaths.add(file.path);
        }
      }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing images: $e')));
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedAssets.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundColorStart,
      appBar: _buildAppBar(),
      body:
          _isLoading && _allPhotos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : !_hasPermission
              ? _buildNoPermissionView()
              : _buildGalleryContent(),
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
        _isSelectionMode ? '${_selectedAssets.length} selected' : 'Gallery',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: _clearSelection,
            tooltip: 'Clear selection',
          ),
          Container(
            margin: EdgeInsets.only(right: 8.w),
            child: ElevatedButton.icon(
              onPressed:
                  _selectedAssets.isNotEmpty ? _uploadSelectedImages : null,
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
        ] else if (_albums.isNotEmpty)
          PopupMenuButton<int>(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            color: const Color(0xFF292832),
            onSelected: _loadPhotosFromAlbum,
            itemBuilder:
                (context) =>
                    _albums
                        .asMap()
                        .entries
                        .map(
                          (entry) => PopupMenuItem<int>(
                            value: entry.key,
                            child: Row(
                              children: [
                                Icon(
                                  entry.key == _selectedAlbumIndex
                                      ? Icons.check_circle
                                      : Icons.photo_album_outlined,
                                  color:
                                      entry.key == _selectedAlbumIndex
                                          ? GlobalStyles.primaryColor
                                          : Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.value.name,
                                    style: TextStyle(
                                      color:
                                          entry.key == _selectedAlbumIndex
                                              ? GlobalStyles.primaryColor
                                              : Colors.white,
                                      fontWeight:
                                          entry.key == _selectedAlbumIndex
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
          ),
      ],
    );
  }

  Widget _buildGalleryContent() {
    return Column(
      children: [
        // Album info header
        if (_albums.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: Colors.black.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  Icons.photo_album,
                  color: GlobalStyles.primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  _albums[_selectedAlbumIndex].name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_allPhotos.length} photos',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                ),
              ],
            ),
          ),

        // Photo grid
        Expanded(
          child:
              _allPhotos.isEmpty
                  ? _buildNoImagesView()
                  : GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4.0,
                      crossAxisSpacing: 4.0,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _allPhotos.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _allPhotos.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final asset = _allPhotos[index];
                      return _buildPhotoTile(asset);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildPhotoTile(AssetEntity asset) {
    final isSelected = _selectedAssets.contains(asset);

    return GestureDetector(
      onTap: () => _selectPhoto(asset),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? GlobalStyles.primaryColor
                    : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List?>(
                future: asset.thumbnailDataWithSize(
                  const ThumbnailSize(200, 200),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    } else {
                      // Handle error case
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
                    }
                  } else {
                    return Container(
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                },
              ),

              // Selection overlay
              if (isSelected)
                Container(
                  color: GlobalStyles.primaryColor.withValues(alpha: 0.3),
                ),

              // Video indicator
              if (asset.type == AssetType.video)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),

              // Selection indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? GlobalStyles.primaryColor
                            : Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child:
                      isSelected
                          ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                          : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography, size: 64.sp, color: Colors.white30),
            SizedBox(height: 24.h),
            Text(
              'Gallery Access Required',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Please enable gallery access in your device settings to view and select photos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: Colors.white70),
            ),
            SizedBox(height: 32.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loadAlbums,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalStyles.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
                SizedBox(width: 16.w),
                ElevatedButton(
                  onPressed: () => PhotoManager.openSetting(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                  ),
                  child: const Text('Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImagesView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_album_outlined,
              size: 64.sp,
              color: Colors.white30,
            ),
            SizedBox(height: 24.h),
            Text(
              'No Images Found',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'This album doesn\'t contain any images. Try selecting a different album or take some photos first.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
