import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/utils/password_utils.dart';
import 'package:insurevis/utils/profile_widget_utils.dart';
import 'package:insurevis/utils/auth_widget_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String? _currentPasswordError;
  String? _newPasswordError;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool success = true}) {
    AuthWidgetUtils.showSnackBar(context, message, isError: !success);
  }

  Future<void> _changePassword() async {
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
    });

    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    // Validate inputs
    final validationError = PasswordUtils.validatePasswordChange(
      currentPassword: currentPass,
      newPassword: newPass,
      confirmPassword: confirm,
    );

    if (validationError != null) {
      if (validationError.toLowerCase().contains('current')) {
        setState(() => _currentPasswordError = validationError);
      } else {
        setState(() => _newPasswordError = validationError);
      }
      return;
    }

    setState(() => _isLoading = true);

    // Keep reference to currentUser to preserve imports and potential future use
    // ignore: unused_local_variable
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final result = await PasswordUtils.changePassword(
      currentPassword: currentPass,
      newPassword: newPass,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnack(result['message'] ?? 'Password changed successfully');
      if (mounted) Navigator.of(context).pop();
    } else {
      final msg = result['message'] ?? 'Failed to change password';
      if (msg.toLowerCase().contains('current password')) {
        setState(() => _currentPasswordError = msg);
      } else {
        _showSnack(msg, success: false);
      }
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? error,
    bool isRequired = true,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return ProfileWidgetUtils.buildPasswordField(
      label: label,
      controller: controller,
      hint: hint,
      error: error,
      isRequired: isRequired,
      obscure: obscure,
      onToggle: onToggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: GlobalStyles.textSecondary,
            size: GlobalStyles.iconSizeMd,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Change Password',
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
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(color: GlobalStyles.surfaceMain),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: isKeyboardVisible ? 16.h : 32.h),

                  // Animated header with icon
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
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            GlobalStyles.primaryMain.withValues(alpha: 0.08),
                            GlobalStyles.primaryMain.withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.radiusMd,
                        ),
                        border: Border.all(
                          color: GlobalStyles.primaryMain.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: GlobalStyles.primaryMain.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.radiusSm,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.lock,
                              color: GlobalStyles.primaryMain,
                              size: GlobalStyles.iconSizeMd,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure Your Account',
                                  style: TextStyle(
                                    fontSize: GlobalStyles.fontSizeBody1,
                                    fontWeight: GlobalStyles.fontWeightSemiBold,
                                    fontFamily: GlobalStyles.fontFamilyHeading,
                                    color: GlobalStyles.textPrimary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Keep your account safe with a strong password',
                                  style: TextStyle(
                                    fontSize: GlobalStyles.fontSizeCaption,
                                    color: GlobalStyles.textSecondary,
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isKeyboardVisible ? 24.h : 48.h),

                  // Animated password fields with staggered entrance
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
                    child: _buildPasswordField(
                      label: 'Current Password',
                      controller: _currentPasswordController,
                      hint: 'Enter your current password',
                      error: _currentPasswordError,
                      obscure: _obscureCurrent,
                      onToggle:
                          () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                    ),
                  ),

                  SizedBox(height: 20.h),

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
                    child: _buildPasswordField(
                      label: 'New Password',
                      controller: _newPasswordController,
                      hint: 'Enter new password',
                      error: _newPasswordError,
                      obscure: _obscureNew,
                      onToggle:
                          () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),

                  SizedBox(height: 20.h),

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
                    child: _buildPasswordField(
                      label: 'Confirm New Password',
                      controller: _confirmPasswordController,
                      hint: 'Confirm new password',
                      obscure: _obscureConfirm,
                      onToggle:
                          () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                    ),
                  ),

                  SizedBox(height: 48.h),

                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child:
                        _isLoading
                            ? AuthWidgetUtils.buildLoadingButton()
                            : AuthWidgetUtils.buildPrimaryButton(
                              onPressed: _changePassword,
                              text: 'Change Password',
                            ),
                  ),

                  SizedBox(height: isKeyboardVisible ? 16.h : 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
