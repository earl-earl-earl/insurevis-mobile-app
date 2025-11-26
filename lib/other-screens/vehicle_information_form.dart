import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/pdf_assessment_view.dart';
import 'package:insurevis/widgets/vehicle_form.dart';

class VehicleInformationForm extends StatefulWidget {
  final List<String>? imagePaths;
  final Map<String, Map<String, dynamic>>? apiResponses;
  final Map<String, String>? assessmentIds;

  const VehicleInformationForm({
    super.key,
    this.imagePaths,
    this.apiResponses,
    this.assessmentIds,
  });

  @override
  State<VehicleInformationForm> createState() => _VehicleInformationFormState();
}

class _VehicleInformationFormState extends State<VehicleInformationForm> {
  // Vehicle information controllers
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

  @override
  void dispose() {
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    return _vehicleMakeController.text.trim().isNotEmpty &&
        _vehicleModelController.text.trim().isNotEmpty &&
        _vehicleYearController.text.trim().isNotEmpty &&
        _plateNumberController.text.trim().isNotEmpty;
  }

  void _onContinuePressed() {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all vehicle information'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create vehicle data map to pass forward
    final vehicleData = {
      'make': _vehicleMakeController.text.trim(),
      'model': _vehicleModelController.text.trim(),
      'year': _vehicleYearController.text.trim(),
      'plate_number': _plateNumberController.text.trim(),
    };

    // Navigate to PDF Assessment View with vehicle data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => PDFAssessmentView(
              imagePaths: widget.imagePaths,
              apiResponses: widget.apiResponses,
              assessmentIds: widget.assessmentIds,
              vehicleData: vehicleData,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2A2A2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Vehicle Information',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2A2A2A),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructions(),
                    SizedBox(height: 24.h),
                    _buildVehicleInformationSection(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: GlobalStyles.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Vehicle Information',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: GlobalStyles.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Please provide accurate vehicle information. This will be used for your assessment report and insurance claim.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInformationSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Details',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A2A2A),
            ),
          ),
          SizedBox(height: 16.h),
          VehicleForm(
            makeController: _vehicleMakeController,
            modelController: _vehicleModelController,
            yearController: _vehicleYearController,
            plateNumberController: _plateNumberController,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 56.h,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _onContinuePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: GlobalStyles.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue to Assessment',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward, color: Colors.white, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}
