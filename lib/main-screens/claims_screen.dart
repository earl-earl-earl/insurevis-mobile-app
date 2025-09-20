import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:insurevis/services/claims_service.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/global_ui_variables.dart';

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

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_allClaims);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadClaims());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    await _loadClaims();
  }

  List<ClaimModel> _applyQuery(String q) {
    final lower = q.trim().toLowerCase();
    if (lower.isEmpty) return List.from(_allClaims);
    return _allClaims.where((c) {
      return c.claimNumber.toLowerCase().contains(lower) ||
          c.status.toLowerCase().contains(lower) ||
          c.incidentDescription.toLowerCase().contains(lower) ||
          c.incidentLocation.toLowerCase().contains(lower);
    }).toList();
  }

  void _onSearchChanged(String q) {
    setState(() {
      _query = q;
      _filtered = _applyQuery(q);
    });
  }

  void _showClaimDetails(ClaimModel claim) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => SizedBox(
            height: 600.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
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

                    // Header with icon and claim number
                    Row(
                      children: [
                        _buildClaimIcon(
                          claim.status,
                          _statusColor(claim.status),
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
                                  color: _statusColor(
                                    claim.status,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  _formatStatus(claim.status),
                                  style: GoogleFonts.inter(
                                    color: _statusColor(claim.status),
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
                        color: GlobalStyles.primaryColor.withValues(
                          alpha: 0.05,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: GlobalStyles.primaryColor.withValues(
                            alpha: 0.1,
                          ),
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
                            _formatCurrency(claim.estimatedDamageCost),
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

                    // Details section
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              claim.vehiclePlateNumber ?? "N/A",
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
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
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

  Future<void> _loadClaims() async {
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
      setState(() {
        _allClaims = claims;
        _filtered = _applyQuery(_query);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load claims. Please try again.';
      });
      if (kDebugMode) print('Load claims error: $e');
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
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.note_add_rounded),
            color: GlobalStyles.primaryColor,
            tooltip: 'Create Claim',
            onPressed: () {
              Navigator.pushNamed(context, '/claim_create');
            },
          ),
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

            // Claims list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: GlobalStyles.primaryColor,
                child:
                    _loading
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
