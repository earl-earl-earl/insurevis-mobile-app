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
            controller: widget.makeController,
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
            controller: widget.modelController,
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
          controller: widget.yearController,
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
}
