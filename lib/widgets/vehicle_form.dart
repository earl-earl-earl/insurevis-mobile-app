import 'package:flutter/material.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/services/car_brands_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  // Search controller and filtered models
  late TextEditingController _modelSearchController;
  List<Map<String, dynamic>> _filteredModels = [];
  bool _showModelDropdown = false;

  // Search controller and filtered makes
  late TextEditingController _makeSearchController;
  List<Map<String, dynamic>> _filteredMakes = [];
  bool _showMakeDropdown = false;

  @override
  void initState() {
    super.initState();
    _modelSearchController = TextEditingController();
    _modelSearchController.addListener(_filterModels);
    _makeSearchController = TextEditingController();
    _makeSearchController.addListener(_filterMakes);
    _fetchCarBrands();
  }

  @override
  void dispose() {
    _modelSearchController.removeListener(_filterModels);
    _modelSearchController.dispose();
    _makeSearchController.removeListener(_filterMakes);
    _makeSearchController.dispose();
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

  /// Filters available models based on search input
  void _filterModels() {
    final searchQuery = _modelSearchController.text.trim().toLowerCase();

    setState(() {
      if (searchQuery.isEmpty) {
        _filteredModels = [..._availableModels];
      } else {
        _filteredModels =
            _availableModels.where((model) {
              final modelName =
                  (model['model'] ?? model['model_name'])
                      .toString()
                      .toLowerCase();
              return modelName.contains(searchQuery);
            }).toList();
      }
      _showModelDropdown = true;
    });
  }

  /// Filters available makes based on search input
  void _filterMakes() {
    final searchQuery = _makeSearchController.text.trim().toLowerCase();

    setState(() {
      if (searchQuery.isEmpty) {
        _filteredMakes = [..._carBrandsData];
      } else {
        _filteredMakes =
            _carBrandsData.where((brand) {
              final brandName =
                  (brand['brand'] ?? brand['name']).toString().toLowerCase();
              return brandName.contains(searchQuery);
            }).toList();
      }
      _showMakeDropdown = true;
    });
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
        if (updateController) {
          widget.makeController.text = make;
          _makeSearchController.text = make;
        }
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
        _modelSearchController.clear();
        widget.yearController.clear();
        _filteredModels = [..._availableModels];
      }
      _showMakeDropdown = false;
    });
  }

  /// Updates year when a model is selected
  void _onModelSelected(String? model, {bool updateController = true}) {
    setState(() {
      _selectedModel = model;
      _isModelOthers = model == 'Others';
      _showModelDropdown = false;

      if (_isModelOthers) {
        if (updateController) {
          widget.modelController.clear();
          _modelSearchController.clear();
          widget.yearController.clear();
        }
      } else if (model != null) {
        if (updateController) {
          widget.modelController.text = model;
          _modelSearchController.text = model;
        }

        if (updateController) {
          final selectedModelData = _filteredModels.firstWhere(
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
        SizedBox(height: GlobalStyles.spacingMd),
        _buildVehicleModelDropdown(),
        SizedBox(height: GlobalStyles.spacingMd),
        _buildVehicleYearField(),
        SizedBox(height: GlobalStyles.spacingMd),
        _buildVehicleInputField(
          controller: widget.plateNumberController,
          label: 'Plate Number',
          hint: 'Enter vehicle plate number',
          icon: LucideIcons.creditCard,
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
          padding: EdgeInsets.only(
            left: GlobalStyles.spacingXs,
            bottom: GlobalStyles.spacingSm,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyBody,
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: GlobalStyles.fontSizeBody1,
            fontWeight: GlobalStyles.fontWeightMedium,
            color: GlobalStyles.textPrimary,
            fontFamily: GlobalStyles.fontFamilyBody,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: GlobalStyles.fontSizeBody1,
              color: GlobalStyles.textTertiary,
              fontWeight: GlobalStyles.fontWeightRegular,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            prefixIcon: Icon(
              icon,
              color: GlobalStyles.primaryMain.withOpacity(0.7),
              size: GlobalStyles.iconSizeSm,
            ),
            filled: true,
            fillColor: GlobalStyles.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: const BorderSide(
                color: GlobalStyles.inputBorderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: const BorderSide(
                color: GlobalStyles.inputFocusBorderColor,
                width: 2,
              ),
            ),
            contentPadding: GlobalStyles.inputPadding,
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
          padding: EdgeInsets.only(
            left: GlobalStyles.spacingXs,
            bottom: GlobalStyles.spacingSm,
          ),
          child: Text(
            'Vehicle Make',
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyBody,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (_isLoadingBrands)
          Container(
            padding: GlobalStyles.inputPadding,
            decoration: BoxDecoration(
              color: GlobalStyles.inputBackground,
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              border: Border.all(
                color: GlobalStyles.inputBorderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: GlobalStyles.iconSizeSm,
                  height: GlobalStyles.iconSizeSm,
                  child: CircularProgressIndicator(
                    strokeWidth: GlobalStyles.iconStrokeWidthNormal,
                    color: GlobalStyles.primaryMain,
                  ),
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Text(
                  'Loading car brands...',
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeBody1,
                    color: GlobalStyles.textSecondary,
                    fontWeight: GlobalStyles.fontWeightMedium,
                    fontFamily: GlobalStyles.fontFamilyBody,
                  ),
                ),
              ],
            ),
          )
        else
          TextField(
            controller: _makeSearchController,
            onTap: () {
              setState(() {
                _showMakeDropdown = true;
                _filteredMakes = [..._carBrandsData];
              });
            },
            onChanged: (value) {
              _filterMakes();
            },
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody1,
              color: GlobalStyles.textPrimary,
              fontWeight: GlobalStyles.fontWeightMedium,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            decoration: InputDecoration(
              hintText: 'Search vehicle make',
              hintStyle: TextStyle(
                fontSize: GlobalStyles.fontSizeBody1,
                color: GlobalStyles.textTertiary,
                fontWeight: GlobalStyles.fontWeightRegular,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
              prefixIcon: Icon(
                LucideIcons.car,
                color: GlobalStyles.primaryMain.withOpacity(0.7),
                size: GlobalStyles.iconSizeSm,
              ),
              filled: true,
              fillColor: GlobalStyles.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.inputBorderRadius,
                ),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.inputBorderRadius,
                ),
                borderSide: const BorderSide(
                  color: GlobalStyles.inputBorderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.inputBorderRadius,
                ),
                borderSide: const BorderSide(
                  color: GlobalStyles.inputFocusBorderColor,
                  width: 2,
                ),
              ),
              contentPadding: GlobalStyles.inputPadding,
            ),
          ),
        if (_showMakeDropdown && !_isLoadingBrands)
          Container(
            margin: EdgeInsets.only(top: GlobalStyles.spacingSm),
            decoration: BoxDecoration(
              color: GlobalStyles.inputBackground,
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              border: Border.all(
                color: GlobalStyles.inputBorderColor,
                width: 1,
              ),
            ),
            constraints: BoxConstraints(maxHeight: 250),
            child:
                _filteredMakes.isEmpty
                    ? Padding(
                      padding: GlobalStyles.inputPadding,
                      child: Text(
                        'No makes found',
                        style: TextStyle(
                          fontSize: GlobalStyles.fontSizeBody1,
                          color: GlobalStyles.textSecondary,
                          fontWeight: GlobalStyles.fontWeightMedium,
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                    )
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredMakes.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _filteredMakes.length) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _onMakeSelected('Others');
                              },
                              child: Padding(
                                padding: GlobalStyles.inputPadding,
                                child: Text(
                                  'Others',
                                  style: TextStyle(
                                    fontSize: GlobalStyles.fontSizeBody1,
                                    color: GlobalStyles.textPrimary,
                                    fontWeight: GlobalStyles.fontWeightMedium,
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final brand = _filteredMakes[index];
                        final brandName =
                            (brand['brand'] ?? brand['name']).toString();

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _onMakeSelected(brandName);
                            },
                            child: Padding(
                              padding: GlobalStyles.inputPadding,
                              child: Text(
                                brandName,
                                style: TextStyle(
                                  fontSize: GlobalStyles.fontSizeBody1,
                                  color: GlobalStyles.textPrimary,
                                  fontWeight: GlobalStyles.fontWeightMedium,
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        if (_isMakeOthers) ...[
          SizedBox(height: GlobalStyles.spacingMd),
          TextField(
            controller: widget.makeController,
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody1,
              fontWeight: GlobalStyles.fontWeightMedium,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            decoration: InputDecoration(
              hintText: 'Enter vehicle make',
              hintStyle: TextStyle(
                fontSize: GlobalStyles.fontSizeBody1,
                color: GlobalStyles.textTertiary,
                fontWeight: GlobalStyles.fontWeightRegular,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
              filled: true,
              fillColor: GlobalStyles.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.inputBorderRadius,
                ),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.inputBorderRadius,
                ),
                borderSide: const BorderSide(
                  color: GlobalStyles.inputBorderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.inputBorderRadius,
                ),
                borderSide: const BorderSide(
                  color: GlobalStyles.inputFocusBorderColor,
                  width: 2,
                ),
              ),
              contentPadding: GlobalStyles.inputPadding,
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
          padding: EdgeInsets.only(
            left: GlobalStyles.spacingXs,
            bottom: GlobalStyles.spacingSm,
          ),
          child: Text(
            'Vehicle Model',
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyBody,
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextField(
          controller: _modelSearchController,
          enabled: !isDisabled,
          onTap: () {
            setState(() {
              _showModelDropdown = true;
              _filteredModels = [..._availableModels];
            });
          },
          onChanged: (value) {
            _filterModels();
          },
          style: TextStyle(
            fontSize: GlobalStyles.fontSizeBody1,
            color: GlobalStyles.textPrimary,
            fontWeight: GlobalStyles.fontWeightMedium,
            fontFamily: GlobalStyles.fontFamilyBody,
          ),
          decoration: InputDecoration(
            hintText: isDisabled ? 'Select make first' : 'Search vehicle model',
            hintStyle: TextStyle(
              fontSize: GlobalStyles.fontSizeBody1,
              color: GlobalStyles.textTertiary,
              fontWeight: GlobalStyles.fontWeightRegular,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            prefixIcon: Icon(
              LucideIcons.carFront,
              color:
                  isDisabled
                      ? GlobalStyles.textDisabled
                      : GlobalStyles.primaryMain.withOpacity(0.7),
              size: GlobalStyles.iconSizeSm,
            ),
            filled: true,
            fillColor:
                isDisabled
                    ? GlobalStyles.backgroundAlternative
                    : GlobalStyles.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: BorderSide(
                color:
                    isDisabled
                        ? GlobalStyles.inputBorderColor.withOpacity(0.5)
                        : GlobalStyles.inputBorderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: const BorderSide(
                color: GlobalStyles.inputFocusBorderColor,
                width: 2,
              ),
            ),
            contentPadding: GlobalStyles.inputPadding,
          ),
        ),
        if (_showModelDropdown && !isDisabled)
          Container(
            margin: EdgeInsets.only(top: GlobalStyles.spacingSm),
            decoration: BoxDecoration(
              color: GlobalStyles.inputBackground,
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              border: Border.all(
                color: GlobalStyles.inputBorderColor,
                width: 1,
              ),
            ),
            constraints: BoxConstraints(maxHeight: 250),
            child:
                _filteredModels.isEmpty
                    ? Padding(
                      padding: GlobalStyles.inputPadding,
                      child: Text(
                        'No models found',
                        style: TextStyle(
                          fontSize: GlobalStyles.fontSizeBody1,
                          color: GlobalStyles.textSecondary,
                          fontWeight: GlobalStyles.fontWeightMedium,
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                    )
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredModels.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _filteredModels.length) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _onModelSelected('Others');
                              },
                              child: Padding(
                                padding: GlobalStyles.inputPadding,
                                child: Text(
                                  'Others',
                                  style: TextStyle(
                                    fontSize: GlobalStyles.fontSizeBody1,
                                    color: GlobalStyles.textPrimary,
                                    fontWeight: GlobalStyles.fontWeightMedium,
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final model = _filteredModels[index];
                        final modelName =
                            (model['model'] ?? model['model_name']).toString();

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _onModelSelected(modelName);
                            },
                            child: Padding(
                              padding: GlobalStyles.inputPadding,
                              child: Text(
                                modelName,
                                style: TextStyle(
                                  fontSize: GlobalStyles.fontSizeBody1,
                                  color: GlobalStyles.textPrimary,
                                  fontWeight: GlobalStyles.fontWeightMedium,
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        if (_isModelOthers) ...[
          SizedBox(height: GlobalStyles.spacingMd),
          TextField(
            controller: widget.modelController,
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody1,
              fontWeight: GlobalStyles.fontWeightMedium,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            decoration: InputDecoration(
              hintText: 'Enter vehicle model',
              hintStyle: TextStyle(
                fontSize: GlobalStyles.fontSizeBody1,
                color: GlobalStyles.textTertiary,
                fontWeight: GlobalStyles.fontWeightRegular,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
              filled: true,
              fillColor: GlobalStyles.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.inputBorderRadius,
                ),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.inputBorderRadius,
                ),
                borderSide: const BorderSide(
                  color: GlobalStyles.inputBorderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.inputBorderRadius,
                ),
                borderSide: const BorderSide(
                  color: GlobalStyles.inputFocusBorderColor,
                  width: 2,
                ),
              ),
              contentPadding: GlobalStyles.inputPadding,
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
          padding: EdgeInsets.only(
            left: GlobalStyles.spacingXs,
            bottom: GlobalStyles.spacingSm,
          ),
          child: Text(
            'Vehicle Year',
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyBody,
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextField(
          controller: widget.yearController,
          enabled: !isDisabled,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: TextStyle(
            fontSize: GlobalStyles.fontSizeBody1,
            fontWeight: GlobalStyles.fontWeightMedium,
            color: GlobalStyles.textPrimary,
            fontFamily: GlobalStyles.fontFamilyBody,
          ),
          decoration: InputDecoration(
            hintText: isDisabled ? 'Select model first' : 'Enter vehicle year',
            hintStyle: TextStyle(
              fontSize: GlobalStyles.fontSizeBody1,
              color: GlobalStyles.textTertiary,
              fontWeight: GlobalStyles.fontWeightRegular,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            prefixIcon: Icon(
              LucideIcons.calendar,
              color:
                  isDisabled
                      ? GlobalStyles.textDisabled
                      : GlobalStyles.primaryMain.withOpacity(0.7),
              size: GlobalStyles.iconSizeSm,
            ),
            filled: true,
            fillColor:
                isDisabled
                    ? GlobalStyles.backgroundAlternative
                    : GlobalStyles.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: BorderSide(
                color:
                    isDisabled
                        ? GlobalStyles.inputBorderColor.withOpacity(0.5)
                        : GlobalStyles.inputBorderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.inputBorderRadius,
              ),
              borderSide: const BorderSide(
                color: GlobalStyles.inputFocusBorderColor,
                width: 2,
              ),
            ),
            contentPadding: GlobalStyles.inputPadding,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
