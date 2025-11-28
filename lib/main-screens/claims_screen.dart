import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:insurevis/services/claims_service.dart';
import 'package:insurevis/services/supabase_service.dart';

import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/global_ui_variables.dart';

import 'package:insurevis/main-screens/claim_details_screen.dart';

enum SortOption {
  dateNewest,
  dateOldest,
  amountHighest,
  amountLowest,
  statusAZ,
  statusZA,
  claimNumberAZ,
  claimNumberZA,
}

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

  static const String _claimsStorageKey = 'cached_claims';
  static const String _lastSyncKey = 'claims_last_sync';
  static const String _sortPreferenceKey = 'claims_sort_preference';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final sortIndex = prefs.getInt(_sortPreferenceKey) ?? 0;
      setState(() {
        _currentSort = SortOption.values[sortIndex];
      });
    } catch (e) {
      if (kDebugMode) print('Error loading sort preference: $e');
    }
  }

  /// Save sort preference to storage
  Future<void> _saveSortPreference(SortOption sort) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sortPreferenceKey, sort.index);
    } catch (e) {
      if (kDebugMode) print('Error saving sort preference: $e');
    }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_claimsStorageKey);

      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        final claims =
            jsonList.map((json) => ClaimModel.fromJson(json)).toList();

        setState(() {
          _allClaims = claims;
          _filtered = _applyFiltersAndSort();
        });

        if (kDebugMode) print('Loaded ${claims.length} claims from cache');
      }
    } catch (e) {
      if (kDebugMode) print('Error loading claims from cache: $e');
    }
  }

  /// Save claims to local storage
  Future<void> _saveToCache(List<ClaimModel> claims) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = claims.map((claim) => claim.toJson()).toList();
      await prefs.setString(_claimsStorageKey, json.encode(jsonList));
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) print('Saved ${claims.length} claims to cache');
    } catch (e) {
      if (kDebugMode) print('Error saving claims to cache: $e');
    }
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

      final claims = await ClaimsService.getUserClaims(user.id);

      // Save to cache
      await _saveToCache(claims);

      setState(() {
        _allClaims = claims;
        _filtered = _applyFiltersAndSort();
        _loading = false;
      });

      if (kDebugMode) print('Synced ${claims.length} claims from server');
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

    try {
      // Listen to changes in claims table for current user
      // Use the Supabase client (exposed by SupabaseService.client) rather
      // than the user object. Calling `.from(...)` on the user caused a
      // NoSuchMethodError at runtime.
      _realtimeSubscription = SupabaseService.client
          .from('claims')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('updated_at', ascending: false)
          .listen((List<Map<String, dynamic>> data) {
            // Real-time data received
            _handleRealtimeUpdate(data);

            // Show snackbar for new claims (only when count increases)
            // if (data.length > previousCount) {
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     SnackBar(
            //       content: Text(
            //         'New claim created',
            //         style: GoogleFonts.inter(color: Colors.white),
            //       ),
            //       backgroundColor: GlobalStyles.primaryColor,
            //       duration: Duration(seconds: 2),
            //     ),
            //   );
            // }
          });

      if (kDebugMode) print('Real-time updates enabled for claims');
    } catch (e) {
      if (kDebugMode) print('Error setting up real-time updates: $e');
    }
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
            backgroundColor: GlobalStyles.primaryColor,
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateFormat.jm().format(date);
      }
    } catch (e) {
      if (kDebugMode) print('Error getting last sync time: $e');
    }
    return 'Never';
  }

  /// Clear cache (for debugging or reset)
  // ignore: unused_element
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_claimsStorageKey);
      await prefs.remove(_lastSyncKey);

      setState(() {
        _allClaims = [];
        _filtered = [];
      });

      if (kDebugMode) print('Cache cleared');

      // Reload from server
      await _syncWithServer();
    } catch (e) {
      if (kDebugMode) print('Error clearing cache: $e');
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    await _syncWithServer();
  }

  List<ClaimModel> _applyQuery(String q, List<ClaimModel> claims) {
    final lower = q.trim().toLowerCase();
    if (lower.isEmpty) return claims;
    return claims.where((c) {
      return c.claimNumber.toLowerCase().contains(lower) ||
          c.status.toLowerCase().contains(lower) ||
          c.incidentDescription.toLowerCase().contains(lower) ||
          c.incidentLocation.toLowerCase().contains(lower);
    }).toList();
  }

  List<ClaimModel> _applySorting(List<ClaimModel> claims) {
    final sortedClaims = List<ClaimModel>.from(claims);

    switch (_currentSort) {
      case SortOption.dateNewest:
        sortedClaims.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortOption.dateOldest:
        sortedClaims.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SortOption.amountHighest:
        sortedClaims.sort(
          (a, b) => (b.estimatedDamageCost ?? 0).compareTo(
            a.estimatedDamageCost ?? 0,
          ),
        );
        break;
      case SortOption.amountLowest:
        sortedClaims.sort(
          (a, b) => (a.estimatedDamageCost ?? 0).compareTo(
            b.estimatedDamageCost ?? 0,
          ),
        );
        break;
      case SortOption.statusAZ:
        sortedClaims.sort((a, b) => a.status.compareTo(b.status));
        break;
      case SortOption.statusZA:
        sortedClaims.sort((a, b) => b.status.compareTo(a.status));
        break;
      case SortOption.claimNumberAZ:
        sortedClaims.sort((a, b) => a.claimNumber.compareTo(b.claimNumber));
        break;
      case SortOption.claimNumberZA:
        sortedClaims.sort((a, b) => b.claimNumber.compareTo(a.claimNumber));
        break;
    }

    return sortedClaims;
  }

  List<ClaimModel> _applyFiltersAndSort() {
    // First apply search query
    final queriedClaims = _applyQuery(_query, _allClaims);
    // Then apply sorting
    return _applySorting(queriedClaims);
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

  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.dateNewest:
        return 'Date (Newest)';
      case SortOption.dateOldest:
        return 'Date (Oldest)';
      case SortOption.amountHighest:
        return 'Amount (Highest)';
      case SortOption.amountLowest:
        return 'Amount (Lowest)';
      case SortOption.statusAZ:
        return 'Status (A-Z)';
      case SortOption.statusZA:
        return 'Status (Z-A)';
      case SortOption.claimNumberAZ:
        return 'Claim # (A-Z)';
      case SortOption.claimNumberZA:
        return 'Claim # (Z-A)';
    }
  }

  IconData _getSortOptionIcon(SortOption option) {
    switch (option) {
      case SortOption.dateNewest:
      case SortOption.dateOldest:
        return Icons.calendar_today_rounded;
      case SortOption.amountHighest:
      case SortOption.amountLowest:
        return Icons.attach_money_rounded;
      case SortOption.statusAZ:
      case SortOption.statusZA:
        return Icons.label_rounded;
      case SortOption.claimNumberAZ:
      case SortOption.claimNumberZA:
        return Icons.tag_rounded;
    }
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
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Title
                  Text(
                    'Sort Claims',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
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
                                      _getSortOptionIcon(option),
                                      color:
                                          _currentSort == option
                                              ? GlobalStyles.primaryColor
                                              : Color(0x992A2A2A),
                                      size: 20.sp,
                                    ),
                                    title: Text(
                                      _getSortOptionLabel(option),
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight:
                                            _currentSort == option
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                        color:
                                            _currentSort == option
                                                ? GlobalStyles.primaryColor
                                                : Color(0xFF2A2A2A),
                                      ),
                                    ),
                                    trailing:
                                        _currentSort == option
                                            ? Icon(
                                              Icons.check_rounded,
                                              color: GlobalStyles.primaryColor,
                                              size: 20.sp,
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
              buildClaimIcon: _buildClaimIcon,
              statusColor: _statusColor,
              formatStatus: _formatStatus,
              formatCurrency: _formatCurrency,
            ),
      ),
    );

    // If an updated claim is returned, the real-time subscription will handle the update
    // But we can also manually trigger a refresh to ensure immediate feedback
    if (result != null && result is ClaimModel) {
      if (kDebugMode) print('Claim updated, triggering refresh...');
      // The real-time subscription should handle this automatically,
      // but we can optionally force a sync for immediate feedback
      await _syncWithServer();
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.orange;
      case 'under review':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'appealed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.upload_rounded;
      case 'under review':
        return Icons.search_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'appealed':
        return Icons.replay_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatStatus(String status) {
    if (status.trim().isEmpty) return '';
    final parts = status.replaceAll('_', ' ').split(' ');
    final capitalized = parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
    return capitalized;
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '-';
    try {
      final f = NumberFormat.currency(
        locale: 'en_PH',
        symbol: '₱',
        decimalDigits: 2,
      );
      return f.format(amount);
    } catch (_) {
      return '₱${amount.toStringAsFixed(2)}';
    }
  }

  Widget _buildClaimIcon(String status, Color color) {
    return Container(
      height: 50.sp,
      width: 50.sp,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(_statusIcon(status), color: color, size: 25.sp),
    );
  }

  Widget _buildClaimTile(ClaimModel claim) {
    return InkWell(
      onTap: () => _showClaimDetails(claim),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            _buildClaimIcon(claim.status, _statusColor(claim.status)),
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
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _formatCurrency(claim.estimatedDamageCost),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          color: GlobalStyles.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatStatus(claim.status),
                        style: GoogleFonts.inter(
                          color: _statusColor(claim.status),
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().format(claim.createdAt),
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 12.sp,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Claims',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: Color(0xFF2A2A2A),
              size: 24.sp,
            ),
            tooltip: 'Refresh',
          ),
          SizedBox(width: 4.w),
          IconButton(
            onPressed: _showSortMenu,
            icon: Icon(
              Icons.sort_rounded,
              color: Color(0xFF2A2A2A),
              size: 24.sp,
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
                  color: Colors.black12.withAlpha((0.04 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  key: const Key('claims_search'),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Color(0x992A2A2A),
                      size: 22.sp,
                    ),
                    hintText: 'Search claims by id, status or text',
                    hintStyle: GoogleFonts.inter(
                      color: Color(0x992A2A2A),
                      fontSize: 14.sp,
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
                                Icons.clear_rounded,
                                color: Color(0x992A2A2A),
                                size: 20.sp,
                              ),
                              onPressed: () => _onSearchChanged(''),
                            )
                            : null,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Color(0xFF2A2A2A),
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
                    Icon(Icons.offline_bolt, size: 16.sp, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text(
                      'Using cached data',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    FutureBuilder<String>(
                      future: _getLastSyncTime(),
                      builder: (context, snapshot) {
                        return Text(
                          'Last sync: ${snapshot.data ?? 'Loading...'}',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.grey[500],
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
                      _getSortOptionIcon(_currentSort),
                      size: 16.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Sorted by ${_getSortOptionLabel(_currentSort)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
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
                color: GlobalStyles.primaryColor,
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
                                        Icons.description_outlined,
                                        size: 64.sp,
                                        color: Colors.grey[300],
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        _errorMessage ?? 'No claims found',
                                        style: GoogleFonts.inter(
                                          color: Colors.grey[500],
                                          fontSize: 16.sp,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_errorMessage == null &&
                                          _query.isNotEmpty) ...[
                                        SizedBox(height: 8.h),
                                        Text(
                                          'Try adjusting your search',
                                          style: GoogleFonts.inter(
                                            color: Colors.grey[400],
                                            fontSize: 14.sp,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
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
              color: Colors.grey[200],
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6.r),
      ),
    );
  }
}
