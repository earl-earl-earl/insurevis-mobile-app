import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/views/main-screens/change_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/terms_of_service_screen.dart';
import 'package:insurevis/other-screens/privacy_policy_screen.dart';
import 'package:insurevis/other-screens/contact_us_screen.dart';
import 'package:insurevis/other-screens/faq_screen.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/utils/profile_widget_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../other-screens/personal_data_screen.dart';
import 'package:insurevis/views/main-screens/delete_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // bool _notificationsEnabled = true;

  Color color = ProfileWidgetUtils.randomColor();

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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              // Profile picture container
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.currentUser;
                  final initial = ProfileWidgetUtils.getFirstLetterOfName(
                    user?.name,
                  );
                  return ProfileWidgetUtils.buildProfileAvatar(
                    initial: initial,
                    color: color,
                  );
                },
              ),
              SizedBox(height: 20.h),
              // Display user data from AuthProvider with fallback
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.currentUser;
                  // Fallback to default values if no user is logged in
                  final userName = user?.name ?? 'Demo User';
                  final userEmail = user?.email ?? 'demo@insurevis.com';

                  return Column(
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          color: GlobalStyles.textPrimary,
                          fontSize: GlobalStyles.fontSizeH4,
                          fontWeight: GlobalStyles.fontWeightBold,
                          fontFamily: GlobalStyles.fontFamilyHeading,
                        ),
                      ),
                      Text(
                        userEmail,
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

              SizedBox(height: 40.h),

              // Text(
              //   'General',
              //   style: GoogleFonts.inter(
              //     color: GlobalStyles.primaryColor,
              //     fontSize: 16.sp,
              //     fontWeight: FontWeight.bold,
              //   ),
              //   textAlign: TextAlign.left,
              // ),

              // SizedBox(height: 10.h),
              ProfileWidgetUtils.buildSectionHeader('Personal Details'),

              SizedBox(height: 10.h),

              ProfileWidgetUtils.buildSettingItem(
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

              ProfileWidgetUtils.buildSectionHeader('Account Security'),

              SizedBox(height: 10.h),

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

              // _buildSettingItem(
              //   icon: Icons.backup_outlined,
              //   title: 'Data Backup/Restore',
              //   subtitle: 'Change number, email id',
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const SettingsScreen(),
              //       ),
              //     );
              //   },
              // ),

              // _buildSettingItem(
              //   icon: Icons.settings_outlined,
              //   title: 'Preferences',
              //   subtitle: 'Theme, other preferences',
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const SettingsScreen(),
              //       ),
              //     );
              //   },
              // ),

              // _buildSettingItem(
              //   icon: Icons.language_outlined,
              //   title: 'Language',
              //   subtitle: 'Change language preference',
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const SettingsScreen(),
              //       ),
              //     );
              //   },
              // ),

              // SizedBox(height: 20.h),

              // Text(
              //   'Notification',
              //   style: GoogleFonts.inter(
              //     color: GlobalStyles.primaryColor,
              //     fontSize: 16.sp,
              //     fontWeight: FontWeight.bold,
              //   ),
              //   textAlign: TextAlign.left,
              // ),

              // SizedBox(height: 10.h),

              // _buildToggleItem(
              //   icon: Icons.notifications_outlined,
              //   title: 'Enable Notification',
              //   subtitle: 'Turn on updates/verifications',
              //   value: _notificationsEnabled,
              //   onChanged: (value) {
              //     setState(() {
              //       _notificationsEnabled = value;
              //     });
              //   },
              // ),
              SizedBox(height: 20.h),

              ProfileWidgetUtils.buildSectionHeader('App Info'),

              SizedBox(height: 10.h),

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

              ProfileWidgetUtils.buildSettingItem(
                icon: LucideIcons.bookOpen,
                title: 'FAQ',
                subtitle: 'Get in touch with us',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FAQScreen()),
                  );
                },
              ),

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

              SizedBox(height: 20.h),

              // Logout button placed at the bottom of the profile page
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalStyles.errorMain,
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
                                  final success = await authProvider.signOut();
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Signed out')),
                                    );
                                    // Navigate to sign-in and clear navigation stack
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/signin',
                                      (route) => false,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          authProvider.error ??
                                              'Sign out failed',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        child: Text(
                          authProvider.isSigningOut
                              ? 'Signing out...'
                              : 'Log out',
                          style: TextStyle(
                            color: GlobalStyles.surfaceMain,
                            fontSize: GlobalStyles.fontSizeBody1,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                            fontFamily: GlobalStyles.fontFamilyBody,
                          ),
                        ),
                      ),
                    );
                  },
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
