import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/services/car_brands_repository.dart';

class VehicleForm extends StatefulWidget {
  final TextEditingController makeController;
  final TextEditingController modelController;
  final TextEditingController yearController;
  final TextEditingController plateNumberController;

  const VehicleForm({
    super.key,
    required this.makeController,
    required this.modelController,
    required this.yearController,
    required this.plateNumberController,
  });

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
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

      if (mounted) {
        setState(() {
          _carBrandsData = brandsData;
          _isLoadingBrands = false;
        });
        _initializeSelections();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBrands = false;
        });
      }
      debugPrint('Error loading car brands from repository: $e');
    }
  }

  void _initializeSelections() {
    // Initialize Make
    final currentMake = widget.makeController.text.trim();
    if (currentMake.isNotEmpty) {
      final brandExists = _carBrandsData.any(
        (brand) => (brand['brand'] ?? brand['name']) == currentMake,
      );
      if (brandExists) {
        _onMakeSelected(currentMake, updateController: false);
      } else {
        _onMakeSelected('Others', updateController: false);
        widget.makeController.text = currentMake; // Restore text for 'Others'
      }
    }

    // Initialize Model
    final currentModel = widget.modelController.text.trim();
    if (currentModel.isNotEmpty && _selectedMake != null && !_isMakeOthers) {
      final modelExists = _availableModels.any(
        (model) => (model['model'] ?? model['model_name']) == currentModel,
      );
      if (modelExists) {
        _onModelSelected(currentModel, updateController: false);
      } else {
        _onModelSelected('Others', updateController: false);
        widget.modelController.text = currentModel; // Restore text for 'Others'
      }
    } else if (currentModel.isNotEmpty && _isMakeOthers) {
      // If make is others, model is free text, so just ensure state reflects that if needed
      // But we don't have a dropdown for model if make is others (based on original code logic? let's check)
      // Original code: if _isMakeOthers, _availableModels = [].
      // So model dropdown is empty or disabled?
      // Let's check _buildVehicleModelDropdown logic.
    }
  }

  /// Updates available models when a make is selected
  void _onMakeSelected(String? make, {bool updateController = true}) {
    setState(() {
      _selectedMake = make;
      _isMakeOthers = make == 'Others';

      if (_isMakeOthers) {
        if (updateController) widget.makeController.clear();
        _availableModels = [];
      } else if (make != null) {
        if (updateController) widget.makeController.text = make;
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

      // Reset model and year when make changes, unless we are initializing
      if (updateController) {
        _selectedModel = null;
        _isModelOthers = false;
        widget.modelController.clear();
        widget.yearController.clear();
      }
    });
  }

  /// Updates year when a model is selected
  void _onModelSelected(String? model, {bool updateController = true}) {
    setState(() {
      _selectedModel = model;
      _isModelOthers = model == 'Others';

      if (_isModelOthers) {
        if (updateController) {
          widget.modelController.clear();
          widget.yearController.clear();
        }
      } else if (model != null) {
        if (updateController) widget.modelController.text = model;

        if (updateController) {
          final selectedModelData = _availableModels.firstWhere(
            (m) => (m['model'] ?? m['model_name']) == model,
            orElse: () => <String, dynamic>{},
          );

          if (selectedModelData.isNotEmpty) {
            final year = selectedModelData['year']?.toString() ?? '';
            widget.yearController.text = year;
          }
        }
      } else {
        if (updateController) widget.yearController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVehicleMakeDropdown(),
        SizedBox(height: 16.h),
        _buildVehicleModelDropdown(),
        SizedBox(height: 16.h),
        _buildVehicleYearField(),
        SizedBox(height: 16.h),
        _buildVehicleInputField(
          controller: widget.plateNumberController,
          label: 'Plate Number',
          hint: 'Enter vehicle plate number',
          icon: Icons.credit_card,
        ),
      ],
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
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15.sp,
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: GlobalStyles.primaryColor.withOpacity(0.7),
              size: 20.sp,
            ),
            filled: true,
            fillColor: Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 18.h,
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
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            'Vehicle Make',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (_isLoadingBrands)
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: GlobalStyles.primaryColor,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Loading car brands...',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
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
                fontSize: 15.sp,
                color: Color(0xFFAAAAAA),
                fontWeight: FontWeight.w400,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.directions_car,
                color: GlobalStyles.primaryColor.withOpacity(0.7),
                size: 20.sp,
              ),
              filled: true,
              fillColor: Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: GlobalStyles.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 18.h,
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
                      child: Text(
                        brandName,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  })
                  .toList(),
              DropdownMenuItem<String>(
                value: 'Others',
                child: Text(
                  'Others',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            onChanged: _onMakeSelected,
          ),
        if (_isMakeOthers) ...[
          SizedBox(height: 12.h),
          TextField(
            controller: widget.makeController,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              hintText: 'Enter vehicle make',
              hintStyle: GoogleFonts.inter(
                fontSize: 15.sp,
                color: Color(0xFFAAAAAA),
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: GlobalStyles.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 18.h,
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
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            'Vehicle Model',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedModel,
          hint: Text(
            isDisabled ? 'Select make first' : 'Select vehicle model',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.w400,
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.car_crash,
              color:
                  isDisabled
                      ? Colors.grey.shade400
                      : GlobalStyles.primaryColor.withOpacity(0.7),
              size: 20.sp,
            ),
            filled: true,
            fillColor: isDisabled ? Color(0xFFEBEBEB) : Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 18.h,
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
                            child: Text(
                              modelName,
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        })
                        .toList(),
                    DropdownMenuItem<String>(
                      value: 'Others',
                      child: Text(
                        'Others',
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
          onChanged: isDisabled ? null : _onModelSelected,
        ),
        if (_isModelOthers) ...[
          SizedBox(height: 12.h),
          TextField(
            controller: widget.modelController,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              hintText: 'Enter vehicle model',
              hintStyle: GoogleFonts.inter(
                fontSize: 15.sp,
                color: Color(0xFFAAAAAA),
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: GlobalStyles.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 18.h,
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
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            'Vehicle Year',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextField(
          controller: widget.yearController,
          enabled: !isDisabled,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: isDisabled ? 'Select model first' : 'Enter vehicle year',
            hintStyle: GoogleFonts.inter(
              fontSize: 15.sp,
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.calendar_today,
              color:
                  isDisabled
                      ? Colors.grey.shade400
                      : GlobalStyles.primaryColor.withOpacity(0.7),
              size: 20.sp,
            ),
            filled: true,
            fillColor: isDisabled ? Color(0xFFEBEBEB) : Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: GlobalStyles.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 18.h,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
