import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/services/car_company_api_service.dart';

class VehicleVerificationScreen extends StatefulWidget {
  final String? initialVin;
  final Map<String, dynamic>? assessmentData;

  const VehicleVerificationScreen({
    super.key,
    this.initialVin,
    this.assessmentData,
  });

  @override
  State<VehicleVerificationScreen> createState() =>
      _VehicleVerificationScreenState();
}

class _VehicleVerificationScreenState extends State<VehicleVerificationScreen> {
  final TextEditingController _vinController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _vehicleInfo;
  Map<String, dynamic>? _warrantyInfo;
  List<Map<String, dynamic>>? _recalls;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialVin != null) {
      _vinController.text = widget.initialVin!;
      _verifyVehicle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalStyles.buildCustomAppBar(
        context: context,
        icon: Icons.arrow_back_rounded,
        color: Colors.white,
        appBarBackgroundColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.backgroundColorStart,
              GlobalStyles.backgroundColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Verify vehicle information with manufacturer',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                SizedBox(height: 30.h),

                // VIN Input
                _buildVinInput(),
                SizedBox(height: 20.h),

                // Verify Button
                _buildVerifyButton(),
                SizedBox(height: 30.h),

                // Error Message
                if (_errorMessage != null) _buildErrorCard(),

                // Vehicle Information
                if (_vehicleInfo != null) _buildVehicleInfoCard(),

                // Warranty Information
                if (_warrantyInfo != null) _buildWarrantyCard(),

                // Recalls
                if (_recalls != null) _buildRecallsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVinInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: _vinController,
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
        decoration: InputDecoration(
          labelText: 'VIN Number',
          labelStyle: TextStyle(color: Colors.white70, fontSize: 14.sp),
          hintText: 'Enter 17-character VIN',
          hintStyle: TextStyle(color: Colors.white54, fontSize: 14.sp),
          prefixIcon: Icon(Icons.confirmation_number, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.w),
        ),
        maxLength: 17,
        textCapitalization: TextCapitalization.characters,
        onChanged: (value) {
          setState(() {
            _errorMessage = null;
          });
        },
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyVehicle,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            _isLoading ? Colors.grey.shade600 : GlobalStyles.primaryColor,
          ),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16.h)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        child:
            _isLoading
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Verifying...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : Text(
                  'Verify Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    final vehicle = _vehicleInfo!['data'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Vehicle Verified',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('VIN', vehicle['vin']),
          _buildInfoRow('Make', vehicle['make']),
          _buildInfoRow('Model', vehicle['model']),
          _buildInfoRow('Year', vehicle['year'].toString()),
          _buildInfoRow('Status', vehicle['status']),
        ],
      ),
    );
  }

  Widget _buildWarrantyCard() {
    final warranty = _warrantyInfo!['data']['warranty'];
    final isActive = warranty['status'] == 'active';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.shield : Icons.shield_outlined,
                color: isActive ? Colors.green : Colors.orange,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Warranty Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('Status', warranty['status']),
          if (warranty['type'] != null) _buildInfoRow('Type', warranty['type']),
          if (warranty['startDate'] != null)
            _buildInfoRow('Start Date', warranty['startDate']),
          if (warranty['endDate'] != null)
            _buildInfoRow('End Date', warranty['endDate']),
          if (warranty['coverage'] != null && warranty['coverage'] is List)
            _buildInfoRow(
              'Coverage',
              (warranty['coverage'] as List).join(', '),
            ),
        ],
      ),
    );
  }

  Widget _buildRecallsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _recalls!.isEmpty ? Icons.check_circle : Icons.warning,
                color: _recalls!.isEmpty ? Colors.green : Colors.orange,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Recalls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_recalls!.isEmpty)
            Text(
              'No active recalls for this vehicle',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            )
          else
            ..._recalls!.map((recall) => _buildRecallItem(recall)).toList(),
        ],
      ),
    );
  }

  Widget _buildRecallItem(Map<String, dynamic> recall) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recall['title'] ?? 'Unknown Recall',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            recall['description'] ?? '',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
          if (recall['remedy'] != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Remedy: ${recall['remedy']}',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyVehicle() async {
    final vin = _vinController.text.trim().toUpperCase();

    if (vin.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a VIN number';
      });
      return;
    }

    if (!CarCompanyApiService.isValidVin(vin)) {
      setState(() {
        _errorMessage = 'Invalid VIN format. VIN must be 17 characters long.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _vehicleInfo = null;
      _warrantyInfo = null;
      _recalls = null;
    });

    try {
      // Verify vehicle info
      final vehicleInfo = await CarCompanyApiService.verifyVehicleInfo(vin);

      // Check warranty
      final warrantyInfo = await CarCompanyApiService.checkWarranty(vin);

      // Check recalls
      final recallInfo = await CarCompanyApiService.checkRecalls(vin);

      setState(() {
        _vehicleInfo = vehicleInfo;
        _warrantyInfo = warrantyInfo;
        _recalls =
            (recallInfo['data']['recalls'] as List)
                .cast<Map<String, dynamic>>();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle verification completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }
}
