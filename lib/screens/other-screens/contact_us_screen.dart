import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _cardControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: GlobalStyles.durationNormal,
        vsync: this,
      ),
    );

    _cardAnimations =
        _cardControllers.map((controller) {
          return Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: controller,
              curve: GlobalStyles.easingDecelerate,
            ),
          );
        }).toList();

    // Stagger animations
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _cardControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: _buildAppBar(context) as PreferredSizeWidget,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: GlobalStyles.paddingNormal,
            vertical: GlobalStyles.paddingLoose,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(),
              SizedBox(height: GlobalStyles.spacingXl),

              // Contact Cards
              ..._buildContactCards(),

              // Additional Help Section
              SizedBox(height: GlobalStyles.spacingXl),
              _buildAdditionalHelp(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
        'Contact Us',
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need help? Get in touch',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyHeading,
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeH2,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            letterSpacing: GlobalStyles.letterSpacingH2,
            height: GlobalStyles.lineHeightH2 / GlobalStyles.fontSizeH2,
          ),
        ),
        SizedBox(height: GlobalStyles.spacingMd),
        Text(
          'Our support team is ready to assist you. Choose your preferred contact method below.',
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: GlobalStyles.textTertiary,
            fontSize: GlobalStyles.fontSizeBody1,
            fontWeight: GlobalStyles.fontWeightRegular,
            height: GlobalStyles.lineHeightBody1 / GlobalStyles.fontSizeBody1,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContactCards() {
    final contacts = [
      {
        'icon': LucideIcons.mail,
        'title': 'Email Support',
        'subtitle': 'support@insurevis.com',
        'description': 'Detailed responses within 24 hours',
        'color': Color(0xFF64B5F6),
      },
      {
        'icon': LucideIcons.phone,
        'title': 'Phone Support',
        'subtitle': '+63 (2) 123-4567',
        'description': 'Mon-Fri, 9:00 AM - 6:00 PM',
        'color': Color(0xFF81C784),
      },
      {
        'icon': LucideIcons.messageCircle,
        'title': 'Live Chat',
        'subtitle': 'Chat with our team',
        'description': 'Available 24/7 for quick assistance',
        'color': Color(0xFFBA68C8),
      },
    ];

    return List.generate(
      contacts.length,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: GlobalStyles.spacingMd),
        child: FadeTransition(
          opacity: _cardAnimations[index],
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _cardControllers[index],
                curve: GlobalStyles.easingDecelerate,
              ),
            ),
            child: _buildContactCard(
              icon: contacts[index]['icon'] as IconData,
              title: contacts[index]['title'] as String,
              subtitle: contacts[index]['subtitle'] as String,
              description: contacts[index]['description'] as String,
              accentColor: contacts[index]['color'] as Color,
              onTap: () {
                _handleContactTap(index, contacts[index]['title'] as String);
              },
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
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusXl),
        splashColor: accentColor.withOpacity(0.1),
        highlightColor: accentColor.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.all(GlobalStyles.paddingNormal),
          decoration: BoxDecoration(
            color: GlobalStyles.surfaceMain,
            borderRadius: BorderRadius.circular(GlobalStyles.radiusXl),
            boxShadow: [GlobalStyles.cardShadow],
            border: Border(left: BorderSide(color: accentColor, width: 4)),
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: GlobalStyles.minTouchTarget + GlobalStyles.spacingSm,
                height: GlobalStyles.minTouchTarget + GlobalStyles.spacingSm,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: GlobalStyles.iconSizeMd,
                ),
              ),
              SizedBox(width: GlobalStyles.spacingMd),

              // Content
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
                        letterSpacing: GlobalStyles.letterSpacingH4,
                      ),
                    ),
                    SizedBox(height: GlobalStyles.spacingXs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        color: accentColor,
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

              // Chevron Icon
              Padding(
                padding: EdgeInsets.only(left: GlobalStyles.spacingMd),
                child: Icon(
                  LucideIcons.chevronRight,
                  color: GlobalStyles.textDisabled,
                  size: GlobalStyles.iconSizeMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalHelp() {
    return Container(
      padding: EdgeInsets.all(GlobalStyles.paddingNormal),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withOpacity(0.08),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
        border: Border.all(
          color: GlobalStyles.primaryMain.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: GlobalStyles.iconSizeLg,
            height: GlobalStyles.iconSizeLg,
            decoration: BoxDecoration(
              color: GlobalStyles.primaryMain.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.lightbulb,
              color: GlobalStyles.primaryMain,
              size: GlobalStyles.iconSizeSm,
            ),
          ),
          SizedBox(width: GlobalStyles.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick tip',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    color: GlobalStyles.textPrimary,
                    fontSize: GlobalStyles.fontSizeBody1,
                    fontWeight: GlobalStyles.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: GlobalStyles.spacingXs),
                Text(
                  'Check our FAQ section for instant answers to common questions.',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textSecondary,
                    fontSize: GlobalStyles.fontSizeBody2,
                    fontWeight: GlobalStyles.fontWeightRegular,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleContactTap(int index, String contactMethod) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $contactMethod...'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(GlobalStyles.paddingNormal),
      ),
    );
  }
}
