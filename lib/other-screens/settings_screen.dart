import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/theme_provider.dart';
import 'package:insurevis/other-screens/terms_of_service_screen.dart';
import 'package:insurevis/other-screens/privacy_policy_screen.dart';
import 'package:insurevis/other-screens/contact_us_screen.dart';
import 'package:insurevis/other-screens/faq_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _autoBackup = true;
  String _selectedLanguage = 'English';

  final List<String> _languages = [
    'English',
    'Filipino',
    'Spanish',
    'Chinese',
    'Japanese',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _autoBackup = prefs.getBool('auto_backup') ?? true;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
    });
  }

  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('biometric_enabled', _biometricEnabled);
    await prefs.setBool('auto_backup', _autoBackup);
    await prefs.setString('selected_language', _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: GlobalStyles.getTextColor(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: GlobalStyles.getTextColor(isDarkMode),
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.getBackgroundColorStart(isDarkMode),
              GlobalStyles.getBackgroundColorEnd(isDarkMode),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // General Settings
                  _buildSectionTitle('General'),

                  _buildSettingItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Toggle between light and dark theme',
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      activeColor: GlobalStyles.primaryColor,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ),

                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: _selectedLanguage,
                    onTap: () => _showLanguageDialog(),
                  ),

                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Push notifications and alerts',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeColor: GlobalStyles.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Security Settings
                  _buildSectionTitle('Security'),

                  _buildSettingItem(
                    icon: Icons.fingerprint_outlined,
                    title: 'Biometric Login',
                    subtitle: 'Use fingerprint or face ID',
                    trailing: Switch(
                      value: _biometricEnabled,
                      activeColor: GlobalStyles.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _biometricEnabled = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ),

                  _buildSettingItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => _showChangePasswordDialog(),
                  ),

                  SizedBox(height: 20.h),

                  // Data & Storage
                  _buildSectionTitle('Data & Storage'),

                  _buildSettingItem(
                    icon: Icons.backup_outlined,
                    title: 'Auto Backup',
                    subtitle: 'Automatically backup your data',
                    trailing: Switch(
                      value: _autoBackup,
                      activeColor: GlobalStyles.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _autoBackup = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ),

                  _buildSettingItem(
                    icon: Icons.storage_outlined,
                    title: 'Storage Usage',
                    subtitle: 'View app storage usage',
                    onTap: () => _showStorageInfo(),
                  ),

                  _buildSettingItem(
                    icon: Icons.delete_outline,
                    title: 'Clear Cache',
                    subtitle: 'Clear temporary files',
                    onTap: () => _showClearCacheDialog(),
                  ),

                  SizedBox(height: 20.h),

                  // Support & Legal
                  _buildSectionTitle('Support & Legal'),

                  _buildSettingItem(
                    icon: Icons.contact_support_outlined,
                    title: 'Contact Us',
                    subtitle: 'Get help and support',
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
                    icon: Icons.help_outline,
                    title: 'FAQ',
                    subtitle: 'Frequently asked questions',
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
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
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

                  // App Info
                  _buildSectionTitle('About'),

                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    subtitle: '1.0.0 (Build 1)',
                  ),

                  _buildSettingItem(
                    icon: Icons.star_outline,
                    title: 'Rate App',
                    subtitle: 'Rate us on the app store',
                    onTap: () => _showRateAppDialog(),
                  ),

                  SizedBox(height: 30.h),

                  // Sign Out Button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: ElevatedButton(
                      onPressed: () => _showSignOutDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: Text(
        title,
        style: TextStyle(
          color: GlobalStyles.primaryColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: GlobalStyles.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: GlobalStyles.primaryColor, size: 20.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: GlobalStyles.getTextColor(isDarkMode),
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: GlobalStyles.getTextSecondaryColor(isDarkMode),
            fontSize: 12.sp,
          ),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? Icon(
                  Icons.chevron_right,
                  color: GlobalStyles.getTextSecondaryColor(isDarkMode),
                  size: 20.sp,
                )
                : null),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            'Select Language',
            style: TextStyle(color: GlobalStyles.getTextColor(isDarkMode)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                return RadioListTile<String>(
                  title: Text(
                    _languages[index],
                    style: TextStyle(
                      color: GlobalStyles.getTextColor(isDarkMode),
                    ),
                  ),
                  value: _languages[index],
                  groupValue: _selectedLanguage,
                  activeColor: GlobalStyles.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    _saveSettings();
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Change Password',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This feature will redirect you to the password change page.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to change password screen
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Storage Usage',
            style: TextStyle(color: Colors.white),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Data: 45.2 MB',
                style: TextStyle(color: Colors.white70),
              ),
              Text('Cache: 12.8 MB', style: TextStyle(color: Colors.white70)),
              Text('Images: 128.5 MB', style: TextStyle(color: Colors.white70)),
              Text(
                'Documents: 23.1 MB',
                style: TextStyle(color: Colors.white70),
              ),
              Divider(color: Colors.white30),
              Text(
                'Total: 209.6 MB',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Clear Cache',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will clear temporary files and may improve app performance. Continue?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showRateAppDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Rate Our App',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Enjoying InsureVis? Please rate us on the app store!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Open app store rating
              },
              child: const Text('Rate Now'),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle sign out logic
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
