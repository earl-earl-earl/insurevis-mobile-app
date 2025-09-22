import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2A2A2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms of Service',
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: '1. Acceptance of Terms',
                  content:
                      'By downloading, installing, or using the InsureVis mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.',
                ),

                _buildSection(
                  title: '2. Description of Service',
                  content:
                      'InsureVis is a mobile application that provides vehicle damage assessment and insurance claim assistance services. The App uses artificial intelligence and image recognition technology to analyze vehicle damage and provide repair cost estimates.',
                ),

                _buildSection(
                  title: '3. User Responsibilities',
                  content:
                      '''• You must be at least 18 years old to use this App
• You are responsible for maintaining the security of your account
• You agree to provide accurate and complete information
• You will not use the App for any illegal or unauthorized purpose
• You will not interfere with or disrupt the App's functionality''',
                ),

                _buildSection(
                  title: '4. Data Collection and Privacy',
                  content:
                      'We collect and process personal data in accordance with our Privacy Policy. By using the App, you consent to the collection, use, and sharing of your information as described in our Privacy Policy.',
                ),

                _buildSection(
                  title: '5. Accuracy of Damage Assessments',
                  content:
                      '''• Damage assessments provided by the App are estimates only
• Results may vary and should not be considered as final insurance claims
• We recommend professional inspection for accurate damage evaluation
• The App is a tool to assist with insurance claims, not replace professional assessment''',
                ),

                _buildSection(
                  title: '6. Intellectual Property',
                  content:
                      'All content, features, and functionality of the App are owned by InsureVis and are protected by international copyright, trademark, and other intellectual property laws.',
                ),

                _buildSection(
                  title: '7. Limitation of Liability',
                  content: '''InsureVis shall not be liable for:
• Any indirect, incidental, special, or consequential damages
• Loss of profits, data, or use arising from your use of the App
• Any damages resulting from reliance on damage assessments
• Technical issues or service interruptions''',
                ),

                _buildSection(
                  title: '8. Disclaimers',
                  content:
                      '''• The App is provided "as is" without warranties of any kind
• We do not guarantee the accuracy of damage assessments
• Service availability may be subject to maintenance and updates
• Results may vary based on image quality and vehicle conditions''',
                ),

                _buildSection(
                  title: '9. Account Termination',
                  content:
                      'We reserve the right to terminate or suspend your account at any time for violations of these Terms or for any other reason at our sole discretion.',
                ),

                _buildSection(
                  title: '10. Updates and Modifications',
                  content:
                      'We reserve the right to modify these Terms at any time. Changes will be effective when posted in the App. Continued use of the App constitutes acceptance of modified Terms.',
                ),

                _buildSection(
                  title: '11. Governing Law',
                  content:
                      'These Terms are governed by and construed in accordance with the laws of the Philippines. Any disputes shall be resolved in the courts of the Philippines.',
                ),

                _buildSection(
                  title: '12. Contact Information',
                  content:
                      '''If you have questions about these Terms, please contact us:

Email: support@insurevis.com
Phone: +63 (2) 123-4567
Address: 123 Tech Street, Makati City, Philippines

Last updated: January 1, 2025''',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Color(0xFF2A2A2A),
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            content,
            style: GoogleFonts.inter(
              color: Color(0xFF2A2A2A),
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
