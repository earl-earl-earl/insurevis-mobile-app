import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/services/car_brands_repository.dart';
import 'package:insurevis/other-screens/pdf_assessment_view.dart';

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

  // Car brands and models data from API
  List<Map<String, dynamic>> _carBrandsData = [];
  bool _isLoadingBrands = false;

  // Selected values for dropdowns
  String? _selectedMake;
  String? _selectedModel;
  bool _isMakeOthers = false;
  bool _isModelOthers = false;

  // Available models for selected make
  List<Map<String, dynamic>> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _fetchCarBrands();
  }

  @override
  void dispose() {
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  /// Fetches car brands data from the repository (which handles caching)
  Future<void> _fetchCarBrands() async {
    setState(() {
      _isLoadingBrands = true;
    });

    try {
      // Ensure repository is initialized (safe to call multiple times)
      await CarBrandsRepository.instance.init();

      // Get the cached brands data from repository
      final brandsData = CarBrandsRepository.instance.brands;

      if (brandsData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No car brands data available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isLoadingBrands = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _carBrandsData = brandsData;
          _isLoadingBrands = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load car brands: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingBrands = false;
        });
      }
      debugPrint('Error loading car brands from repository: $e');
    }
  }

  /// Updates available models when a make is selected
  void _onMakeSelected(String? make) {
    setState(() {
      _selectedMake = make;
      _isMakeOthers = make == 'Others';

      if (_isMakeOthers) {
        _vehicleMakeController.clear();
        _availableModels = [];
      } else if (make != null) {
        _vehicleMakeController.text = make;
        final selectedBrandData = _carBrandsData.firstWhere(
          (brand) => (brand['brand'] ?? brand['name']) == make,
          orElse: () => <String, dynamic>{},
        );

        if (selectedBrandData.isNotEmpty &&
            selectedBrandData['models'] is List) {
          _availableModels =
              (selectedBrandData['models'] as List)
                  .cast<Map<String, dynamic>>();
        } else {
          _availableModels = [];
        }
      }

      // Reset model and year when make changes
      _selectedModel = null;
      _isModelOthers = false;
      _vehicleModelController.clear();
      _vehicleYearController.clear();
    });
  }

  /// Updates year when a model is selected
  void _onModelSelected(String? model) {
    setState(() {
      _selectedModel = model;
      _isModelOthers = model == 'Others';

      if (_isModelOthers) {
        _vehicleModelController.clear();
        _vehicleYearController.clear();
      } else if (model != null) {
        _vehicleModelController.text = model;
        final selectedModelData = _availableModels.firstWhere(
          (m) => (m['model'] ?? m['model_name']) == model,
          orElse: () => <String, dynamic>{},
        );

        if (selectedModelData.isNotEmpty) {
          final year = selectedModelData['year']?.toString() ?? '';
          _vehicleYearController.text = year;
        }
      } else {
        _vehicleYearController.clear();
      }
    });
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
          _buildVehicleMakeDropdown(),
          SizedBox(height: 16.h),
          _buildVehicleModelDropdown(),
          SizedBox(height: 16.h),
          _buildVehicleYearField(),
          SizedBox(height: 16.h),
          _buildVehicleInputField(
            controller: _plateNumberController,
            label: 'Plate Number',
            hint: 'Enter vehicle plate number',
            icon: Icons.credit_card,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2A2A),
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Color(0xFF999999),
            ),
            prefixIcon: Icon(icon, color: GlobalStyles.primaryColor),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor,
                width: 2,
              ),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleMakeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Make',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2A2A),
          ),
        ),
        SizedBox(height: 8.h),
        if (_isLoadingBrands)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: GlobalStyles.primaryColor,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Loading car brands...',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedMake,
            hint: Text(
              'Select vehicle make',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Color(0xFF999999),
              ),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.directions_car,
                color: GlobalStyles.primaryColor,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.primaryColor,
                  width: 2,
                ),
              ),
            ),
            items: [
              ..._carBrandsData
                  .where(
                    (brand) => brand['brand'] != null || brand['name'] != null,
                  )
                  .map((brand) {
                    final brandName =
                        (brand['brand'] ?? brand['name']).toString();
                    return DropdownMenuItem<String>(
                      value: brandName,
                      child: Text(brandName),
                    );
                  })
                  .toList(),
              DropdownMenuItem<String>(value: 'Others', child: Text('Others')),
            ],
            onChanged: _onMakeSelected,
          ),
        if (_isMakeOthers) ...[
          SizedBox(height: 12.h),
          TextField(
            controller: _vehicleMakeController,
            decoration: InputDecoration(
              hintText: 'Enter vehicle make',
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Color(0xFF999999),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVehicleModelDropdown() {
    final bool isDisabled = _selectedMake == null || _isMakeOthers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Model',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2A2A),
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: _selectedModel,
          hint: Text(
            isDisabled ? 'Select make first' : 'Select vehicle model',
            style: GoogleFonts.inter(fontSize: 14.sp, color: Color(0xFF999999)),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.car_crash, color: GlobalStyles.primaryColor),
            filled: true,
            fillColor: isDisabled ? Colors.grey.shade200 : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor,
                width: 2,
              ),
            ),
          ),
          items:
              isDisabled
                  ? []
                  : [
                    ..._availableModels
                        .where(
                          (model) =>
                              model['model'] != null ||
                              model['model_name'] != null,
                        )
                        .map((model) {
                          final modelName =
                              (model['model'] ?? model['model_name'])
                                  .toString();
                          return DropdownMenuItem<String>(
                            value: modelName,
                            child: Text(modelName),
                          );
                        })
                        .toList(),
                    DropdownMenuItem<String>(
                      value: 'Others',
                      child: Text('Others'),
                    ),
                  ],
          onChanged: isDisabled ? null : _onModelSelected,
        ),
        if (_isModelOthers) ...[
          SizedBox(height: 12.h),
          TextField(
            controller: _vehicleModelController,
            decoration: InputDecoration(
              hintText: 'Enter vehicle model',
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Color(0xFF999999),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVehicleYearField() {
    final bool isDisabled =
        (_selectedMake == null || _selectedModel == null) &&
        !(_isMakeOthers || _isModelOthers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Year',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2A2A2A),
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _vehicleYearController,
          enabled: !isDisabled,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: InputDecoration(
            hintText: isDisabled ? 'Select model first' : 'Enter vehicle year',
            hintStyle: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Color(0xFF999999),
            ),
            prefixIcon: Icon(
              Icons.calendar_today,
              color: GlobalStyles.primaryColor,
            ),
            filled: true,
            fillColor: isDisabled ? Colors.grey.shade200 : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor,
                width: 2,
              ),
            ),
            counterText: '',
          ),
        ),
      ],
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
