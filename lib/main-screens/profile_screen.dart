import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/other-screens/settings_screen.dart';
import 'package:insurevis/other-screens/terms_of_service_screen.dart';
import 'package:insurevis/other-screens/privacy_policy_screen.dart';
import 'package:insurevis/other-screens/contact_us_screen.dart';
import 'package:insurevis/other-screens/faq_screen.dart';
import 'package:insurevis/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20.h),

                // Profile picture container
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(26), // 0.1 * 255
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 70.sp,
                      color: Colors.white38,
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                Text(
                  'General',
                  style: TextStyle(
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
                  subtitle: 'Change name, email id',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                _buildSettingItem(
                  icon: Icons.backup_outlined,
                  title: 'Data Backup/Restore',
                  subtitle: 'Change number, email id',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                _buildSettingItem(
                  icon: Icons.settings_outlined,
                  title: 'Preferences',
                  subtitle: 'Theme, other preferences',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                _buildSettingItem(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'Change language preference',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: 20.h),

                Text(
                  'Notification',
                  style: TextStyle(
                    color: GlobalStyles.primaryColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),

                SizedBox(height: 10.h),

                _buildToggleItem(
                  icon: Icons.notifications_outlined,
                  title: 'Enable Notification',
                  subtitle: 'Turn on updates/verifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),

                SizedBox(height: 20.h),

                Text(
                  'App Info',
                  style: TextStyle(
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
                      MaterialPageRoute(
                        builder: (context) => const FAQScreen(),
                      ),
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

                SizedBox(height: 80.h),
              ],
            ),
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
        leading: Icon(icon, color: Colors.white70, size: 24.sp),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.white54, size: 20.sp),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool? value,
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13), // 0.05 * 255
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.white70, size: 24.sp),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
        value: value ?? true,
        activeColor: GlobalStyles.primaryColor,
        onChanged: onChanged ?? (value) {},
      ),
    );
  }
}
