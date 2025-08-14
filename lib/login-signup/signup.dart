import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/services/supabase_service.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields matching Supabase schema
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // State variables
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Validation methods using SupabaseService validators
  String? _validateName(String? value) {
    return SupabaseService.validateName(value ?? '');
  }

  String? _validateEmail(String? value) {
    return SupabaseService.validateEmail(value ?? '');
  }

  String? _validatePhone(String? value) {
    return SupabaseService.validatePhone(value);
  }

  String? _validatePassword(String? value) {
    return SupabaseService.validatePassword(value ?? '');
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _handleSignUp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _errorMessage = null;
    });

    // Clear any previous errors
    authProvider.clearError();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage =
            "Please agree to the Terms of Service and Privacy Policy";
      });
      _showErrorSnackBar(_errorMessage!);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await authProvider.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        phone:
            _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Account created successfully! Please check your email for verification.",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            margin: const EdgeInsets.all(20),
          ),
        );

        // Navigate to signin screen for email verification
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/signin',
          (Route<dynamic> route) => false,
        );
      } else if (mounted) {
        // Show error message
        final errorMessage =
            authProvider.error ?? 'Sign-up failed. Please try again.';
        setState(() {
          _errorMessage = errorMessage;
        });
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });

      if (mounted) {
        _showErrorSnackBar(_errorMessage!);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final double topSpacingHeight = isKeyboardVisible ? 30.h : 60.h;
    final double middleSpacingHeight = isKeyboardVisible ? 16.h : 32.h;

    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlobalStyles.buildCustomAppBar(
          context: context,
          icon: Icons.arrow_back_rounded,
          color: GlobalStyles.paleWhite,
          appBarBackgroundColor: Colors.transparent,
        ),
        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GlobalStyles.backgroundColorStart,
                GlobalStyles.backgroundColorEnd,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: GlobalStyles.defaultPadding,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: topSpacingHeight),

                            // Header Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                        "assets/images/loggers.png",
                                      ),
                                    ),
                                  ),
                                  height: 80.h,
                                  width: 80.w,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  "Create Account",
                                  style: GlobalStyles.headingStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: 34.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "Join InsureVis today",
                                  style: TextStyle(
                                    color: GlobalStyles.paleWhite.withAlpha(
                                      204,
                                    ),
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: middleSpacingHeight),

                            // Error Message Display
                            if (_errorMessage != null) ...[
                              Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red[300],
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16.h),
                            ],

                            // Form Container
                            Container(
                              padding: EdgeInsets.all(20.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(15),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.white.withAlpha(26),
                                  width: 1.w,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name Field
                                  _buildInputLabel("Full Name *"),
                                  SizedBox(height: 8.h),
                                  _buildTextFormField(
                                    controller: _nameController,
                                    focusNode: _nameFocusNode,
                                    hintText: "Enter your full name",
                                    keyboardType: TextInputType.name,
                                    prefixIcon: Icons.person_outline,
                                    validator: _validateName,
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  SizedBox(height: 20.h),

                                  // Email Field
                                  _buildInputLabel("Email *"),
                                  SizedBox(height: 8.h),
                                  _buildTextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    hintText: "Enter your email",
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                    validator: _validateEmail,
                                  ),
                                  SizedBox(height: 20.h),

                                  // Phone Field (Optional)
                                  _buildInputLabel("Phone Number"),
                                  SizedBox(height: 8.h),
                                  _buildTextFormField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    hintText:
                                        "Enter your phone number (optional)",
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone_outlined,
                                    validator: _validatePhone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d\s\-\(\)\+]'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.h),

                                  // Password Field
                                  _buildInputLabel("Password *"),
                                  SizedBox(height: 8.h),
                                  _buildTextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    hintText: "Create a strong password",
                                    obscureText: !_isPasswordVisible,
                                    prefixIcon: Icons.lock_outline,
                                    validator: _validatePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.white60,
                                        size: 20.sp,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 20.h),

                                  // Confirm Password Field
                                  _buildInputLabel("Confirm Password *"),
                                  SizedBox(height: 8.h),
                                  _buildTextFormField(
                                    controller: _confirmPasswordController,
                                    focusNode: _confirmPasswordFocusNode,
                                    hintText: "Confirm your password",
                                    obscureText: !_isConfirmPasswordVisible,
                                    prefixIcon: Icons.lock_outline,
                                    validator: _validateConfirmPassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.white60,
                                        size: 20.sp,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // Terms and Conditions
                            GestureDetector(
                              onTap:
                                  () => setState(
                                    () => _agreeToTerms = !_agreeToTerms,
                                  ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: Material(
                                      color:
                                          _agreeToTerms
                                              ? GlobalStyles.primaryColor
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4.r),
                                      child: Checkbox(
                                        value: _agreeToTerms,
                                        onChanged: (bool? value) {
                                          setState(
                                            () =>
                                                _agreeToTerms = value ?? false,
                                          );
                                        },
                                        fillColor:
                                            WidgetStateProperty.resolveWith(
                                              (states) =>
                                                  _agreeToTerms
                                                      ? GlobalStyles
                                                          .primaryColor
                                                      : Colors.transparent,
                                            ),
                                        checkColor: Colors.white,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        side: BorderSide(
                                          color: Colors.white54,
                                          width: 1.5.w,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4.r,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        text: "I agree to the ",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13.sp,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "Terms of Service",
                                            style: TextStyle(
                                              color: GlobalStyles.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                          TextSpan(text: " and "),
                                          TextSpan(
                                            text: "Privacy Policy",
                                            style: TextStyle(
                                              color: GlobalStyles.primaryColor,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30.h),

                            // Sign Up Button
                            _isLoading
                                ? Container(
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    color: GlobalStyles.primaryColor.withValues(
                                      alpha: 0.7,
                                    ),
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
                                  onPressed: _handleSignUp,
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
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                    ),
                                    minimumSize: WidgetStatePropertyAll(
                                      Size(double.infinity, 60.h),
                                    ),
                                  ),
                                  child: Text(
                                    "Create Account",
                                    style: GlobalStyles.buttonTextStyle
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),

                            // Extra space at bottom when keyboard is visible
                            if (isKeyboardVisible) SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ), // Already have an account section
                AnimatedOpacity(
                  opacity: isKeyboardVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isKeyboardVisible ? 0 : null,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/signin',
                              );
                            },
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                color: GlobalStyles.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        validator: validator,
        style: TextStyle(fontSize: 15.sp, color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white38, fontSize: 15.sp),
          contentPadding: EdgeInsets.symmetric(
            vertical: 18.h,
            horizontal: 16.w,
          ),
          prefixIcon: Icon(prefixIcon, color: Colors.white54, size: 20.sp),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withAlpha(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Colors.red.withAlpha(153),
              width: 1.5.w,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Colors.red.withAlpha(153),
              width: 1.5.w,
            ),
          ),
          errorStyle: TextStyle(color: Colors.red[300], fontSize: 12.sp),
        ),
      ),
    );
  }
}
