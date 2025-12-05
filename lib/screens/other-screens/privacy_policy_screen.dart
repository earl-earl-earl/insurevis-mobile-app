import 'package:flutter/material.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<int, bool> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _sections = [
    {
      'title': 'Introduction',
      'content':
          'InsureVis ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
      'icon': 'shield',
    },
    {
      'title': 'Information We Collect',
      'content': '''Personal Information:
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
      'icon': 'database',
    },
    {
      'title': 'How We Use Your Information',
      'content': '''We use your information to:
• Provide vehicle damage assessment services
• Generate repair cost estimates
• Process insurance claims and documentation
• Improve our AI recognition algorithms
• Send notifications about your assessments
• Provide customer support
• Comply with legal obligations''',
      'icon': 'settings',
    },
    {
      'title': 'Information Sharing',
      'content': '''We may share your information with:
• Insurance companies (with your consent)
• Authorized repair shops and service providers
• Third-party service providers who assist our operations
• Legal authorities when required by law

We do not sell your personal information to third parties.''',
      'icon': 'share2',
    },
    {
      'title': 'Data Security',
      'content': '''We implement security measures including:
• Encryption of sensitive data
• Secure data transmission protocols
• Regular security audits and updates
• Access controls and authentication
• Secure cloud storage with backup systems''',
      'icon': 'lock',
    },
    {
      'title': 'Data Retention',
      'content':
          'We retain your information for as long as necessary to provide our services and comply with legal obligations. Assessment data may be kept for up to 7 years for insurance and legal purposes.',
      'icon': 'clock',
    },
    {
      'title': 'Your Rights',
      'content': '''You have the right to:
• Access your personal information
• Correct inaccurate information
• Delete your account and data
• Object to data processing
• Data portability
• Withdraw consent at any time''',
      'icon': 'user-check',
    },
    {
      'title': 'Cookies and Tracking',
      'content':
          'Our app may use cookies and similar technologies to enhance user experience, analyze app usage, and improve our services.',
      'icon': 'eye',
    },
    {
      'title': 'Third-Party Services',
      'content': '''Our app integrates with third-party services:
• Cloud storage providers
• Analytics services
• Payment processors
• Insurance API services

Each has their own privacy policies which we encourage you to review.''',
      'icon': 'box',
    },
    {
      'title': 'Children\'s Privacy',
      'content':
          'Our app is not intended for children under 18. We do not knowingly collect personal information from children under 18.',
      'icon': 'shield-alert',
    },
    {
      'title': 'International Transfers',
      'content':
          'Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place.',
      'icon': 'globe',
    },
    {
      'title': 'Changes to Privacy Policy',
      'content':
          'We may update this Privacy Policy periodically. We will notify you of any material changes through the app or by email.',
      'icon': 'refresh-cw',
    },
    {
      'title': 'Contact Us',
      'content': '''For privacy-related questions or concerns:

Email: privacy@insurevis.com
Phone: +63 (2) 123-4567
Address: 123 Tech Street, Makati City, Philippines

Data Protection Officer: dpo@insurevis.com

Last updated: January 1, 2025''',
      'icon': 'mail',
    },
  ];

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeH5,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            fontFamily: GlobalStyles.fontFamilyHeading,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: GlobalStyles.paddingNormal,
                vertical: GlobalStyles.paddingNormal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(bottom: GlobalStyles.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Privacy Matters',
                            style: TextStyle(
                              color: GlobalStyles.textPrimary,
                              fontSize: GlobalStyles.fontSizeH4,
                              fontWeight: GlobalStyles.fontWeightBold,
                              fontFamily: GlobalStyles.fontFamilyHeading,
                            ),
                          ),
                          SizedBox(height: GlobalStyles.spacingSm),
                          Text(
                            'We are committed to protecting your personal information and your right to privacy.',
                            style: TextStyle(
                              color: GlobalStyles.textSecondary,
                              fontSize: GlobalStyles.fontSizeBody2,
                              height: 1.5,
                              fontFamily: GlobalStyles.fontFamilyBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expandable sections
                  ..._buildExpandableSections(),
                  SizedBox(height: GlobalStyles.spacingLg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandableSections() {
    return List.generate(_sections.length, (index) {
      final section = _sections[index];
      final isExpanded = _expandedSections[index] ?? (index == 0);

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 50)),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: GlobalStyles.spacingMd),
          decoration: BoxDecoration(
            color: GlobalStyles.surfaceMain,
            borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
            border: Border.all(
              color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: [GlobalStyles.cardShadow],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedSections[index] = !isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                child: Padding(
                  padding: EdgeInsets.all(GlobalStyles.paddingNormal),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: EdgeInsets.all(GlobalStyles.spacingSm),
                        decoration: BoxDecoration(
                          color: GlobalStyles.primaryMain.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.radiusSm,
                          ),
                        ),
                        child: Icon(
                          _getIconData(section['icon']!),
                          color: GlobalStyles.primaryMain,
                          size: GlobalStyles.iconSizeSm,
                        ),
                      ),
                      SizedBox(width: GlobalStyles.spacingMd),
                      // Title
                      Expanded(
                        child: Text(
                          section['title']!,
                          style: TextStyle(
                            color: GlobalStyles.textPrimary,
                            fontSize: GlobalStyles.fontSizeBody1,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                            fontFamily: GlobalStyles.fontFamilyHeading,
                          ),
                        ),
                      ),
                      // Chevron
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          LucideIcons.chevronDown,
                          color: GlobalStyles.textSecondary,
                          size: GlobalStyles.iconSizeMd,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable content
              if (isExpanded) ...[
                Divider(
                  color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
                  height: 1,
                  indent: GlobalStyles.paddingNormal,
                  endIndent: GlobalStyles.paddingNormal,
                ),
                Padding(
                  padding: EdgeInsets.all(GlobalStyles.paddingNormal),
                  child: Text(
                    section['content']!,
                    style: TextStyle(
                      color: GlobalStyles.textSecondary,
                      fontSize: GlobalStyles.fontSizeBody2,
                      height: 1.6,
                      fontFamily: GlobalStyles.fontFamilyBody,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'shield':
        return LucideIcons.shieldCheck;
      case 'database':
        return LucideIcons.database;
      case 'settings':
        return LucideIcons.settings;
      case 'share2':
        return LucideIcons.share2;
      case 'lock':
        return LucideIcons.lock;
      case 'clock':
        return LucideIcons.clock;
      case 'user-check':
        return LucideIcons.userCheck;
      case 'eye':
        return LucideIcons.eye;
      case 'box':
        return LucideIcons.box;
      case 'shield-alert':
        return LucideIcons.shieldAlert;
      case 'globe':
        return LucideIcons.globe;
      case 'refresh-cw':
        return LucideIcons.refreshCw;
      case 'mail':
        return LucideIcons.mail;
      default:
        return LucideIcons.shieldCheck;
    }
  }
}
