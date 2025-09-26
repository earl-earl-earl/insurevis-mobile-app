import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
          'Open the app and tap Sign Up. Provide your name, email and a strong password (minimum 8 characters, upper + lower case, number and special character). The app uses Supabase for authentication. If an account with the email already exists you will be prompted to sign in instead.',
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
          'InsureVis produces automated AI assessments and cost estimates. Accuracy depends on image quality, number of angles provided and damage complexity. Use the report as a reliable preliminary assessment — insurers may still require a physical inspection for final claim approval.',
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
          'Use good, even lighting, keep the camera steady and include multiple angles of the damaged area. Make sure the damage fills the frame enough to be clearly visible. Avoid heavy shadows, reflections and extreme zoom which can reduce analysis quality.',
    },
    {
      'category': 'Photos & Images',
      'question': 'Can I upload multiple photos?',
      'answer':
          'Yes. The app supports multi-photo assessments and the exported PDF/report will include all images submitted for that assessment. Note that individual file uploads are validated; most document/photo uploads have a 10MB per-file limit.',
    },
    {
      'category': 'Insurance Claims',
      'question': 'Can I use InsureVis reports for insurance claims?',
      'answer':
          'Yes — the app can generate detailed PDF assessment reports (summary, insurance and technical templates) that many insurers accept as preliminary documentation. Insurers may still request a physical inspection before finalising a claim.',
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
          'Cost estimates are generated from the detected damage type and severity, combined with vehicle make/model data and local pricing when available. Estimates are indicative — actual repair shop quotes may vary.',
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
          'Close background apps, check your internet connection and try again. Large uploads or slow connections can delay processing. If problems persist, update the app and contact support with logs via the Contact screen.',
    },
    {
      'category': 'Technical Issues',
      'question': 'My photos won\'t upload. What\'s wrong?',
      'answer':
          'Common causes: poor connection, camera/storage permissions not granted, or the file exceeds the 10MB per-file limit. Try re-taking the photo, reduce image size or use the gallery uploader. The web portal and services also enforce a 10MB file limit for documents.',
    },
    {
      'category': 'Account & Settings',
      'question': 'How do I change my password?',
      'answer':
          'While signed in go to Settings > Security > Change Password and provide your current password plus a new strong password. If you forgot your password use the Reset Password option on the login screen — a reset email will be sent to your address.',
    },
    {
      'category': 'Account & Settings',
      'question': 'Can I delete my account?',
      'answer':
          'Account deletion is available from Settings > Account > Delete Account. Deleting your account removes your profile, assessments and documents from the app and backend — this action is permanent. If you need help restoring data contact support immediately.',
    },
    {
      'category': 'Privacy & Security',
      'question': 'Is my data secure?',
      'answer':
          'The app uses Supabase and standard transport/security practices to protect your data. Files and personal information are stored with access controls; the Privacy Policy screen describes collection and sharing practices. Contact support for data deletion or export requests.',
    },
    {
      'category': 'Privacy & Security',
      'question': 'Who can see my assessment reports?',
      'answer':
          'By default reports are private to your account. You can export or share generated PDFs with insurers, repair shops or other parties. Sharing is a manual action initiated by you.',
    },
    {
      'category': 'Billing & Subscriptions',
      'question': 'Is the app free to use?',
      'answer':
          'Yes — InsureVis is 100% free to use. There are no paid plans or subscriptions required to access the app\'s features.',
    },
    {
      'category': 'Billing & Subscriptions',
      'question': 'How do I cancel my subscription?',
      'answer':
          'There are no subscriptions to cancel — the app is fully free. If you see billing-related messages, please contact support so we can investigate.',
    },
    {
      'category': 'Exports & Reports',
      'question': 'Can I export assessment reports?',
      'answer':
          'Yes. The app generates PDF reports (multiple templates: summary, insurance and technical). PDFs include images, cost breakdowns and metadata and are intended for sharing with insurers and repair shops.',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2A2A2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Frequently Asked Questions',
          style: GoogleFonts.inter(
            color: Color(0xFF2A2A2A),
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
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
                padding: EdgeInsets.all(20.w),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: Color(0xFF2A2A2A)),
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    hintStyle: GoogleFonts.inter(color: Color(0x992A2A2A)),
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
                    fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.black12.withAlpha((0.04 * 255).toInt()),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.black12.withAlpha((0.04 * 255).toInt()),
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
                                      style: GoogleFonts.inter(
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
        color: GlobalStyles.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GlobalStyles.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              faq['question']!,
              style: GoogleFonts.inter(
                color: Color(0xFF2A2A2A),
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
            const Divider(color: Color(0x332A2A2A), height: 1),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                faq['answer']!,
                style: GoogleFonts.inter(
                  color: Color(0x992A2A2A),
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
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Try different keywords or contact support',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14.sp),
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
          backgroundColor: Colors.white,
          title: Text(
            'Need More Help?',
            style: GoogleFonts.inter(color: Color(0xFF2A2A2A)),
          ),
          content: Text(
            'Can\'t find what you\'re looking for? Our support team is here to help!',
            style: GoogleFonts.inter(color: Color(0x992A2A2A)),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  GlobalStyles.primaryColor,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: GlobalStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to contact screen
                Navigator.pushNamed(context, '/contact');
              },
              child: Text(
                'Contact Support',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
