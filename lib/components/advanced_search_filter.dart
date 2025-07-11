import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdvancedSearchFilter extends StatefulWidget {
  final Function(SearchFilters) onFiltersChanged;
  final SearchFilters currentFilters;

  const AdvancedSearchFilter({
    super.key,
    required this.onFiltersChanged,
    required this.currentFilters,
  });

  @override
  State<AdvancedSearchFilter> createState() => _AdvancedSearchFilterState();
}

class _AdvancedSearchFilterState extends State<AdvancedSearchFilter>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late SearchFilters _filters;
  bool _isExpanded = false;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.currentFilters.searchQuery,
    );
    _filters = widget.currentFilters.copy();

    _expandController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(_expandController);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _applyFilters() {
    _filters.searchQuery = _searchController.text;
    widget.onFiltersChanged(_filters);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _filters = SearchFilters();
    });
    widget.onFiltersChanged(_filters);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return Colors.red;
      case 'medium':
      case 'moderate':
        return Colors.orange;
      case 'low':
      case 'minor':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Search bar and expand button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _filters.searchQuery = value;
                      _applyFilters();
                    },
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search assessments...',
                      hintStyle: TextStyle(color: Colors.white60),
                      prefixIcon: Icon(Icons.search, color: Colors.white60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Filter toggle button
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color:
                          _isExpanded
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color:
                            _isExpanded
                                ? Colors.blue
                                : Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune,
                          color: _isExpanded ? Colors.blue : Colors.white70,
                          size: 20.sp,
                        ),
                        SizedBox(width: 4.w),
                        AnimatedBuilder(
                          animation: _rotateAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotateAnimation.value * 3.14159,
                              child: Icon(
                                Icons.expand_more,
                                color:
                                    _isExpanded ? Colors.blue : Colors.white70,
                                size: 20.sp,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expanded filters
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: _buildExpandedFilters(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedFilters() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter categories
          _buildSectionTitle('Filter by Category'),
          SizedBox(height: 12.h),
          _buildFilterChips(),

          SizedBox(height: 20.h),

          // Date range
          _buildSectionTitle('Date Range'),
          SizedBox(height: 12.h),
          _buildDateRangeSelector(),

          SizedBox(height: 20.h),

          // Severity filter
          _buildSectionTitle('Severity Level'),
          SizedBox(height: 12.h),
          _buildSeverityFilter(),

          SizedBox(height: 20.h),

          // Cost range
          _buildSectionTitle('Cost Range'),
          SizedBox(height: 12.h),
          _buildCostRangeFilter(),

          SizedBox(height: 20.h),

          // Sort options
          _buildSectionTitle('Sort By'),
          SizedBox(height: 12.h),
          _buildSortOptions(),

          SizedBox(height: 20.h),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = [
      'All Types',
      'Dents',
      'Scratches',
      'Paint Damage',
      'Cracks',
      'Broken Parts',
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children:
          categories.map((category) {
            final isSelected =
                _filters.damageTypes.contains(category) ||
                (category == 'All Types' && _filters.damageTypes.isEmpty);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (category == 'All Types') {
                    _filters.damageTypes.clear();
                  } else {
                    if (_filters.damageTypes.contains(category)) {
                      _filters.damageTypes.remove(category);
                    } else {
                      _filters.damageTypes.add(category);
                    }
                  }
                });
                _applyFilters();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? Colors.blue
                            : Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? Colors.blue : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDateRangeSelector() {
    final options = [
      {'label': 'All Time', 'value': DateRange.allTime},
      {'label': 'Today', 'value': DateRange.today},
      {'label': 'This Week', 'value': DateRange.thisWeek},
      {'label': 'This Month', 'value': DateRange.thisMonth},
      {'label': 'Last 3 Months', 'value': DateRange.last3Months},
      {'label': 'Custom', 'value': DateRange.custom},
    ];

    return Column(
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children:
              options.map((option) {
                final isSelected = _filters.dateRange == option['value'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _filters.dateRange = option['value'] as DateRange;
                    });
                    _applyFilters();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.green
                                : Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isSelected ? Colors.green : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),

        // Custom date picker
        if (_filters.dateRange == DateRange.custom) ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'From: ${_filters.startDate?.toString().substring(0, 10) ?? 'Select'}',
                  () => _selectDate(true),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildDateButton(
                  'To: ${_filters.endDate?.toString().substring(0, 10) ?? 'Select'}',
                  () => _selectDate(false),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDateButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 12.sp, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? (_filters.startDate ?? DateTime.now())
              : (_filters.endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _filters.startDate = picked;
        } else {
          _filters.endDate = picked;
        }
      });
      _applyFilters();
    }
  }

  Widget _buildSeverityFilter() {
    final severities = ['All', 'High', 'Medium', 'Low'];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children:
          severities.map((severity) {
            final isSelected =
                _filters.severityLevels.contains(severity) ||
                (severity == 'All' && _filters.severityLevels.isEmpty);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (severity == 'All') {
                    _filters.severityLevels.clear();
                  } else {
                    if (_filters.severityLevels.contains(severity)) {
                      _filters.severityLevels.remove(severity);
                    } else {
                      _filters.severityLevels.add(severity);
                    }
                  }
                });
                _applyFilters();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? _getSeverityColor(severity).withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? _getSeverityColor(severity)
                            : Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color:
                        isSelected
                            ? _getSeverityColor(severity)
                            : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCostRangeFilter() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '\$${_filters.minCost.round()}',
              style: TextStyle(fontSize: 12.sp, color: Colors.white70),
            ),
            Expanded(
              child: RangeSlider(
                values: RangeValues(_filters.minCost, _filters.maxCost),
                min: 0,
                max: 10000,
                divisions: 20,
                activeColor: Colors.green,
                inactiveColor: Colors.white.withValues(alpha: 0.3),
                onChanged: (RangeValues values) {
                  setState(() {
                    _filters.minCost = values.start;
                    _filters.maxCost = values.end;
                  });
                },
                onChangeEnd: (RangeValues values) {
                  _applyFilters();
                },
              ),
            ),
            Text(
              '\$${_filters.maxCost.round()}',
              style: TextStyle(fontSize: 12.sp, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    final options = [
      {'label': 'Date (Newest)', 'value': SortOption.dateNewest},
      {'label': 'Date (Oldest)', 'value': SortOption.dateOldest},
      {'label': 'Cost (High to Low)', 'value': SortOption.costHighLow},
      {'label': 'Cost (Low to High)', 'value': SortOption.costLowHigh},
      {'label': 'Severity', 'value': SortOption.severity},
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children:
          options.map((option) {
            final isSelected = _filters.sortOption == option['value'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _filters.sortOption = option['value'] as SortOption;
                });
                _applyFilters();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.purple.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? Colors.purple
                            : Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  option['label'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? Colors.purple : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: Icon(Icons.clear, size: 18.sp),
            label: Text('Clear All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.3),
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red, width: 1),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _applyFilters();
              _toggleExpanded();
            },
            icon: Icon(Icons.check, size: 18.sp),
            label: Text('Apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Search filters data class
class SearchFilters {
  String searchQuery;
  List<String> damageTypes;
  List<String> severityLevels;
  DateRange dateRange;
  DateTime? startDate;
  DateTime? endDate;
  double minCost;
  double maxCost;
  SortOption sortOption;

  SearchFilters({
    this.searchQuery = '',
    List<String>? damageTypes,
    List<String>? severityLevels,
    this.dateRange = DateRange.allTime,
    this.startDate,
    this.endDate,
    this.minCost = 0,
    this.maxCost = 10000,
    this.sortOption = SortOption.dateNewest,
  }) : damageTypes = damageTypes ?? [],
       severityLevels = severityLevels ?? [];

  SearchFilters copy() {
    return SearchFilters(
      searchQuery: searchQuery,
      damageTypes: List.from(damageTypes),
      severityLevels: List.from(severityLevels),
      dateRange: dateRange,
      startDate: startDate,
      endDate: endDate,
      minCost: minCost,
      maxCost: maxCost,
      sortOption: sortOption,
    );
  }

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        damageTypes.isNotEmpty ||
        severityLevels.isNotEmpty ||
        dateRange != DateRange.allTime ||
        minCost > 0 ||
        maxCost < 10000 ||
        sortOption != SortOption.dateNewest;
  }
}

// Enums for filter options
enum DateRange { allTime, today, thisWeek, thisMonth, last3Months, custom }

enum SortOption { dateNewest, dateOldest, costHighLow, costLowHigh, severity }
