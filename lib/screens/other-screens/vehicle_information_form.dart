import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/screens/other-screens/pdf_assessment_view.dart';
import 'package:insurevis/widgets/vehicle_form.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/utils/vehicle_form_utils.dart';

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
    return VehicleFormUtils.isFormComplete(
      make: _vehicleMakeController.text,
      model: _vehicleModelController.text,
      year: _vehicleYearController.text,
      plateNumber: _plateNumberController.text,
    );
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
    final vehicleData = VehicleFormUtils.prepareVehicleData(
      make: _vehicleMakeController.text,
      model: _vehicleModelController.text,
      year: _vehicleYearController.text,
      plateNumber: _plateNumberController.text,
    );

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
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: AppBar(
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
          'Vehicle Information',
          style: TextStyle(
            fontSize: GlobalStyles.fontSizeH5,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            color: GlobalStyles.textPrimary,
            fontFamily: GlobalStyles.fontFamilyHeading,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(GlobalStyles.paddingNormal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructions(),
                    SizedBox(height: GlobalStyles.spacingLg),
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
      padding: GlobalStyles.cardPadding,
      decoration: BoxDecoration(
        color: GlobalStyles.infoMain.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GlobalStyles.cardBorderRadius),
        border: Border.all(
          color: GlobalStyles.infoMain.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.info,
                color: GlobalStyles.infoMain,
                size: GlobalStyles.iconSizeMd,
              ),
              SizedBox(width: GlobalStyles.spacingMd),
              Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: GlobalStyles.fontSizeH6,
                  fontWeight: GlobalStyles.fontWeightSemiBold,
                  color: GlobalStyles.infoMain,
                  fontFamily: GlobalStyles.fontFamilyHeading,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            'Please provide accurate vehicle information. This will be used for your assessment report and insurance claim.',
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textTertiary,
              height: 1.5,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInformationSection() {
    return Container(
      padding: GlobalStyles.cardPadding,
      decoration: BoxDecoration(
        color: GlobalStyles.cardBackground,
        borderRadius: BorderRadius.circular(GlobalStyles.cardBorderRadius),
        boxShadow: [GlobalStyles.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.car,
                color: GlobalStyles.primaryMain,
                size: GlobalStyles.iconSizeSm,
              ),
              SizedBox(width: GlobalStyles.spacingSm),
              Text(
                'Vehicle Details',
                style: TextStyle(
                  fontSize: GlobalStyles.fontSizeH5,
                  fontWeight: GlobalStyles.fontWeightSemiBold,
                  color: GlobalStyles.textPrimary,
                  fontFamily: GlobalStyles.fontFamilyHeading,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingMd),
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
      padding: EdgeInsets.all(GlobalStyles.paddingNormal),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        boxShadow: [GlobalStyles.shadowMd],
      ),
      child: SizedBox(
        height: 56.h,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _onContinuePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: GlobalStyles.primaryMain,
            foregroundColor: GlobalStyles.surfaceMain,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.buttonBorderRadius,
              ),
            ),
            elevation: 0,
            shadowColor: GlobalStyles.buttonShadow.color,
            padding: GlobalStyles.buttonPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue to Assessment',
                style: TextStyle(
                  fontSize: GlobalStyles.fontSizeButton,
                  fontWeight: GlobalStyles.fontWeightMedium,
                  fontFamily: GlobalStyles.fontFamilyBody,
                  letterSpacing: GlobalStyles.letterSpacingButton,
                ),
              ),
              SizedBox(width: GlobalStyles.spacingSm),
              Icon(LucideIcons.arrowRight, size: GlobalStyles.iconSizeSm),
            ],
          ),
        ),
      ),
    );
  }
}
