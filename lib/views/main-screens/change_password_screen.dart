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

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
            fontSize: GlobalStyles.fontSizeBody1,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            fontFamily: GlobalStyles.fontFamilyHeading,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: GlobalStyles.surfaceMain),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: isKeyboardVisible ? 20.h : 40.h),

                Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeH2,
                    fontWeight: GlobalStyles.fontWeightBold,
                    fontFamily: GlobalStyles.fontFamilyHeading,
                    color: GlobalStyles.textPrimary,
                  ),
                ),
                SizedBox(height: GlobalStyles.paddingTight),
                Text(
                  'Update your account password below.',
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeBody2,
                    color: GlobalStyles.textSecondary,
                    fontFamily: GlobalStyles.fontFamilyBody,
                  ),
                ),

                SizedBox(height: isKeyboardVisible ? 30.h : 60.h),

                _buildPasswordField(
                  label: 'Current Password',
                  controller: _currentPasswordController,
                  hint: 'Enter your current password',
                  error: _currentPasswordError,
                  obscure: _obscureCurrent,
                  onToggle:
                      () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),

                SizedBox(height: 24.h),

                _buildPasswordField(
                  label: 'New Password',
                  controller: _newPasswordController,
                  hint: 'Enter new password',
                  error: _newPasswordError,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),

                SizedBox(height: 24.h),

                _buildPasswordField(
                  label: 'Confirm New Password',
                  controller: _confirmPasswordController,
                  hint: 'Confirm new password',
                  obscure: _obscureConfirm,
                  onToggle:
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),

                SizedBox(height: 32.h),

                _isLoading
                    ? AuthWidgetUtils.buildLoadingButton()
                    : AuthWidgetUtils.buildPrimaryButton(
                      onPressed: _changePassword,
                      text: 'Change Password',
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
