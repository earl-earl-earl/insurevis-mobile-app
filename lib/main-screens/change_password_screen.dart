import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:insurevis/global_ui_variables.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _currentPasswordError;
  String? _newPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 14.sp)),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
    });

    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (currentPass.isEmpty) {
      setState(() => _currentPasswordError = 'Please enter your current password');
      return;
    }

    if (newPass.isEmpty) {
      setState(() => _newPasswordError = 'Please enter a new password');
      return;
    }

    if (newPass != confirm) {
      setState(() => _newPasswordError = 'Passwords do not match');
      return;
    }

    if (currentPass == newPass) {
      setState(() => _newPasswordError = 'New password must be different from current password');
      return;
    }

    final passErr = SupabaseService.validatePassword(newPass);
    if (passErr != null) {
      setState(() => _newPasswordError = passErr);
      return;
    }

    setState(() => _isLoading = true);
    
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final result = await SupabaseService.changePassword(
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: GoogleFonts.inter(
              color: const Color(0x992A2A2A),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            children: isRequired ? [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ] : null,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: TextField(
            controller: controller,
            obscureText: true,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF2A2A2A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: const Color(0x992A2A2A),
                fontSize: 14.sp,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 18.h,
                horizontal: 16.w,
              ),
              filled: true,
              fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.primaryColor,
                  width: 1.5.w,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.red[300]!,
                  width: 1.5.w,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.red[300]!,
                  width: 1.5.w,
                ),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[300],
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  error,
                  style: GoogleFonts.inter(
                    color: Colors.red[300],
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: GlobalStyles.buildCustomAppBar(
        context: context,
        icon: Icons.arrow_back_rounded,
        color: const Color(0xFF2A2A2A),
        appBarBackgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: Colors.white),
          child: Padding(
            padding: GlobalStyles.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: isKeyboardVisible ? 20.h : 40.h),

                Text(
                  'Change Password',
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Update your account password below.',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0x992A2A2A),
                  ),
                ),

                SizedBox(height: isKeyboardVisible ? 30.h : 60.h),

                _buildPasswordField(
                  label: 'Current Password',
                  controller: _currentPasswordController,
                  hint: 'Enter your current password',
                  error: _currentPasswordError,
                ),

                SizedBox(height: 24.h),

                _buildPasswordField(
                  label: 'New Password',
                  controller: _newPasswordController,
                  hint: 'Enter new password',
                  error: _newPasswordError,
                ),

                SizedBox(height: 24.h),

                _buildPasswordField(
                  label: 'Confirm New Password',
                  controller: _confirmPasswordController,
                  hint: 'Confirm new password',
                ),

                SizedBox(height: 32.h),

                _isLoading
                    ? Container(
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: GlobalStyles.primaryColor.withAlpha(180),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalStyles.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          minimumSize: Size(double.infinity, 60.h),
                        ),
                        child: Text(
                          'Change Password',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}