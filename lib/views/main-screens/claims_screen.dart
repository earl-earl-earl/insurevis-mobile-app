import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:insurevis/services/supabase_service.dart';

import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:insurevis/views/main-screens/claim_details_screen.dart';
import 'package:insurevis/utils/claims_cache_utils.dart';
import 'package:insurevis/utils/claims_handler_utils.dart';
import 'package:insurevis/utils/claims_widget_utils.dart';

class ClaimsScreen extends StatefulWidget {
  static const routeName = '/claims';

  const ClaimsScreen({Key? key}) : super(key: key);

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  List<ClaimModel> _allClaims = [];
  List<ClaimModel> _filtered = [];
  String _query = '';
  bool _loading = false;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  SortOption _currentSort = SortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    _filtered = List.from(_allClaims);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeClaims());
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  /// Load sort preference from storage
  Future<void> _loadSortPreference() async {
    final sortIndex = await ClaimsCacheUtils.loadSortPreference();
    if (sortIndex != null) {
      setState(() {
        _currentSort = SortOption.values[sortIndex];
      });
    }
  }

  /// Save sort preference to storage
  Future<void> _saveSortPreference(SortOption sort) async {
    await ClaimsCacheUtils.saveSortPreference(sort.index);
  }

  /// Initialize claims by loading from cache first, then syncing with server
  Future<void> _initializeClaims() async {
    // Load from cache immediately for fast UI
    await _loadFromCache();

    // Then sync with server in background
    await _syncWithServer();
  }

  /// Load claims from local storage
  Future<void> _loadFromCache() async {
    final claims = await ClaimsCacheUtils.loadFromCache();
    if (claims != null) {
      setState(() {
        _allClaims = claims;
        _filtered = _applyFiltersAndSort();
      });
    }
  }

  /// Save claims to local storage
  Future<void> _saveToCache(List<ClaimModel> claims) async {
    await ClaimsCacheUtils.saveToCache(claims);
  }

  /// Sync with server and update cache
  Future<void> _syncWithServer() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        setState(() {
          _allClaims = [];
          _filtered = [];
          _errorMessage = 'Please sign in to view claims.';
          _loading = false;
        });
        return;
      }

      final claims = await ClaimsHandlerUtils.syncWithServer();

      if (claims != null) {
        setState(() {
          _allClaims = claims;
          _filtered = _applyFiltersAndSort();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to sync claims. Using cached data.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to sync claims. Using cached data.';
      });
      if (kDebugMode) print('Sync claims error: $e');
    }
  }

  /// Setup real-time updates for claims
  void _setupRealtimeUpdates() {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    _realtimeSubscription = ClaimsHandlerUtils.setupRealtimeUpdates(
      user.id,
      (data) => _handleRealtimeUpdate(data),
    );
  }

  /// Handle real-time updates from Supabase
  void _handleRealtimeUpdate(List<Map<String, dynamic>> data) {
    try {
      final updatedClaims =
          data.map((json) => ClaimModel.fromJson(json)).toList();

      // Save updated data to cache
      _saveToCache(updatedClaims);

      setState(() {
        _allClaims = updatedClaims;
        _filtered = _applyFiltersAndSort();
      });

      if (kDebugMode) print('Real-time update: ${updatedClaims.length} claims');

      // Show snackbar for new claims
      if (updatedClaims.length > _allClaims.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New claim received'),
            backgroundColor: GlobalStyles.primaryMain,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error handling real-time update: $e');
    }
  }

  /// Get last sync time for display
  Future<String> _getLastSyncTime() async {
    final timestamp = await ClaimsCacheUtils.getLastSyncTimestamp();
    if (timestamp != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat.jm().format(date);
    }
    return 'Never';
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    await _syncWithServer();
  }

  List<ClaimModel> _applyFiltersAndSort() {
    return ClaimsHandlerUtils.applyFiltersAndSort(
      _allClaims,
      _query,
      _currentSort,
    );
  }

  void _onSearchChanged(String q) {
    setState(() {
      _query = q;
      _filtered = _applyFiltersAndSort();
    });
  }

  void _onSortChanged(SortOption sort) {
    setState(() {
      _currentSort = sort;
      _filtered = _applyFiltersAndSort();
    });
    _saveSortPreference(sort);
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Constrain the bottom sheet height to a percentage of the screen
        final maxHeight = MediaQuery.of(context).size.height * 0.60;

        return SingleChildScrollView(
          // This padding ensures the sheet can expand above the keyboard if needed
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: BoxDecoration(
                color: GlobalStyles.surfaceMain,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(GlobalStyles.radiusXl),
                ),
              ),
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: GlobalStyles.textDisabled,
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusSm,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Title
                  Text(
                    'Sort Claims',
                    style: TextStyle(
                      fontSize: GlobalStyles.fontSizeH4,
                      fontWeight: GlobalStyles.fontWeightBold,
                      fontFamily: GlobalStyles.fontFamilyHeading,
                      color: GlobalStyles.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Sort options
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            SortOption.values
                                .map(
                                  (option) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      ClaimsWidgetUtils.getSortOptionIcon(
                                        option,
                                      ),
                                      color:
                                          _currentSort == option
                                              ? GlobalStyles.primaryMain
                                              : GlobalStyles.textTertiary,
                                      size: GlobalStyles.iconSizeSm,
                                    ),
                                    title: Text(
                                      ClaimsWidgetUtils.getSortOptionLabel(
                                        option,
                                      ),
                                      style: TextStyle(
                                        fontSize: GlobalStyles.fontSizeBody2,
                                        fontWeight:
                                            _currentSort == option
                                                ? GlobalStyles
                                                    .fontWeightSemiBold
                                                : GlobalStyles
                                                    .fontWeightRegular,
                                        color:
                                            _currentSort == option
                                                ? GlobalStyles.primaryMain
                                                : GlobalStyles.textPrimary,
                                        fontFamily: GlobalStyles.fontFamilyBody,
                                      ),
                                    ),
                                    trailing:
                                        _currentSort == option
                                            ? Icon(
                                              LucideIcons.check,
                                              color: GlobalStyles.primaryMain,
                                              size: GlobalStyles.iconSizeSm,
                                            )
                                            : null,
                                    onTap: () {
                                      _onSortChanged(option);
                                      Navigator.pop(context);
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClaimDetails(ClaimModel claim) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ClaimDetailsScreen(
              claim: claim,
              buildClaimIcon: ClaimsWidgetUtils.buildClaimIcon,
              statusColor: ClaimsWidgetUtils.statusColor,
              formatStatus: ClaimsWidgetUtils.formatStatus,
              formatCurrency: ClaimsWidgetUtils.formatCurrency,
            ),
      ),
    );

    if (result != null && result is ClaimModel) {
      if (kDebugMode) print('Claim updated, triggering refresh...');
      await _syncWithServer();
    }
  }

  Widget _buildClaimTile(ClaimModel claim) {
    final statusColor = ClaimsWidgetUtils.statusColor(claim.status);
    final formattedStatus = ClaimsWidgetUtils.formatStatus(claim.status);
    final formattedCurrency = ClaimsWidgetUtils.formatCurrency(
      claim.estimatedDamageCost,
    );

    return InkWell(
      onTap: () => _showClaimDetails(claim),
      borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            ClaimsWidgetUtils.buildClaimIcon(claim.status, statusColor),
            SizedBox(width: 12.w),
            // Details column takes remaining width
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          claim.claimNumber,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                            fontFamily: GlobalStyles.fontFamilyBody,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        formattedCurrency,
                        style: TextStyle(
                          fontWeight: GlobalStyles.fontWeightBold,
                          fontSize: 14.sp,
                          color: GlobalStyles.primaryMain,
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: GlobalStyles.fontSizeCaption,
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().format(claim.createdAt),
                        style: TextStyle(
                          color: GlobalStyles.textTertiary,
                          fontSize: GlobalStyles.fontSizeCaption,
                          fontFamily: GlobalStyles.fontFamilyBody,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 0,
        title: Text(
          'Claims',
          style: TextStyle(
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeH2,
            fontWeight: GlobalStyles.fontWeightBold,
            fontFamily: GlobalStyles.fontFamilyHeading,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(
              LucideIcons.refreshCw,
              color: GlobalStyles.textSecondary,
              size: GlobalStyles.iconSizeMd,
            ),
            tooltip: 'Refresh',
          ),
          SizedBox(width: 4.w),
          IconButton(
            onPressed: _showSortMenu,
            icon: Icon(
              LucideIcons.arrowUpDown,
              color: GlobalStyles.textSecondary,
              size: GlobalStyles.iconSizeMd,
            ),
            tooltip: 'Sort',
          ),
          // Debug menu for development
          // if (kDebugMode) ...[
          //   PopupMenuButton<String>(
          //     icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          //     onSelected: (value) {
          //       switch (value) {
          //         case 'clear_cache':
          //           _clearCache();
          //           break;
          //         case 'show_sync_info':
          //           _showSyncInfo();
          //           break;
          //       }
          //     },
          //     itemBuilder:
          //         (context) => [
          //           PopupMenuItem(
          //             value: 'clear_cache',
          //             child: Text('Clear Cache'),
          //           ),
          //           PopupMenuItem(
          //             value: 'show_sync_info',
          //             child: Text('Sync Info'),
          //           ),
          //         ],
          //   ),
          // ],
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar with improved styling
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Container(
                decoration: BoxDecoration(
                  color: GlobalStyles.surfaceElevated,
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                ),
                child: TextField(
                  key: const Key('claims_search'),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: GlobalStyles.textTertiary,
                      size: GlobalStyles.iconSizeSm,
                    ),
                    hintText: 'Search claims by id, status or text',
                    hintStyle: TextStyle(
                      color: GlobalStyles.textTertiary,
                      fontSize: GlobalStyles.fontSizeBody2,
                      fontFamily: GlobalStyles.fontFamilyBody,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    suffixIcon:
                        _query.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                color: GlobalStyles.textTertiary,
                                size: GlobalStyles.iconSizeSm,
                              ),
                              onPressed: () => _onSearchChanged(''),
                            )
                            : null,
                  ),
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeBody2,
                    color: GlobalStyles.textPrimary,
                    fontFamily: GlobalStyles.fontFamilyBody,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),

            // Cache status indicator (only show when not loading and has data)
            if (!_loading && _allClaims.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.database,
                      size: GlobalStyles.iconSizeXs,
                      color: GlobalStyles.successMain,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Using cached data',
                      style: TextStyle(
                        fontSize: GlobalStyles.fontSizeCaption,
                        color: GlobalStyles.textSecondary,
                        fontFamily: GlobalStyles.fontFamilyBody,
                      ),
                    ),
                    Spacer(),
                    FutureBuilder<String>(
                      future: _getLastSyncTime(),
                      builder: (context, snapshot) {
                        return Text(
                          'Last sync: ${snapshot.data ?? 'Loading...'}',
                          style: TextStyle(
                            fontSize: GlobalStyles.fontSizeCaption,
                            color: GlobalStyles.textTertiary,
                            fontFamily: GlobalStyles.fontFamilyBody,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],

            // Sort indicator
            if (_filtered.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Icon(
                      ClaimsWidgetUtils.getSortOptionIcon(_currentSort),
                      size: GlobalStyles.iconSizeXs,
                      color: GlobalStyles.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Sorted by ${ClaimsWidgetUtils.getSortOptionLabel(_currentSort)}',
                      style: TextStyle(
                        fontSize: GlobalStyles.fontSizeCaption,
                        color: GlobalStyles.textSecondary,
                        fontFamily: GlobalStyles.fontFamilyBody,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],

            // Claims list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: GlobalStyles.primaryMain,
                child:
                    _loading && _allClaims.isEmpty
                        ? ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: 6,
                          separatorBuilder: (_, _) => SizedBox(height: 8.h),
                          itemBuilder: (context, index) => _ClaimSkeletonTile(),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                        )
                        : (_filtered.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: 100.h),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        LucideIcons.fileText,
                                        size: GlobalStyles.iconSizeXl * 1.5,
                                        color: GlobalStyles.textDisabled,
                                      ),
                                      SizedBox(
                                        height: GlobalStyles.paddingNormal,
                                      ),
                                      Text(
                                        _errorMessage ?? 'No claims found',
                                        style: TextStyle(
                                          color: GlobalStyles.textSecondary,
                                          fontSize: GlobalStyles.fontSizeBody1,
                                          fontFamily:
                                              GlobalStyles.fontFamilyBody,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_errorMessage == null &&
                                          _query.isNotEmpty) ...[
                                        SizedBox(
                                          height: GlobalStyles.spacingSm,
                                        ),
                                        Text(
                                          'Try adjusting your search',
                                          style: TextStyle(
                                            color: GlobalStyles.textTertiary,
                                            fontSize:
                                                GlobalStyles.fontSizeBody2,
                                            fontFamily:
                                                GlobalStyles.fontFamilyBody,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            )
                            : ListView.separated(
                              itemCount: _filtered.length,
                              separatorBuilder: (_, _) => SizedBox(height: 4.h),
                              itemBuilder: (context, index) {
                                final claim = _filtered[index];
                                return _buildClaimTile(claim);
                              },
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                            )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show sync information dialog (debug feature)
  // ignore: unused_element
  void _showSyncInfo() async {
    final lastSync = await _getLastSyncTime();
    final cacheSize = _allClaims.length;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sync Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cached Claims: $cacheSize'),
                Text('Last Sync: $lastSync'),
                Text(
                  'Real-time: ${_realtimeSubscription != null ? 'Active' : 'Inactive'}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }
}

class _ClaimSkeletonTile extends StatelessWidget {
  const _ClaimSkeletonTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton icon
          Container(
            height: 50.sp,
            width: 50.sp,
            decoration: BoxDecoration(
              color: GlobalStyles.textDisabled.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          // Skeleton content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _SkeletonBox(width: 180.w, height: 14.h)),
                    SizedBox(width: 8.w),
                    _SkeletonBox(width: 60.w, height: 14.h),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SkeletonBox(width: 80.w, height: 12.h),
                    _SkeletonBox(width: 80.w, height: 12.h),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBox({Key? key, required this.width, required this.height})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: GlobalStyles.textDisabled.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
      ),
    );
  }
}
