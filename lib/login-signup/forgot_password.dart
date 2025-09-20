import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/services/supabase_service.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  String? _emailError;

  bool _isLoading = false;
  bool _accountFound = false;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _newPasswordError;
  // Fields used by the password input (kept intentionally generic to match
  // earlier form helper variables). These allow the TextFormField below to
  // reference the same names without being removed.
  final FocusNode focusNode = FocusNode();
  bool obscureText = true;
  TextInputType keyboardType = TextInputType.text;
  TextCapitalization textCapitalization = TextCapitalization.none;
  List<TextInputFormatter> inputFormatters = const [];
  FormFieldValidator<String>? validator;
  Widget? suffixIcon;
  String hintText = 'Enter new password';
  // visibility toggles for password fields
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    // dispose locally created focus node
    focusNode.dispose();
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
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _checkAccount() async {
    setState(() {
      _emailError = null;
      _newPasswordError = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);
    final exists = await SupabaseService.userExists(email);
    setState(() => _isLoading = false);

    if (!exists) {
      _showSnack('No account found with this email address', success: false);
      return;
    }

    setState(() => _accountFound = true);
  }

  Future<void> _performManualReset() async {
    setState(() => _newPasswordError = null);

    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPass.isEmpty) {
      setState(() => _newPasswordError = 'Please enter a new password');
      return;
    }

    if (newPass != confirm) {
      setState(() => _newPasswordError = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim().toLowerCase();
    final result = await SupabaseService.manualResetPassword(
      email: email,
      newPassword: newPass,
    );
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnack(result['message'] ?? 'Password updated');
      if (mounted) Navigator.of(context).pop();
    } else {
      final msg = result['message'] ?? 'Manual reset failed';
      _showSnack(msg, success: false);
    }
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      _emailError = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(email: email);
    setState(() => _isLoading = false);

    if (success) {
      _showSnack('Password reset email sent! Check your inbox.');
      if (mounted) Navigator.of(context).pop();
    } else {
      final errorMessage = authProvider.error ?? 'Failed to send reset email.';
      _showSnack(errorMessage, success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
                  'Forgot Password',
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Enter the email associated with your account.',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0x992A2A2A),
                  ),
                ),

                SizedBox(height: isKeyboardVisible ? 40.h : 80.h),

                Text(
                  'Email',
                  style: GoogleFonts.inter(
                    color: const Color(0x992A2A2A),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF2A2A2A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: GlobalStyles.primaryColor,
                          width: 1.5.w,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide:
                            _emailError != null
                                ? BorderSide(
                                  color: Colors.red.withAlpha(153),
                                  width: 1.5.w,
                                )
                                : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color:
                              _emailError != null
                                  ? Colors.red.withAlpha(153)
                                  : GlobalStyles.primaryColor.withAlpha(153),
                          width: 1.5.w,
                        ),
                      ),
                    ),
                  ),
                ),

                if (_emailError != null) ...[
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
                          _emailError!,
                          style: GoogleFonts.inter(
                            color: Colors.red[300],
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 24.h),

                if (_accountFound) ...[
                  Text.rich(
                    TextSpan(
                      text: 'New Password',
                      style: GoogleFonts.inter(
                        color: const Color(0x992A2A2A),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _newPasswordController,
                      obscureText: !_newPasswordVisible,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFF2A2A2A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0x992A2A2A),
                          fontSize: 14.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 18.h,
                          horizontal: 16.w,
                        ),
                        filled: true,
                        fillColor: Colors.black12.withAlpha(
                          (0.04 * 255).toInt(),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _newPasswordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20.sp,
                            color: const Color(0x992A2A2A),
                          ),
                          onPressed:
                              () => setState(
                                () =>
                                    _newPasswordVisible = !_newPasswordVisible,
                              ),
                        ),
                        border: OutlineInputBorder(
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: GlobalStyles.primaryColor.withAlpha(153),
                            width: 1.5.w,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),
                  Text.rich(
                    TextSpan(
                      text: 'Confirm Password',
                      style: GoogleFonts.inter(
                        color: const Color(0x992A2A2A),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_confirmPasswordVisible,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFF2A2A2A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0x992A2A2A),
                          fontSize: 14.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 18.h,
                          horizontal: 16.w,
                        ),
                        filled: true,
                        fillColor: Colors.black12.withAlpha(
                          (0.04 * 255).toInt(),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20.sp,
                            color: const Color(0x992A2A2A),
                          ),
                          onPressed:
                              () => setState(
                                () =>
                                    _confirmPasswordVisible =
                                        !_confirmPasswordVisible,
                              ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: GlobalStyles.primaryColor,
                            width: 1.5.w,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: GlobalStyles.primaryColor.withAlpha(153),
                            width: 1.5.w,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  if (_newPasswordError != null) ...[
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
                            _newPasswordError!,
                            style: GoogleFonts.inter(
                              color: Colors.red[300],
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 16.h),

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
                        onPressed: _performManualReset,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            GlobalStyles.primaryColor,
                          ),
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(
                              vertical: 20.h,
                              horizontal: 20.w,
                            ),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          minimumSize: WidgetStatePropertyAll(
                            Size(double.infinity, 60.h),
                          ),
                        ),
                        child: Text(
                          'Update password',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                ] else ...[
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
                      : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _checkAccount,
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                GlobalStyles.primaryColor,
                              ),
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(vertical: 16.h),
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              minimumSize: WidgetStatePropertyAll(
                                Size(double.infinity, 56.h),
                              ),
                            ),
                            child: Text(
                              'Check Account',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ),
                ],

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
