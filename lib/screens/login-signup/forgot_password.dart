import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/utils/auth_handler_utils.dart';
import 'package:insurevis/utils/auth_widget_utils.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword>
    with TickerProviderStateMixin {
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

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Slide animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });

    // Auto-focus email field
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _emailFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    focusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool success = true}) {
    AuthWidgetUtils.showSnackBar(context, message, isError: !success);
  }

  Future<void> _checkAccount() async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _emailError = null;
      _newPasswordError = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      HapticFeedback.mediumImpact();
      setState(() => _emailError = 'Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);
    final exists = await AuthHandlerUtils.checkAccountExists(email);
    setState(() => _isLoading = false);

    if (!exists) {
      HapticFeedback.mediumImpact();
      _showSnack('No account found with this email address', success: false);
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _accountFound = true);
  }

  Future<void> _performManualReset() async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _newPasswordError = null);

    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPass.isEmpty) {
      HapticFeedback.mediumImpact();
      setState(() => _newPasswordError = 'Please enter a new password');
      return;
    }

    if (newPass != confirm) {
      HapticFeedback.mediumImpact();
      setState(() => _newPasswordError = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim().toLowerCase();
    final result = await AuthHandlerUtils.handleManualPasswordReset(
      email: email,
      newPassword: newPass,
    );
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      HapticFeedback.heavyImpact();
      _showSnack(result['message'] ?? 'Password updated');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop();
    } else {
      HapticFeedback.mediumImpact();
      final msg = result['message'] ?? 'Manual reset failed';
      _showSnack(msg, success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: GlobalStyles.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(color: GlobalStyles.backgroundMain),
              child: Padding(
                padding: EdgeInsets.all(GlobalStyles.paddingNormal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: isKeyboardVisible ? 20.h : 40.h),

                    Text(
                      'Forgot Password',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyHeading,
                        fontSize: GlobalStyles.fontSizeH2,
                        fontWeight: GlobalStyles.fontWeightBold,
                        color: GlobalStyles.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Enter the email associated with your account.',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        fontSize: GlobalStyles.fontSizeBody2,
                        color: GlobalStyles.textTertiary,
                      ),
                    ),

                    SizedBox(height: isKeyboardVisible ? 40.h : 80.h),

                    Text(
                      'Email',
                      style: TextStyle(
                        fontFamily: GlobalStyles.fontFamilyBody,
                        color: GlobalStyles.textTertiary,
                        fontSize: GlobalStyles.fontSizeBody2,
                        fontWeight: GlobalStyles.fontWeightSemiBold,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          GlobalStyles.inputBorderRadius,
                        ),
                        boxShadow: [GlobalStyles.shadowSm],
                      ),
                      child: TextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontSize: GlobalStyles.fontSizeBody2,
                          color: GlobalStyles.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            color: GlobalStyles.textTertiary,
                            fontSize: GlobalStyles.fontSizeBody2,
                          ),
                          contentPadding: GlobalStyles.inputPadding,
                          filled: true,
                          fillColor: GlobalStyles.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GlobalStyles.inputBorderRadius,
                            ),
                            borderSide: BorderSide(
                              color: GlobalStyles.inputBorderColor,
                              width: 1.w,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GlobalStyles.inputBorderRadius,
                            ),
                            borderSide:
                                _emailError != null
                                    ? BorderSide(
                                      color: GlobalStyles.errorMain,
                                      width: 1.5.w,
                                    )
                                    : BorderSide(
                                      color: GlobalStyles.inputBorderColor,
                                      width: 1.w,
                                    ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GlobalStyles.inputBorderRadius,
                            ),
                            borderSide: BorderSide(
                              color:
                                  _emailError != null
                                      ? GlobalStyles.errorMain
                                      : GlobalStyles.inputFocusBorderColor,
                              width: 1.5.w,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_emailError != null) ...[
                      SizedBox(height: GlobalStyles.spacingSm),
                      AuthWidgetUtils.buildErrorText(_emailError!),
                    ],

                    SizedBox(height: 24.h),

                    if (_accountFound) ...[
                      Text.rich(
                        TextSpan(
                          text: 'New Password',
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            color: GlobalStyles.textTertiary,
                            fontSize: GlobalStyles.fontSizeBody2,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                          ),
                          children: [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: GlobalStyles.errorMain),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.inputBorderRadius,
                          ),
                          boxShadow: [GlobalStyles.shadowSm],
                        ),
                        child: TextField(
                          controller: _newPasswordController,
                          obscureText: !_newPasswordVisible,
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeBody2,
                            color: GlobalStyles.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            hintStyle: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textTertiary,
                              fontSize: GlobalStyles.fontSizeBody2,
                            ),
                            contentPadding: GlobalStyles.inputPadding,
                            filled: true,
                            fillColor: GlobalStyles.inputBackground,
                            suffixIcon:
                                AuthWidgetUtils.buildPasswordVisibilityToggle(
                                  isVisible: _newPasswordVisible,
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _newPasswordVisible =
                                                !_newPasswordVisible,
                                      ),
                                ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.inputBorderRadius,
                              ),
                              borderSide: BorderSide(
                                color: GlobalStyles.inputBorderColor,
                                width: 1.w,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.inputBorderRadius,
                              ),
                              borderSide: BorderSide(
                                color: GlobalStyles.inputBorderColor,
                                width: 1.w,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.inputBorderRadius,
                              ),
                              borderSide: BorderSide(
                                color: GlobalStyles.inputFocusBorderColor,
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
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            color: GlobalStyles.textTertiary,
                            fontSize: GlobalStyles.fontSizeBody2,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                          ),
                          children: [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: GlobalStyles.errorMain),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.inputBorderRadius,
                          ),
                          boxShadow: [GlobalStyles.shadowSm],
                        ),
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_confirmPasswordVisible,
                          style: TextStyle(
                            fontFamily: GlobalStyles.fontFamilyBody,
                            fontSize: GlobalStyles.fontSizeBody2,
                            color: GlobalStyles.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Confirm new password',
                            hintStyle: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textTertiary,
                              fontSize: GlobalStyles.fontSizeBody2,
                            ),
                            contentPadding: GlobalStyles.inputPadding,
                            filled: true,
                            fillColor: GlobalStyles.inputBackground,
                            suffixIcon:
                                AuthWidgetUtils.buildPasswordVisibilityToggle(
                                  isVisible: _confirmPasswordVisible,
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _confirmPasswordVisible =
                                                !_confirmPasswordVisible,
                                      ),
                                ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.inputBorderRadius,
                              ),
                              borderSide: BorderSide(
                                color: GlobalStyles.inputBorderColor,
                                width: 1.w,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.inputBorderRadius,
                              ),
                              borderSide: BorderSide(
                                color: GlobalStyles.inputFocusBorderColor,
                                width: 1.5.w,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.inputBorderRadius,
                              ),
                              borderSide: BorderSide(
                                color: GlobalStyles.inputBorderColor,
                                width: 1.w,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_newPasswordError != null) ...[
                        SizedBox(height: GlobalStyles.spacingSm),
                        AuthWidgetUtils.buildErrorText(_newPasswordError!),
                      ],

                      SizedBox(height: 16.h),

                      _isLoading
                          ? AuthWidgetUtils.buildLoadingButton()
                          : AuthWidgetUtils.buildPrimaryButton(
                            onPressed: _performManualReset,
                            text: 'Update password',
                          ),
                    ] else ...[
                      _isLoading
                          ? AuthWidgetUtils.buildLoadingButton()
                          : Column(
                            children: [
                              AuthWidgetUtils.buildPrimaryButton(
                                onPressed: _checkAccount,
                                text: 'Check Account',
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
        ),
      ),
    );
  }
}
