import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  // Contact-only screen; no form controllers needed.

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.surfaceMain,
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
          'Contact Us',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyHeading,
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeH4,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            letterSpacing: GlobalStyles.letterSpacingH4,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [GlobalStyles.surfaceMain, GlobalStyles.backgroundMain],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: GlobalStyles.paddingNormal,
              vertical: GlobalStyles.paddingLoose,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help? Get in touch',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    color: GlobalStyles.primaryMain,
                    fontSize: GlobalStyles.fontSizeH3,
                    fontWeight: GlobalStyles.fontWeightSemiBold,
                    letterSpacing: GlobalStyles.letterSpacingH3,
                  ),
                ),

                SizedBox(height: GlobalStyles.spacingSm),

                Text(
                  'Our support team is happy to help you with any questions or issues. Choose a contact method below.',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textTertiary,
                    fontSize: GlobalStyles.fontSizeBody2,
                    fontWeight: GlobalStyles.fontWeightRegular,
                    height:
                        GlobalStyles.lineHeightBody2 /
                        GlobalStyles.fontSizeBody2,
                  ),
                ),

                SizedBox(height: GlobalStyles.spacingLg),

                _buildContactCard(
                  icon: LucideIcons.mail,
                  title: 'Email Support',
                  subtitle: 'support@insurevis.com',
                  description: 'Get help via email',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening email app...')),
                    );
                  },
                ),

                _buildContactCard(
                  icon: LucideIcons.phone,
                  title: 'Phone Support',
                  subtitle: '+63 (2) 123-4567',
                  description: 'Mon-Fri 9AM-6PM',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening phone dialer...')),
                    );
                  },
                ),

                _buildContactCard(
                  icon: LucideIcons.messageCircle,
                  title: 'Live Chat',
                  subtitle: 'Chat with support',
                  description: 'Available 24/7',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live chat coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GlobalStyles.radiusXl),
      child: Container(
        margin: EdgeInsets.only(bottom: GlobalStyles.spacingMd),
        padding: EdgeInsets.symmetric(
          horizontal: GlobalStyles.paddingNormal,
          vertical: GlobalStyles.paddingNormal,
        ),
        decoration: BoxDecoration(
          color: GlobalStyles.surfaceMain,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusXl),
          boxShadow: [GlobalStyles.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: GlobalStyles.minTouchTarget + GlobalStyles.spacingSm,
              height: GlobalStyles.minTouchTarget + GlobalStyles.spacingSm,
              decoration: BoxDecoration(
                color: GlobalStyles.primaryMain,
                shape: BoxShape.circle,
                boxShadow: [GlobalStyles.shadowMd],
              ),
              child: Icon(
                icon,
                color: GlobalStyles.surfaceMain,
                size: GlobalStyles.iconSizeMd,
              ),
            ),

            SizedBox(width: GlobalStyles.spacingMd),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyHeading,
                      color: GlobalStyles.textPrimary,
                      fontSize: GlobalStyles.fontSizeH6,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                    ),
                  ),
                  SizedBox(height: GlobalStyles.spacingXs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.textSecondary,
                      fontSize: GlobalStyles.fontSizeBody2,
                      fontWeight: GlobalStyles.fontWeightMedium,
                    ),
                  ),
                  SizedBox(height: GlobalStyles.spacingXs),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.textTertiary,
                      fontSize: GlobalStyles.fontSizeCaption,
                      fontWeight: GlobalStyles.fontWeightRegular,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              LucideIcons.chevronRight,
              color: GlobalStyles.textDisabled,
              size: GlobalStyles.iconSizeMd,
            ),
          ],
        ),
      ),
    );
  }
}
