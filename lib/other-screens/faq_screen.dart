import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<int, bool> _expandedItems = {};

  final List<Map<String, String>> _faqItems = [
    {
      'category': 'Getting Started',
      'question': 'How do I create an account?',
      'answer':
          'To create an account, download the InsureVis app and tap "Sign Up". Enter your email, create a password, and verify your email address. You can also sign up using your Google or Facebook account.',
    },
    {
      'category': 'Getting Started',
      'question': 'What do I need to get started?',
      'answer':
          'You need a smartphone with a camera, internet connection, and basic vehicle information. Make sure your camera can take clear photos of your vehicle damage.',
    },
    {
      'category': 'Damage Assessment',
      'question': 'How accurate are the damage assessments?',
      'answer':
          'Our AI technology provides estimates with 85-90% accuracy based on thousands of training cases. However, results may vary depending on image quality, lighting, and damage complexity. We recommend professional inspection for final insurance claims.',
    },
    {
      'category': 'Damage Assessment',
      'question': 'What types of damage can be detected?',
      'answer':
          'InsureVis can detect various types of vehicle damage including dents, scratches, cracks, broken parts, paint damage, and structural damage on cars, motorcycles, and light trucks.',
    },
    {
      'category': 'Damage Assessment',
      'question': 'How long does the assessment take?',
      'answer':
          'Most damage assessments are completed within 30 seconds to 2 minutes, depending on image processing time and internet connection speed.',
    },
    {
      'category': 'Photos & Images',
      'question': 'What makes a good damage photo?',
      'answer':
          'Take photos in good lighting, keep the camera steady, capture the entire damaged area, take multiple angles, and ensure the damage is clearly visible. Avoid shadows and reflections when possible.',
    },
    {
      'category': 'Photos & Images',
      'question': 'Can I upload multiple photos?',
      'answer':
          'Yes, you can upload multiple photos of the same vehicle or assess different vehicles separately. Multiple angles help improve assessment accuracy.',
    },
    {
      'category': 'Insurance Claims',
      'question': 'Can I use this for insurance claims?',
      'answer':
          'Yes, our detailed reports are accepted by major insurance companies as preliminary assessments. However, your insurance company may still require a professional inspection for final claim processing.',
    },
    {
      'category': 'Insurance Claims',
      'question': 'Which insurance companies accept InsureVis reports?',
      'answer':
          'Most major insurance companies in the Philippines accept our reports including MAPFRE, Philippine AXA, Malayan Insurance, and others. Check with your specific insurer for their requirements.',
    },
    {
      'category': 'Cost Estimates',
      'question': 'How are repair costs calculated?',
      'answer':
          'Repair costs are calculated based on damage type, severity, vehicle make/model, local labor rates, and parts pricing. Our database is regularly updated with current market prices.',
    },
    {
      'category': 'Cost Estimates',
      'question': 'Are the cost estimates guaranteed?',
      'answer':
          'Cost estimates are provided for reference only and may vary based on actual repair shop pricing, parts availability, and additional damage discovered during repair.',
    },
    {
      'category': 'Technical Issues',
      'question': 'The app is running slowly. What should I do?',
      'answer':
          'Try closing other apps, ensuring you have good internet connection, restarting the app, or restarting your device. Make sure you have the latest version of the app installed.',
    },
    {
      'category': 'Technical Issues',
      'question': 'My photos won\'t upload. What\'s wrong?',
      'answer':
          'Check your internet connection, ensure the photo file size isn\'t too large (max 10MB), verify camera permissions are enabled, and try taking a new photo if the file appears corrupted.',
    },
    {
      'category': 'Account & Settings',
      'question': 'How do I change my password?',
      'answer':
          'Go to Settings > Security > Change Password. Enter your current password and choose a new one. You can also reset your password from the login screen if you forgot it.',
    },
    {
      'category': 'Account & Settings',
      'question': 'Can I delete my account?',
      'answer':
          'Yes, you can delete your account by going to Settings > Account > Delete Account. Note that this action is permanent and will remove all your assessment history.',
    },
    {
      'category': 'Privacy & Security',
      'question': 'Is my data secure?',
      'answer':
          'Yes, we use industry-standard encryption to protect your data. Photos and personal information are stored securely and are not shared without your consent. See our Privacy Policy for details.',
    },
    {
      'category': 'Privacy & Security',
      'question': 'Who can see my assessment reports?',
      'answer':
          'Only you can see your reports by default. You can choose to share them with insurance companies, repair shops, or other authorized parties when needed.',
    },
    {
      'category': 'Billing & Subscriptions',
      'question': 'Is the app free to use?',
      'answer':
          'InsureVis offers both free and premium features. Basic damage assessment is free with limited monthly usage. Premium subscriptions provide unlimited assessments and advanced features.',
    },
    {
      'category': 'Billing & Subscriptions',
      'question': 'How do I cancel my subscription?',
      'answer':
          'You can cancel your subscription anytime in Settings > Subscription or through your app store account settings. Your subscription will remain active until the end of the current billing period.',
    },
  ];

  List<Map<String, String>> get _filteredFAQs {
    if (_searchQuery.isEmpty) {
      return _faqItems;
    }
    return _faqItems.where((faq) {
      return faq['question']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['category']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFAQs = _filteredFAQs;
    final categories =
        filteredFAQs.map((faq) => faq['category']!).toSet().toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.backgroundColorStart,
              GlobalStyles.backgroundColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(20.w),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: GlobalStyles.primaryColor,
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white60,
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
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: GlobalStyles.primaryColor,
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
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                                      vertical: 15.h,
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: GlobalStyles.primaryColor,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
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
                                  SizedBox(height: 20.h),
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
        backgroundColor: GlobalStyles.primaryColor,
        child: const Icon(Icons.help_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, String> faq, int index) {
    final isExpanded = _expandedItems[index] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              faq['question']!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: GlobalStyles.primaryColor,
              size: 24.sp,
            ),
            onTap: () {
              setState(() {
                _expandedItems[index] = !isExpanded;
              });
            },
          ),
          if (isExpanded) ...[
            const Divider(color: Colors.white30, height: 1),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                faq['answer']!,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                  height: 1.5,
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
          Icon(Icons.search_off, size: 80.sp, color: Colors.white30),
          SizedBox(height: 20.h),
          Text(
            'No results found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Try different keywords or contact support',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
          SizedBox(height: 30.h),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalStyles.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Clear Search'),
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
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Need More Help?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Can\'t find what you\'re looking for? Our support team is here to help!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to contact screen
                Navigator.pushNamed(context, '/contact');
              },
              child: const Text('Contact Support'),
            ),
          ],
        );
      },
    );
  }
}
