import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/utils/faq_utils.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<int, bool> _expandedItems = {};
  final Map<int, AnimationController> _expandControllers = {};
  late AnimationController _searchFocusController;
  late List<AnimationController> _itemControllers;

  late final List<Map<String, String>> _faqItems;

  @override
  void initState() {
    super.initState();
    _faqItems = FAQUtils.getFAQItems();
    _searchFocusController = AnimationController(
      duration: GlobalStyles.durationFast,
      vsync: this,
    );
    _initializeItemAnimations();
  }

  void _initializeItemAnimations() {
    _itemControllers = List.generate(
      _faqItems.length,
      (index) => AnimationController(
        duration: GlobalStyles.durationNormal,
        vsync: this,
      ),
    );
    // Initialize expand controllers for each item
    for (int i = 0; i < _faqItems.length; i++) {
      _expandControllers[i] = AnimationController(
        duration: GlobalStyles.durationNormal,
        vsync: this,
      );
    }
  }

  List<Map<String, String>> get _filteredFAQs {
    return FAQUtils.filterFAQs(_faqItems, _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    for (var controller in _expandControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFAQs = _filteredFAQs;
    final categories = FAQUtils.getCategories(filteredFAQs);

    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar with Animation
            _buildSearchBar(),

            // FAQ List or Empty State
            Expanded(
              child:
                  filteredFAQs.isEmpty
                      ? _buildNoResults()
                      : _buildFAQList(filteredFAQs, categories),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showContactDialog();
      },
      backgroundColor: GlobalStyles.primaryMain,
      elevation: 4,
      tooltip: 'Need more help?',
      child: Icon(
        LucideIcons.messageCircle,
        color: GlobalStyles.surfaceMain,
        size: GlobalStyles.iconSizeMd,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GlobalStyles.surfaceMain,
      elevation: 0,
      shadowColor: GlobalStyles.shadowSm.color,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          LucideIcons.arrowLeft,
          color: GlobalStyles.textPrimary,
          size: GlobalStyles.iconSizeMd,
        ),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Go back',
      ),
      title: Text(
        'Frequently Asked Questions',
        style: TextStyle(
          fontFamily: GlobalStyles.fontFamilyHeading,
          color: GlobalStyles.textPrimary,
          fontSize: GlobalStyles.fontSizeH4,
          fontWeight: GlobalStyles.fontWeightSemiBold,
          letterSpacing: GlobalStyles.letterSpacingH4,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(GlobalStyles.paddingNormal),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontFamily: GlobalStyles.fontFamilyBody,
          color: GlobalStyles.textPrimary,
          fontSize: GlobalStyles.fontSizeBody1,
        ),
        decoration: InputDecoration(
          hintText: 'Search FAQs...',
          hintStyle: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: GlobalStyles.textTertiary,
            fontSize: GlobalStyles.fontSizeBody1,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: GlobalStyles.paddingNormal),
            child: Icon(
              LucideIcons.search,
              color: GlobalStyles.primaryMain,
              size: GlobalStyles.iconSizeSm,
            ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: GlobalStyles.minTouchTarget,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: GlobalStyles.textTertiary,
                      size: GlobalStyles.iconSizeSm,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    tooltip: 'Clear search',
                  )
                  : null,
          filled: true,
          fillColor: GlobalStyles.surfaceMain,
          contentPadding: EdgeInsets.symmetric(
            horizontal: GlobalStyles.paddingNormal,
            vertical: GlobalStyles.paddingNormal,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
            borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
            borderSide: BorderSide(color: GlobalStyles.inputBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
            borderSide: BorderSide(
              color: GlobalStyles.inputFocusBorderColor,
              width: 2.w,
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onTap: () {
          _searchFocusController.forward();
        },
      ),
    );
  }

  Widget _buildFAQList(
    List<Map<String, String>> filteredFAQs,
    List<String> categories,
  ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: GlobalStyles.paddingNormal,
        vertical: GlobalStyles.spacingMd,
      ),
      itemCount: categories.length,
      itemBuilder: (context, categoryIndex) {
        final category = categories[categoryIndex];
        final categoryFAQs =
            filteredFAQs.where((faq) => faq['category'] == category).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            if (_searchQuery.isEmpty) ...[
              Padding(
                padding: EdgeInsets.only(
                  top:
                      categoryIndex == 0
                          ? GlobalStyles.spacingSm
                          : GlobalStyles.spacingLg,
                  bottom: GlobalStyles.spacingMd,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: GlobalStyles.primaryMain,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: GlobalStyles.spacingMd),
                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyHeading,
                          color: GlobalStyles.textPrimary,
                          fontSize: GlobalStyles.fontSizeH5,
                          fontWeight: GlobalStyles.fontWeightSemiBold,
                          letterSpacing: GlobalStyles.letterSpacingH4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // FAQ Items with Animations
            ...categoryFAQs.asMap().entries.map((entry) {
              final faqIndex = _faqItems.indexOf(entry.value);
              _itemControllers[faqIndex].forward();
              return _buildAnimatedFAQItem(entry.value, faqIndex);
            }).toList(),

            if (categoryIndex < categories.length - 1)
              SizedBox(height: GlobalStyles.spacingLg),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedFAQItem(Map<String, String> faq, int index) {
    return Padding(
      padding: EdgeInsets.only(bottom: GlobalStyles.spacingMd),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _itemControllers[index],
            curve: GlobalStyles.easingDecelerate,
          ),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _itemControllers[index],
              curve: GlobalStyles.easingDecelerate,
            ),
          ),
          child: _buildFAQItem(faq, index),
        ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, String> faq, int index) {
    final isExpanded = FAQUtils.isExpanded(_expandedItems, index);
    final expandController = _expandControllers[index]!;

    // Trigger animation when expanded state changes
    if (isExpanded && expandController.status != AnimationStatus.forward) {
      expandController.forward();
    } else if (!isExpanded &&
        expandController.status != AnimationStatus.reverse) {
      expandController.reverse();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: GlobalStyles.surfaceMain,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
          border: Border.all(
            color:
                isExpanded
                    ? GlobalStyles.primaryMain
                    : GlobalStyles.primaryMain.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            if (isExpanded) GlobalStyles.cardShadow else GlobalStyles.shadowSm,
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expandedItems[index] = !isExpanded;
                });
              },
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(GlobalStyles.radiusLg),
                topRight: Radius.circular(GlobalStyles.radiusLg),
              ),
              splashColor: GlobalStyles.primaryMain.withOpacity(0.05),
              highlightColor: GlobalStyles.primaryMain.withOpacity(0.03),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.paddingNormal,
                  vertical: GlobalStyles.paddingNormal,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        faq['question']!,
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          color: GlobalStyles.textPrimary,
                          fontSize: GlobalStyles.fontSizeBody1,
                          fontWeight: GlobalStyles.fontWeightMedium,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: GlobalStyles.spacingMd),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: GlobalStyles.durationNormal,
                      child: Icon(
                        LucideIcons.chevronDown,
                        color: GlobalStyles.primaryMain,
                        size: GlobalStyles.iconSizeMd,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Animated content expansion
            SizeTransition(
              sizeFactor: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: expandController,
                  curve: GlobalStyles.easingStandard,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 1,
                    color: GlobalStyles.primaryMain.withOpacity(0.15),
                  ),
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: expandController,
                        curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(GlobalStyles.paddingNormal),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            faq['answer']!,
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textSecondary,
                              fontSize: GlobalStyles.fontSizeBody2,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: GlobalStyles.iconSizeXl * 2.5,
            height: GlobalStyles.iconSizeXl * 2.5,
            decoration: BoxDecoration(
              color: GlobalStyles.primaryMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.searchX,
              size: GlobalStyles.iconSizeXl * 1.5,
              color: GlobalStyles.primaryMain,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingLg),
          Text(
            'No results found',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyHeading,
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeH5,
              fontWeight: GlobalStyles.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingSm),
          Text(
            'Try different keywords or contact support',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textTertiary,
              fontSize: GlobalStyles.fontSizeBody2,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingXl),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            icon: Icon(LucideIcons.redo, size: GlobalStyles.iconSizeSm),
            label: Text(
              'Clear Search',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeButton,
                fontWeight: GlobalStyles.fontWeightMedium,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalStyles.primaryMain,
              foregroundColor: GlobalStyles.surfaceMain,
              padding: GlobalStyles.buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: GlobalStyles.dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GlobalStyles.dialogBorderRadius,
            ),
          ),
          title: Text(
            'Need More Help?',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyHeading,
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeH5,
              fontWeight: GlobalStyles.fontWeightSemiBold,
            ),
          ),
          content: Text(
            'Can\'t find what you\'re looking for? Our support team is here to help!',
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textSecondary,
              fontSize: GlobalStyles.fontSizeBody2,
            ),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  GlobalStyles.primaryMain,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontWeight: GlobalStyles.fontWeightMedium,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: GlobalStyles.primaryMain,
                foregroundColor: GlobalStyles.surfaceMain,
                padding: EdgeInsets.symmetric(
                  horizontal: GlobalStyles.paddingNormal,
                  vertical: GlobalStyles.paddingTight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to contact screen
                Navigator.pushNamed(context, '/contact');
              },
              child: Text(
                'Contact Support',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontWeight: GlobalStyles.fontWeightMedium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
