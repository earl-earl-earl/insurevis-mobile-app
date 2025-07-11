import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Privacy Policy',
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: 'Introduction',
                  content:
                      'InsureVis ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
                ),

                _buildSection(
                  title: 'Information We Collect',
                  content: '''Personal Information:
• Name and contact information
• Email address and phone number
• Vehicle information and ownership details
• Insurance policy information

Technical Information:
• Device information and operating system
• App usage data and analytics
• Location data (when enabled)
• Camera and photo access for damage assessment

Damage Assessment Data:
• Vehicle photos and images
• Damage assessment results
• Repair cost estimates
• Insurance claim information''',
                ),

                _buildSection(
                  title: 'How We Use Your Information',
                  content: '''We use your information to:
• Provide vehicle damage assessment services
• Generate repair cost estimates
• Process insurance claims and documentation
• Improve our AI recognition algorithms
• Send notifications about your assessments
• Provide customer support
• Comply with legal obligations''',
                ),

                _buildSection(
                  title: 'Information Sharing',
                  content: '''We may share your information with:
• Insurance companies (with your consent)
• Authorized repair shops and service providers
• Third-party service providers who assist our operations
• Legal authorities when required by law

We do not sell your personal information to third parties.''',
                ),

                _buildSection(
                  title: 'Data Security',
                  content: '''We implement security measures including:
• Encryption of sensitive data
• Secure data transmission protocols
• Regular security audits and updates
• Access controls and authentication
• Secure cloud storage with backup systems''',
                ),

                _buildSection(
                  title: 'Data Retention',
                  content:
                      'We retain your information for as long as necessary to provide our services and comply with legal obligations. Assessment data may be kept for up to 7 years for insurance and legal purposes.',
                ),

                _buildSection(
                  title: 'Your Rights',
                  content: '''You have the right to:
• Access your personal information
• Correct inaccurate information
• Delete your account and data
• Object to data processing
• Data portability
• Withdraw consent at any time''',
                ),

                _buildSection(
                  title: 'Cookies and Tracking',
                  content:
                      'Our app may use cookies and similar technologies to enhance user experience, analyze app usage, and improve our services.',
                ),

                _buildSection(
                  title: 'Third-Party Services',
                  content: '''Our app integrates with third-party services:
• Cloud storage providers
• Analytics services
• Payment processors
• Insurance API services

Each has their own privacy policies which we encourage you to review.''',
                ),

                _buildSection(
                  title: 'Children\'s Privacy',
                  content:
                      'Our app is not intended for children under 18. We do not knowingly collect personal information from children under 18.',
                ),

                _buildSection(
                  title: 'International Transfers',
                  content:
                      'Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place.',
                ),

                _buildSection(
                  title: 'Changes to Privacy Policy',
                  content:
                      'We may update this Privacy Policy periodically. We will notify you of any material changes through the app or by email.',
                ),

                _buildSection(
                  title: 'Contact Us',
                  content: '''For privacy-related questions or concerns:

Email: privacy@insurevis.com
Phone: +63 (2) 123-4567
Address: 123 Tech Street, Makati City, Philippines

Data Protection Officer: dpo@insurevis.com

Last updated: January 1, 2025''',
                ),

                SizedBox(height: 30.h),

                // Contact Button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: ElevatedButton(
                    onPressed: () {
                      // Open email or contact form
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Contact feature will open your email app',
                          ),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalStyles.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Contact Privacy Team',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: GlobalStyles.primaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            content,
            style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.5),
          ),
        ],
      ),
    );
  }
}
