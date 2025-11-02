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
import 'package:insurevis/services/storage_service.dart';
import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/services/download_service.dart';
import 'package:insurevis/widgets/image_viewer_page.dart';
import 'package:insurevis/widgets/pdf_viewer_page.dart';
import 'package:path/path.dart' as p;

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
        sortedClaims.sort((a, b) => b.incidentDate.compareTo(a.incidentDate));
        break;
      case SortOption.dateOldest:
        sortedClaims.sort((a, b) => a.incidentDate.compareTo(b.incidentDate));
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

  void _showClaimDetails(ClaimModel claim) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ClaimDetailsPage(
              claim: claim,
              buildClaimIcon: _buildClaimIcon,
              statusColor: _statusColor,
              formatStatus: _formatStatus,
              formatCurrency: _formatCurrency,
            ),
      ),
    );
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
                        DateFormat.yMMMd().format(claim.incidentDate),
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
          SizedBox(width: 4.w),
          IconButton(
            icon: Icon(Icons.note_add_rounded),
            color: GlobalStyles.primaryColor,
            tooltip: 'Create Claim',
            onPressed: () {
              Navigator.pushNamed(context, '/claim_create');
            },
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
                          separatorBuilder: (_, __) => SizedBox(height: 8.h),
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
                              separatorBuilder:
                                  (_, __) => SizedBox(height: 4.h),
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

class _ClaimDocumentsCacheEntry {
  final List<DocumentModel> documents;
  final Map<String, String?> signedUrls;
  final DateTime fetchedAt;

  _ClaimDocumentsCacheEntry({
    required this.documents,
    required this.signedUrls,
    required this.fetchedAt,
  });
}

class _ClaimDocumentsCache {
  static final Map<String, _ClaimDocumentsCacheEntry> _store = {};

  static _ClaimDocumentsCacheEntry? get(String claimId) => _store[claimId];

  static void set(
    String claimId, {
    required List<DocumentModel> documents,
    required Map<String, String?> signedUrls,
  }) {
    _store[claimId] = _ClaimDocumentsCacheEntry(
      documents: List.unmodifiable(documents),
      signedUrls: Map.unmodifiable(signedUrls),
      fetchedAt: DateTime.now(),
    );
  }
}

class _ClaimDetailsSheet extends StatefulWidget {
  final ClaimModel claim;
  final Widget Function(String status, Color color) buildClaimIcon;
  final Color Function(String status) statusColor;
  final String Function(String status) formatStatus;
  final String Function(double? amount) formatCurrency;

  const _ClaimDetailsSheet({
    required this.claim,
    required this.buildClaimIcon,
    required this.statusColor,
    required this.formatStatus,
    required this.formatCurrency,
  });

  @override
  State<_ClaimDetailsSheet> createState() => _ClaimDetailsSheetState();
}

class _ClaimDetailsSheetState extends State<_ClaimDetailsSheet> {
  final StorageService _storage = StorageService();
  final DownloadService _downloader = DownloadService();
  List<DocumentModel> _documents = [];
  bool _loadingDocs = false;
  String? _docError;
  final Map<String, String?> _signedUrls = {}; // docId -> url
  final Map<String, double> _progress = {}; // docId -> 0..1
  static const Duration _cacheTtl = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loadingDocs = true;
      _docError = null;
    });
    try {
      // Try cache first
      final cached = _ClaimDocumentsCache.get(widget.claim.id);
      if (cached != null &&
          DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
        _documents = cached.documents;
        _signedUrls
          ..clear()
          ..addAll(cached.signedUrls);
        setState(() {
          _loadingDocs = false;
        });
        return;
      }

      final data = await SupabaseService.client
          .from('documents')
          .select('*')
          .eq('claim_id', widget.claim.id)
          .order('created_at', ascending: false);

      final docs =
          (data as List)
              .map((j) => DocumentModel.fromJson(j as Map<String, dynamic>))
              .toList();

      // Preload signed URLs for display/download
      for (final d in docs) {
        if (d.storagePath != null && d.storagePath!.isNotEmpty) {
          final url = await _storage.getSignedUrl(
            d.storagePath!,
            expiresIn: 3600,
          );
          _signedUrls[d.id] = url;
        } else if (d.remoteUrl != null) {
          _signedUrls[d.id] = d.remoteUrl;
        } else {
          _signedUrls[d.id] = null;
        }
      }

      setState(() {
        _documents = docs;
        _loadingDocs = false;
      });

      // Save to cache
      _ClaimDocumentsCache.set(
        widget.claim.id,
        documents: docs,
        signedUrls: Map<String, String?>.from(_signedUrls),
      );
    } catch (e) {
      setState(() {
        _docError = 'Failed to load documents';
        _loadingDocs = false;
      });
      if (kDebugMode) print('Error loading documents: $e');
    }
  }

  bool _isPdf(DocumentModel doc) {
    final name = doc.fileName.toLowerCase();
    if (name.endsWith('.pdf')) return true;
    final fmt = doc.format?.toLowerCase();
    return fmt == 'pdf';
  }

  bool _isImage(DocumentModel doc) {
    final name = doc.fileName.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
  }

  Future<void> _download(DocumentModel doc) async {
    final url = _signedUrls[doc.id];
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No download URL available for ${doc.fileName}'),
          ),
        );
      }
      return;
    }

    setState(() {
      _progress[doc.id] = 0.0;
    });

    try {
      await _downloader.ensurePermissions();
      final savedPath = await _downloader.downloadForViewing(
        url: url,
        fileName: doc.fileName,
        onProgress: (received, total) {
          if (total > 0) {
            final value = received / total;
            if (mounted) setState(() => _progress[doc.id] = value);
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to $savedPath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _progress.remove(doc.id));
    }
  }

  Future<void> _openPdf(DocumentModel doc) async {
    final url = _signedUrls[doc.id];
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No URL available to open ${doc.fileName}')),
        );
      }
      return;
    }

    setState(() {
      _progress[doc.id] = 0.0;
    });

    try {
      await _downloader.ensurePermissions();
      final fileName =
          doc.fileName.toLowerCase().endsWith('.pdf')
              ? doc.fileName
              : p.setExtension(doc.fileName, '.pdf');
      final savedPath = await _downloader.downloadForViewing(
        url: url,
        fileName: fileName,
        onProgress: (received, total) {
          if (total > 0) {
            final value = received / total;
            if (mounted) setState(() => _progress[doc.id] = value);
          }
        },
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => PdfViewerPage(
                filePath: savedPath,
                title: doc.type.displayName,
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _progress.remove(doc.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final claim = widget.claim;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  // Header with icon and claim number
                  Row(
                    children: [
                      widget.buildClaimIcon(
                        claim.status,
                        widget.statusColor(claim.status),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              claim.claimNumber,
                              style: GoogleFonts.inter(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: widget
                                    .statusColor(claim.status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                widget.formatStatus(claim.status),
                                style: GoogleFonts.inter(
                                  color: widget.statusColor(claim.status),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Amount section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: GlobalStyles.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: GlobalStyles.primaryColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Damage Cost',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.formatCurrency(claim.estimatedDamageCost),
                          style: GoogleFonts.inter(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: GlobalStyles.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Details
                  _buildDetailRow(
                    'Incident Date',
                    DateFormat.yMMMd().format(claim.incidentDate),
                  ),
                  _buildDetailRow('Location', claim.incidentLocation),
                  _buildDetailRow(
                    'Vehicle',
                    '${claim.vehicleMake} ${claim.vehicleModel} (${claim.vehicleYear})',
                  ),
                  _buildDetailRow(
                    'Plate Number',
                    claim.vehiclePlateNumber ?? 'N/A',
                  ),
                  SizedBox(height: 16.h),

                  Text(
                    'Description',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      claim.incidentDescription,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Documents section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Documents',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_loadingDocs)
                        SizedBox(
                          height: 18.sp,
                          width: 18.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GlobalStyles.primaryColor,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  if (_docError != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _docError!,
                        style: GoogleFonts.inter(
                          color: Colors.red[700],
                          fontSize: 13.sp,
                        ),
                      ),
                    )
                  else if (_documents.isEmpty && !_loadingDocs)
                    Text(
                      'No documents uploaded for this claim yet.',
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    )
                  else
                    Column(
                      children:
                          _documents.map((doc) {
                            final url = _signedUrls[doc.id];
                            if (_isPdf(doc)) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 10.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: Colors.red[600],
                                      size: 22.sp,
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doc.type.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            doc.fileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_progress[doc.id] != null)
                                      SizedBox(
                                        width: 24.sp,
                                        height: 24.sp,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: (_progress[doc.id] ?? 0),
                                          color: GlobalStyles.primaryColor,
                                        ),
                                      )
                                    else
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Open',
                                            onPressed:
                                                url == null
                                                    ? null
                                                    : () => _openPdf(doc),
                                            icon: Icon(
                                              Icons.open_in_new_rounded,
                                              color: Colors.blueGrey,
                                              size: 22.sp,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Download',
                                            onPressed:
                                                url == null
                                                    ? null
                                                    : () => _download(doc),
                                            icon: Icon(
                                              Icons.download_rounded,
                                              color: GlobalStyles.primaryColor,
                                              size: 22.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            } else if (_isImage(doc) && url != null) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[200]!),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ImageViewerPage(
                                                  imageUrl: url,
                                                  title: doc.type.displayName,
                                                ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(12.r),
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => Container(
                                                  color: Colors.grey[200],
                                                  child: Center(
                                                    child: Icon(
                                                      Icons
                                                          .image_not_supported_rounded,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 8.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doc.type.displayName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  doc.fileName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_progress[doc.id] != null)
                                            SizedBox(
                                              width: 24.sp,
                                              height: 24.sp,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value: (_progress[doc.id] ?? 0),
                                                color:
                                                    GlobalStyles.primaryColor,
                                              ),
                                            )
                                          else
                                            IconButton(
                                              tooltip: 'Download',
                                              onPressed: () => _download(doc),
                                              icon: Icon(
                                                Icons.download_rounded,
                                                color:
                                                    GlobalStyles.primaryColor,
                                                size: 22.sp,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Fallback generic file row
                              return Container(
                                margin: EdgeInsets.only(bottom: 10.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file_rounded,
                                      color: Colors.grey[700],
                                      size: 22.sp,
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doc.type.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            doc.fileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Download',
                                      onPressed:
                                          _signedUrls[doc.id] == null
                                              ? null
                                              : () => _download(doc),
                                      icon: Icon(
                                        Icons.download_rounded,
                                        color: GlobalStyles.primaryColor,
                                        size: 22.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }).toList(),
                    ),

                  SizedBox(height: 20.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalStyles.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
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

/// New full screen page replacement for the bottom sheet
class ClaimDetailsPage extends StatefulWidget {
  final ClaimModel claim;
  final Widget Function(String status, Color color) buildClaimIcon;
  final Color Function(String status) statusColor;
  final String Function(String status) formatStatus;
  final String Function(double? amount) formatCurrency;

  const ClaimDetailsPage({
    super.key,
    required this.claim,
    required this.buildClaimIcon,
    required this.statusColor,
    required this.formatStatus,
    required this.formatCurrency,
  });

  @override
  State<ClaimDetailsPage> createState() => _ClaimDetailsPageState();
}

class _ClaimDetailsPageState extends State<ClaimDetailsPage> {
  // Reuse the logic by delegating to the existing sheet state fields/methods
  final StorageService _storage = StorageService();
  final DownloadService _downloader = DownloadService();
  List<DocumentModel> _documents = [];
  bool _loadingDocs = false;
  String? _docError;
  final Map<String, String?> _signedUrls = {}; // docId -> url
  final Map<String, double> _progress = {}; // docId -> 0..1
  static const Duration _cacheTtl = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loadingDocs = true;
      _docError = null;
    });
    try {
      // Try cache first
      final cached = _ClaimDocumentsCache.get(widget.claim.id);
      if (cached != null &&
          DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
        _documents = cached.documents;
        _signedUrls
          ..clear()
          ..addAll(cached.signedUrls);
        setState(() {
          _loadingDocs = false;
        });
        return;
      }

      final data = await SupabaseService.client
          .from('documents')
          .select('*')
          .eq('claim_id', widget.claim.id)
          .order('created_at', ascending: false);

      final docs =
          (data as List)
              .map((j) => DocumentModel.fromJson(j as Map<String, dynamic>))
              .toList();

      // Preload signed URLs for display/download
      for (final d in docs) {
        if (d.storagePath != null && d.storagePath!.isNotEmpty) {
          final url = await _storage.getSignedUrl(
            d.storagePath!,
            expiresIn: 3600,
          );
          _signedUrls[d.id] = url;
        } else if (d.remoteUrl != null) {
          _signedUrls[d.id] = d.remoteUrl;
        } else {
          _signedUrls[d.id] = null;
        }
      }

      setState(() {
        _documents = docs;
        _loadingDocs = false;
      });

      // Save to cache
      _ClaimDocumentsCache.set(
        widget.claim.id,
        documents: docs,
        signedUrls: Map<String, String?>.from(_signedUrls),
      );
    } catch (e) {
      setState(() {
        _docError = 'Failed to load documents';
        _loadingDocs = false;
      });
      if (kDebugMode) print('Error loading documents: $e');
    }
  }

  bool _isPdf(DocumentModel doc) {
    final name = doc.fileName.toLowerCase();
    if (name.endsWith('.pdf')) return true;
    final fmt = doc.format?.toLowerCase();
    return fmt == 'pdf';
  }

  bool _isImage(DocumentModel doc) {
    final name = doc.fileName.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
  }

  Future<void> _download(DocumentModel doc) async {
    final url = _signedUrls[doc.id];
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No download URL available for ${doc.fileName}'),
          ),
        );
      }
      return;
    }

    setState(() {
      _progress[doc.id] = 0.0;
    });

    try {
      await _downloader.ensurePermissions();
      final savedPath = await _downloader.downloadForViewing(
        url: url,
        fileName: doc.fileName,
        onProgress: (received, total) {
          if (total > 0) {
            final value = received / total;
            if (mounted) {
              setState(() => _progress[doc.id] = value);
            }
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to $savedPath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _progress.remove(doc.id));
      }
    }
  }

  Future<void> _openPdf(DocumentModel doc) async {
    final url = _signedUrls[doc.id];
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No URL available to open ${doc.fileName}')),
        );
      }
      return;
    }

    setState(() {
      _progress[doc.id] = 0.0;
    });

    try {
      await _downloader.ensurePermissions();
      final fileName =
          doc.fileName.toLowerCase().endsWith('.pdf')
              ? doc.fileName
              : '${doc.fileName}.pdf';
      final savedPath = await _downloader.downloadForViewing(
        url: url,
        fileName: fileName,
        onProgress: (received, total) {
          if (total > 0) {
            final value = received / total;
            if (mounted) {
              setState(() => _progress[doc.id] = value);
            }
          }
        },
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => PdfViewerPage(
                filePath: savedPath,
                title: doc.type.displayName,
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _progress.remove(doc.id));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final claim = widget.claim;
    return Scaffold(
      appBar: AppBar(title: Text('Claim Details')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed header card with claim id, status and estimated cost
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.buildClaimIcon(
                          claim.status,
                          widget.statusColor(claim.status),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                claim.claimNumber,
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: widget
                                      .statusColor(claim.status)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  widget.formatStatus(claim.status),
                                  style: GoogleFonts.inter(
                                    color: widget.statusColor(claim.status),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Estimated Cost section (outside the claim ID box)
                  Text(
                    'Estimated Cost',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: GlobalStyles.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: GlobalStyles.primaryColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.formatCurrency(claim.estimatedDamageCost),
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: GlobalStyles.primaryColor,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Details
                  _buildDetailRow(
                    'Incident Date',
                    DateFormat.yMMMd().format(claim.incidentDate),
                  ),
                  _buildDetailRow('Location', claim.incidentLocation),
                  _buildDetailRow(
                    'Vehicle',
                    '${claim.vehicleMake} ${claim.vehicleModel} (${claim.vehicleYear})',
                  ),
                  _buildDetailRow(
                    'Plate Number',
                    claim.vehiclePlateNumber ?? 'N/A',
                  ),

                  SizedBox(height: 12.h),
                  Text(
                    'Description',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      claim.incidentDescription,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Notes section
                  if ((claim.carCompanyApprovalNotes != null &&
                          claim.carCompanyApprovalNotes!.trim().isNotEmpty) ||
                      (claim.insuranceCompanyApprovalNotes != null &&
                          claim.insuranceCompanyApprovalNotes!
                              .trim()
                              .isNotEmpty)) ...[
                    Text(
                      'Rejection Notes',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.red[200]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18.sp,
                                color: Colors.red[700],
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                claim.carCompanyApprovalNotes != null &&
                                        claim.carCompanyApprovalNotes!
                                            .trim()
                                            .isNotEmpty
                                    ? 'Car Company Rejection'
                                    : 'Insurance Company Rejection',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            claim.carCompanyApprovalNotes?.trim().isNotEmpty ==
                                    true
                                ? claim.carCompanyApprovalNotes!
                                : claim.insuranceCompanyApprovalNotes ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Documents header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Documents',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_loadingDocs)
                        SizedBox(
                          height: 18.sp,
                          width: 18.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GlobalStyles.primaryColor,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  if (_docError != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _docError!,
                        style: GoogleFonts.inter(
                          color: Colors.red[700],
                          fontSize: 13.sp,
                        ),
                      ),
                    )
                  else if (_documents.isEmpty && !_loadingDocs)
                    Text(
                      'No documents uploaded for this claim yet.',
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Documents list
          if (_documents.isNotEmpty)
            SliverList.builder(
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                final url = _signedUrls[doc.id];
                if (_isPdf(doc)) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.red[600],
                            size: 22.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.type.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  doc.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_progress[doc.id] != null)
                            SizedBox(
                              width: 24.sp,
                              height: 24.sp,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: (_progress[doc.id] ?? 0),
                                color: GlobalStyles.primaryColor,
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Open',
                                  onPressed:
                                      url == null ? null : () => _openPdf(doc),
                                  icon: Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.blueGrey,
                                    size: 22.sp,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Download',
                                  onPressed:
                                      url == null ? null : () => _download(doc),
                                  icon: Icon(
                                    Icons.download_rounded,
                                    color: GlobalStyles.primaryColor,
                                    size: 22.sp,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                } else if (_isImage(doc) && url != null) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => ImageViewerPage(
                                        imageUrl: url,
                                        title: doc.type.displayName,
                                      ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12.r),
                              ),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported_rounded,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.type.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        doc.fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_progress[doc.id] != null)
                                  SizedBox(
                                    width: 24.sp,
                                    height: 24.sp,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: (_progress[doc.id] ?? 0),
                                      color: GlobalStyles.primaryColor,
                                    ),
                                  )
                                else
                                  IconButton(
                                    tooltip: 'Download',
                                    onPressed: () => _download(doc),
                                    icon: Icon(
                                      Icons.download_rounded,
                                      color: GlobalStyles.primaryColor,
                                      size: 22.sp,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file_rounded,
                            color: Colors.grey[700],
                            size: 22.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.type.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  doc.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Download',
                            onPressed:
                                _signedUrls[doc.id] == null
                                    ? null
                                    : () => _download(doc),
                            icon: Icon(
                              Icons.download_rounded,
                              color: GlobalStyles.primaryColor,
                              size: 22.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
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
