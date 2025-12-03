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

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<int, bool> _expandedItems = {};

  late final List<Map<String, String>> _faqItems;

  @override
  void initState() {
    super.initState();
    _faqItems = FAQUtils.getFAQItems();
  }

  List<Map<String, String>> get _filteredFAQs {
    return FAQUtils.filterFAQs(_faqItems, _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFAQs = _filteredFAQs;
    final categories = FAQUtils.getCategories(filteredFAQs);

    return Scaffold(
      backgroundColor: Colors.white,
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
          'Frequently Asked Questions',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyHeading,
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeH4,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            letterSpacing: GlobalStyles.letterSpacingH4,
          ),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(GlobalStyles.paddingNormal),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    hintStyle: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.textTertiary,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: GlobalStyles.primaryMain,
                      size: GlobalStyles.iconSizeSm,
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
                            )
                            : null,
                    filled: true,
                    fillColor: GlobalStyles.backgroundMain,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusLg,
                      ),
                      borderSide: BorderSide(
                        color: GlobalStyles.inputBorderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusLg,
                      ),
                      borderSide: BorderSide(
                        color: GlobalStyles.inputBorderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusLg,
                      ),
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
                ),
              ),

              // FAQ List
              Expanded(
                child:
                    filteredFAQs.isEmpty
                        ? _buildNoResults()
                        : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: GlobalStyles.paddingNormal,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, categoryIndex) {
                            final category = categories[categoryIndex];
                            final categoryFAQs =
                                filteredFAQs
                                    .where((faq) => faq['category'] == category)
                                    .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Header
                                if (_searchQuery.isEmpty) ...[
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: GlobalStyles.spacingMd,
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontFamily:
                                            GlobalStyles.fontFamilyHeading,
                                        color: GlobalStyles.primaryMain,
                                        fontSize: GlobalStyles.fontSizeH5,
                                        fontWeight:
                                            GlobalStyles.fontWeightSemiBold,
                                      ),
                                    ),
                                  ),
                                ],

                                // FAQ Items
                                ...categoryFAQs.asMap().entries.map((entry) {
                                  final faqIndex = _faqItems.indexOf(
                                    entry.value,
                                  );
                                  return _buildFAQItem(entry.value, faqIndex);
                                }),

                                if (categoryIndex < categories.length - 1)
                                  SizedBox(height: GlobalStyles.spacingMd),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showContactDialog();
        },
        backgroundColor: GlobalStyles.primaryMain,
        elevation: 4,
        child: Icon(
          LucideIcons.messageCircle,
          color: GlobalStyles.surfaceMain,
          size: GlobalStyles.iconSizeMd,
        ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, String> faq, int index) {
    final isExpanded = FAQUtils.isExpanded(_expandedItems, index);

    return Container(
      margin: EdgeInsets.only(bottom: GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
        border: Border.all(
          color: GlobalStyles.primaryMain.withValues(alpha: 0.15),
          width: GlobalStyles.iconStrokeWidthNormal,
        ),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              faq['question']!,
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color: GlobalStyles.textPrimary,
                fontSize: GlobalStyles.fontSizeBody1,
                fontWeight: GlobalStyles.fontWeightMedium,
              ),
            ),
            trailing: Icon(
              isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              color: GlobalStyles.primaryMain,
              size: GlobalStyles.iconSizeMd,
            ),
            onTap: () {
              setState(() {
                _expandedItems
                  ..clear()
                  ..addAll(FAQUtils.toggleExpansion(_expandedItems, index));
              });
            },
          ),
          if (isExpanded) ...[
            Divider(
              color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
              height: 1,
            ),
            Padding(
              padding: EdgeInsets.all(GlobalStyles.paddingNormal),
              child: Text(
                faq['answer']!,
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.textSecondary,
                  fontSize: GlobalStyles.fontSizeBody2,
                  height:
                      GlobalStyles.lineHeightBody2 / GlobalStyles.fontSizeBody2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: GlobalStyles.iconSizeXl * 2,
            color: GlobalStyles.textDisabled,
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
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalStyles.primaryMain,
              foregroundColor: GlobalStyles.surfaceMain,
              padding: GlobalStyles.buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GlobalStyles.radiusFull),
              ),
              elevation: 0,
              shadowColor: GlobalStyles.buttonShadow.color,
            ),
            child: Text(
              'Clear Search',
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                fontSize: GlobalStyles.fontSizeButton,
                fontWeight: GlobalStyles.fontWeightMedium,
                letterSpacing: GlobalStyles.letterSpacingButton,
              ),
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
