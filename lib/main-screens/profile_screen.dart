import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurevis/main-screens/change_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/terms_of_service_screen.dart';
import 'package:insurevis/other-screens/privacy_policy_screen.dart';
import 'package:insurevis/other-screens/contact_us_screen.dart';
import 'package:insurevis/other-screens/faq_screen.dart';
import 'package:insurevis/providers/auth_provider.dart';

import '../other-screens/personal_data_screen.dart';
import 'package:insurevis/main-screens/delete_account_screen.dart';

// Returns a random Color from [colors]. If [colors] is null or empty,
// a small default palette is used. The function is private to this file.
Color _randomColor([List<Color>? colors]) {
  final palette =
      (colors == null || colors.isEmpty)
          ? <Color>[
            Colors.red,
            Colors.orange,
            Colors.amber,
            Colors.green,
            Colors.blue,
            Colors.indigo,
            Colors.purple,
            Colors.teal,
            Colors.cyan,
          ]
          : colors;

  final rnd = Random();
  return palette[rnd.nextInt(palette.length)];
}

// Returns the first non-empty letter from [fullName], uppercased.
// If the name is null/empty returns a fallback 'D' (for Demo).
String _firstLetterOfName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return 'D';
  final trimmed = fullName.trim();
  return trimmed.characters.first.toUpperCase();
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // bool _notificationsEnabled = true;

  Color color = _randomColor();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: Color(0xFF2A2A2A),
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF2A2A2A)),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              // Profile picture container
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(
                    alpha: 0.15,
                  ), // subtle tinted background
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Center(
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.currentUser;
                      final initial = _firstLetterOfName(user?.name);
                      return Text(
                        initial,
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 58.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
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
                        style: GoogleFonts.inter(
                          color: Color(0xFF2A2A2A),
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: GoogleFonts.inter(
                          color: Color(0x992A2A2A),
                          fontSize: 14.sp,
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
              Text(
                'Personal Details',
                style: GoogleFonts.inter(
                  color: GlobalStyles.primaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),

              SizedBox(height: 10.h),

              _buildSettingItem(
                icon: Icons.person_outline,
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

              Text(
                'Account Security',
                style: GoogleFonts.inter(
                  color: GlobalStyles.primaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),

              SizedBox(height: 10.h),

              _buildSettingItem(
                icon: Icons.person_outline,
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

              _buildSettingItem(
                icon: Icons.delete_outline,
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

              Text(
                'App Info',
                style: GoogleFonts.inter(
                  color: GlobalStyles.primaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),

              SizedBox(height: 10.h),

              _buildSettingItem(
                icon: Icons.contact_support_outlined,
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

              _buildSettingItem(
                icon: Icons.policy_outlined,
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

              _buildSettingItem(
                icon: Icons.help_outline,
                title: 'FAQ',
                subtitle: 'Get in touch with us',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FAQScreen()),
                  );
                },
              ),

              _buildSettingItem(
                icon: Icons.description_outlined,
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
                          backgroundColor: Colors.redAccent,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13), // 0.05 * 255
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Color(0x992A2A2A), size: 24.sp),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Color(0xFF2A2A2A),
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(color: Color(0x772A2A2A), fontSize: 12.sp),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Color(0x772A2A2A),
          size: 20.sp,
        ),
        onTap: onTap,
      ),
    );
  }
}
