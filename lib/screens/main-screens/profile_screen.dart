import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/screens/main-screens/change_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/screens/other-screens/terms_of_service_screen.dart';
import 'package:insurevis/screens/other-screens/privacy_policy_screen.dart';
import 'package:insurevis/screens/other-screens/contact_us_screen.dart';
import 'package:insurevis/screens/other-screens/faq_screen.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/utils/profile_widget_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../other-screens/personal_data_screen.dart';
import 'package:insurevis/screens/main-screens/delete_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  Color color = ProfileWidgetUtils.randomColor();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Helper method to build animated section headers
  Widget _buildAnimatedSectionHeader(String title) {
    return SizedBox(
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: GlobalStyles.primaryMain,
                fontSize: GlobalStyles.fontSizeBody1,
                fontWeight: GlobalStyles.fontWeightBold,
                fontFamily: GlobalStyles.fontFamilyHeading,
              ),
            ),
            SizedBox(height: 8.h),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Container(
                  height: 3.h,
                  width: 45.w * value,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        GlobalStyles.primaryMain,
                        GlobalStyles.primaryMain.withValues(alpha: 0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeH5,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            fontFamily: GlobalStyles.fontFamilyHeading,
          ),
        ),
        backgroundColor: GlobalStyles.surfaceMain,
        iconTheme: IconThemeData(color: GlobalStyles.textPrimary),
      ),
      backgroundColor: GlobalStyles.backgroundMain,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              // Animated profile header container
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * 30),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        GlobalStyles.primaryMain.withValues(alpha: 0.08),
                        GlobalStyles.primaryMain.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: GlobalStyles.primaryMain.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Profile picture container
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.currentUser;
                          final initial =
                              ProfileWidgetUtils.getFirstLetterOfName(
                                user?.name,
                              );
                          return ProfileWidgetUtils.buildProfileAvatar(
                            initial: initial,
                            color: color,
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                      // Display user data from AuthProvider with fallback
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.currentUser;
                          final userName = user?.name ?? 'Demo User';
                          final userEmail = user?.email ?? 'demo@insurevis.com';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                userName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: GlobalStyles.textPrimary,
                                  fontSize: GlobalStyles.fontSizeH4,
                                  fontWeight: GlobalStyles.fontWeightBold,
                                  fontFamily: GlobalStyles.fontFamilyHeading,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                userEmail,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: GlobalStyles.textSecondary,
                                  fontSize: GlobalStyles.fontSizeBody2,
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              // Personal Details Section
              _buildAnimatedSectionHeader('Personal Details'),
              SizedBox(height: 12.h),
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
                child: ProfileWidgetUtils.buildSettingItem(
                  icon: LucideIcons.user,
                  title: 'Personal Data',
                  subtitle: 'Change name, email, phone number',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalDataScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),

              // Account Security Section
              _buildAnimatedSectionHeader('Account Security'),
              SizedBox(height: 12.h),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Column(
                  children: [
                    ProfileWidgetUtils.buildSettingItem(
                      icon: LucideIcons.lock,
                      title: 'Change Password',
                      subtitle: 'Change your account password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                    ProfileWidgetUtils.buildSettingItem(
                      icon: LucideIcons.trash2,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeleteAccountScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // App Info Section
              _buildAnimatedSectionHeader('App Info'),
              SizedBox(height: 12.h),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Column(
                  children: [
                    ProfileWidgetUtils.buildSettingItem(
                      icon: LucideIcons.headphones,
                      title: 'Contact Us',
                      subtitle: 'Contact our Customer Service',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactUsScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                    ProfileWidgetUtils.buildSettingItem(
                      icon: LucideIcons.shield,
                      title: 'Privacy Policy',
                      subtitle: 'Security notifications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                    ProfileWidgetUtils.buildSettingItem(
                      icon: LucideIcons.bookOpen,
                      title: 'FAQ',
                      subtitle: 'Get in touch with us',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FAQScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                    ProfileWidgetUtils.buildSettingItem(
                      icon: LucideIcons.file,
                      title: 'Terms of Service',
                      subtitle: 'Terms and conditions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),

              // Logout button placed at the bottom of the profile page
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * 20),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalStyles.errorMain,
                            disabledBackgroundColor: GlobalStyles.errorMain
                                .withValues(alpha: 0.4),
                            elevation: 2,
                            shadowColor: GlobalStyles.errorMain.withValues(
                              alpha: 0.3,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: GlobalStyles.paddingNormal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.radiusMd,
                              ),
                            ),
                          ),
                          onPressed:
                              authProvider.isSigningOut
                                  ? null
                                  : () async {
                                    final success =
                                        await authProvider.signOut();
                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Signed out'),
                                        ),
                                      );
                                      // Navigate to sign-in and clear navigation stack
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/signin',
                                        (route) => false,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            authProvider.error ??
                                                'Sign out failed',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child:
                                authProvider.isSigningOut
                                    ? SizedBox(
                                      key: const ValueKey('loading'),
                                      height: 20.sp,
                                      width: 20.sp,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Row(
                                      key: const ValueKey('text'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.logOut,
                                          color: GlobalStyles.surfaceMain,
                                          size: GlobalStyles.iconSizeSm,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Log out',
                                          style: TextStyle(
                                            color: GlobalStyles.surfaceMain,
                                            fontSize:
                                                GlobalStyles.fontSizeBody1,
                                            fontWeight:
                                                GlobalStyles.fontWeightSemiBold,
                                            fontFamily:
                                                GlobalStyles.fontFamilyBody,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
