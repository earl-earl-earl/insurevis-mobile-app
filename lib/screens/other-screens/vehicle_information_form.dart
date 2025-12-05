import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _VehicleInformationFormState extends State<VehicleInformationForm>
    with TickerProviderStateMixin {
  // Vehicle information controllers
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

  // Animation controllers
  late AnimationController _contentAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _contentFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animations
    _contentAnimationController.forward();
    Future.delayed(
      const Duration(milliseconds: 400),
      () => _buttonAnimationController.forward(),
    );
  }

  @override
  void dispose() {
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _plateNumberController.dispose();
    _contentAnimationController.dispose();
    _buttonAnimationController.dispose();
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

  void _onContinuePressed() async {
    if (!_validateForm()) {
      await HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all vehicle information'),
          backgroundColor: GlobalStyles.errorMain,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          margin: EdgeInsets.all(16.w),
        ),
      );
      return;
    }

    await HapticFeedback.heavyImpact();

    // Create vehicle data map to pass forward
    final vehicleData = VehicleFormUtils.prepareVehicleData(
      make: _vehicleMakeController.text,
      model: _vehicleModelController.text,
      year: _vehicleYearController.text,
      plateNumber: _plateNumberController.text,
    );

    // Navigate to PDF Assessment View with smooth transition
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder:
              (context, animation, secondaryAnimation) => PDFAssessmentView(
                imagePaths: widget.imagePaths,
                apiResponses: widget.apiResponses,
                assessmentIds: widget.assessmentIds,
                vehicleData: vehicleData,
              ),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) =>
                  SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic)),
                    ),
                    child: child,
                  ),
        ),
      );
    }
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
          onPressed: () async {
            await HapticFeedback.lightImpact();
            if (mounted) Navigator.pop(context);
          },
        ),
        title: FadeTransition(
          opacity: _contentFadeAnimation,
          child: Text(
            'Vehicle Information',
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeH5,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyHeading,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(GlobalStyles.paddingNormal),
                child: SlideTransition(
                  position: _contentSlideAnimation,
                  child: FadeTransition(
                    opacity: _contentFadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder:
                              (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 10),
                                  child: child,
                                ),
                              ),
                          child: _buildInstructions(),
                        ),
                        SizedBox(height: GlobalStyles.spacingLg),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder:
                              (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 10),
                                  child: child,
                                ),
                              ),
                          child: _buildVehicleInformationSection(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ScaleTransition(
              scale: _buttonScaleAnimation,
              child: _buildBottomActions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: GlobalStyles.infoMain.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: GlobalStyles.infoMain.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: GlobalStyles.infoMain.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: GlobalStyles.infoMain.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.info,
                  color: GlobalStyles.infoMain,
                  size: GlobalStyles.iconSizeSm,
                ),
              ),
              SizedBox(width: 12.w),
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
          SizedBox(height: 12.h),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: GlobalStyles.textPrimary.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: GlobalStyles.textPrimary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: GlobalStyles.textPrimary.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.car,
                  color: GlobalStyles.primaryMain,
                  size: GlobalStyles.iconSizeSm,
                ),
              ),
              SizedBox(width: 12.w),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        boxShadow: [
          BoxShadow(
            color: GlobalStyles.textPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 56.h,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [GlobalStyles.primaryMain, GlobalStyles.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: GlobalStyles.primaryMain.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onContinuePressed,
              borderRadius: BorderRadius.circular(12.r),
              splashColor: GlobalStyles.surfaceMain.withValues(alpha: 0.1),
              highlightColor: GlobalStyles.surfaceMain.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue to Assessment',
                    style: TextStyle(
                      fontSize: GlobalStyles.fontSizeButton,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                      fontFamily: GlobalStyles.fontFamilyBody,
                      letterSpacing: GlobalStyles.letterSpacingButton,
                      color: GlobalStyles.surfaceMain,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Icon(
                    LucideIcons.arrowRight,
                    size: GlobalStyles.iconSizeSm,
                    color: GlobalStyles.surfaceMain,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
