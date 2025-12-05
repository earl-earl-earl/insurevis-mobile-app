import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _appBarAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _appBarFadeAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _appBarFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _appBarAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _contentFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _appBarAnimationController.forward();
    Future.delayed(
      const Duration(milliseconds: 200),
      () => _contentAnimationController.forward(),
    );
  }

  @override
  void dispose() {
    _appBarAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
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
          onPressed: () async {
            await HapticFeedback.lightImpact();
            if (mounted) Navigator.pop(context);
          },
        ),
        title: FadeTransition(
          opacity: _appBarFadeAnimation,
          child: Text(
            'Terms of Service',
            style: TextStyle(
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeH5,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              fontFamily: GlobalStyles.fontFamilyHeading,
            ),
          ),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: SlideTransition(
            position: _contentSlideAnimation,
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedSection(
                      index: 0,
                      title: '1. Acceptance of Terms',
                      content:
                          'By downloading, installing, or using the InsureVis mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.',
                    ),
                    _buildAnimatedSection(
                      index: 1,
                      title: '2. Description of Service',
                      content:
                          'InsureVis is a mobile application that provides vehicle damage assessment and insurance claim assistance services. The App uses artificial intelligence and image recognition technology to analyze vehicle damage and provide repair cost estimates.',
                    ),
                    _buildAnimatedSection(
                      index: 2,
                      title: '3. User Responsibilities',
                      content:
                          '''• You must be at least 18 years old to use this App
• You are responsible for maintaining the security of your account
• You agree to provide accurate and complete information
• You will not use the App for any illegal or unauthorized purpose
• You will not interfere with or disrupt the App's functionality''',
                    ),
                    _buildAnimatedSection(
                      index: 3,
                      title: '4. Data Collection and Privacy',
                      content:
                          'We collect and process personal data in accordance with our Privacy Policy. By using the App, you consent to the collection, use, and sharing of your information as described in our Privacy Policy.',
                    ),
                    _buildAnimatedSection(
                      index: 4,
                      title: '5. Accuracy of Damage Assessments',
                      content:
                          '''• Damage assessments provided by the App are estimates only
• Results may vary and should not be considered as final insurance claims
• We recommend professional inspection for accurate damage evaluation
• The App is a tool to assist with insurance claims, not replace professional assessment''',
                    ),
                    _buildAnimatedSection(
                      index: 5,
                      title: '6. Intellectual Property',
                      content:
                          'All content, features, and functionality of the App are owned by InsureVis and are protected by international copyright, trademark, and other intellectual property laws.',
                    ),
                    _buildAnimatedSection(
                      index: 6,
                      title: '7. Limitation of Liability',
                      content: '''InsureVis shall not be liable for:
• Any indirect, incidental, special, or consequential damages
• Loss of profits, data, or use arising from your use of the App
• Any damages resulting from reliance on damage assessments
• Technical issues or service interruptions''',
                    ),
                    _buildAnimatedSection(
                      index: 7,
                      title: '8. Disclaimers',
                      content:
                          '''• The App is provided "as is" without warranties of any kind
• We do not guarantee the accuracy of damage assessments
• Service availability may be subject to maintenance and updates
• Results may vary based on image quality and vehicle conditions''',
                    ),
                    _buildAnimatedSection(
                      index: 8,
                      title: '9. Account Termination',
                      content:
                          'We reserve the right to terminate or suspend your account at any time for violations of these Terms or for any other reason at our sole discretion.',
                    ),
                    _buildAnimatedSection(
                      index: 9,
                      title: '10. Updates and Modifications',
                      content:
                          'We reserve the right to modify these Terms at any time. Changes will be effective when posted in the App. Continued use of the App constitutes acceptance of modified Terms.',
                    ),
                    _buildAnimatedSection(
                      index: 10,
                      title: '11. Governing Law',
                      content:
                          'These Terms are governed by and construed in accordance with the laws of the Philippines. Any disputes shall be resolved in the courts of the Philippines.',
                    ),
                    _buildAnimatedSection(
                      index: 11,
                      title: '12. Contact Information',
                      content:
                          '''If you have questions about these Terms, please contact us:

Email: support@insurevis.com
Phone: +63 (2) 123-4567
Address: 123 Tech Street, Makati City, Philippines

Last updated: January 1, 2025''',
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({
    required int index,
    required String title,
    required String content,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 10),
              child: child,
            ),
          ),
      child: _buildSection(title: title, content: content),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: GlobalStyles.textPrimary.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: GlobalStyles.textPrimary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: GlobalStyles.textPrimary.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.fileText,
                  color: GlobalStyles.primaryMain,
                  size: GlobalStyles.iconSizeSm,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: GlobalStyles.primaryMain,
                    fontSize: GlobalStyles.fontSizeH6,
                    fontWeight: GlobalStyles.fontWeightSemiBold,
                    fontFamily: GlobalStyles.fontFamilyHeading,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeBody2,
              height: 1.6,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
          ),
        ],
      ),
    );
  }
}
