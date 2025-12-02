import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/utils/auth_validation_utils.dart';
import 'package:insurevis/utils/auth_handler_utils.dart';
import 'package:insurevis/utils/auth_widget_utils.dart';
import 'package:insurevis/views/login-signup/forgot_password.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _rememberMe = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Error messages for individual fields
  String? _emailError;
  String? _passwordError;

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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Clear any previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate inputs first
    bool hasErrors = false;

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = "Please enter your email";
      });
      hasErrors = true;
    } else {
      // Validate email format
      final emailError = AuthValidationUtils.validateEmail(
        _emailController.text.trim(),
      );
      if (emailError != null) {
        setState(() {
          _emailError = emailError;
        });
        hasErrors = true;
      }
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = "Please enter your password";
      });
      hasErrors = true;
    }

    if (hasErrors) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthHandlerUtils.handleSignIn(
        context: context,
        authProvider: authProvider,
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (result['success'] && mounted) {
        // Show success message
        AuthWidgetUtils.showSnackBar(context, "Signed in successfully!");

        // Navigate to home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (Route<dynamic> route) => false,
        );
      } else if (mounted) {
        // Show error message
        AuthWidgetUtils.showSnackBar(
          context,
          result['error'] ?? 'Sign-in failed. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        AuthWidgetUtils.showSnackBar(
          context,
          "An unexpected error occurred. Please try again.",
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final double topSpacingHeight = isKeyboardVisible ? 10.h : 30.h;
    final double middleSpacingHeight = isKeyboardVisible ? 5.h : 30.h;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(color: GlobalStyles.backgroundMain),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(GlobalStyles.paddingNormal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: topSpacingHeight),

                        // Welcome Header Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome to",
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyHeading,
                                fontSize: GlobalStyles.fontSizeH3,
                                fontWeight: GlobalStyles.fontWeightSemiBold,
                                color: GlobalStyles.textPrimary,
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                text: "Insure",
                                style: TextStyle(
                                  fontFamily: GlobalStyles.fontFamilyHeading,
                                  fontSize: GlobalStyles.fontSizeH1,
                                  fontWeight: GlobalStyles.fontWeightBold,
                                  color: GlobalStyles.textPrimary,
                                  height: 0.8,
                                  letterSpacing: GlobalStyles.letterSpacingH1,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Vis",
                                    style: TextStyle(
                                      fontFamily:
                                          GlobalStyles.fontFamilyHeading,
                                      color: GlobalStyles.primaryMain,
                                      fontSize: GlobalStyles.fontSizeH1,
                                      fontWeight: GlobalStyles.fontWeightBold,
                                      letterSpacing:
                                          GlobalStyles.letterSpacingH1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: middleSpacingHeight),
                        SizedBox(height: 70.h),

                        // Email Field
                        _buildInputLabel("Email"),
                        SizedBox(height: 8.h),
                        AuthWidgetUtils.buildTextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          hintText: "Enter your email",
                          keyboardType: TextInputType.emailAddress,
                          hasError: _emailError != null,
                        ),
                        if (_emailError != null) ...[
                          SizedBox(height: 8.h),
                          AuthWidgetUtils.buildErrorText(_emailError!),
                        ],

                        SizedBox(height: 24.h),

                        // Password Field
                        _buildInputLabel("Password"),
                        SizedBox(height: 8.h),
                        AuthWidgetUtils.buildTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          hintText: "Enter your password",
                          obscureText: !_isPasswordVisible,
                          hasError: _passwordError != null,
                          suffixIcon:
                              AuthWidgetUtils.buildPasswordVisibilityToggle(
                                isVisible: _isPasswordVisible,
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                        ),
                        if (_passwordError != null) ...[
                          SizedBox(height: 8.h),
                          AuthWidgetUtils.buildErrorText(_passwordError!),
                        ],

                        SizedBox(height: 10.h),

                        // Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AuthWidgetUtils.buildRememberMeCheckbox(
                              isChecked: _rememberMe,
                              onChanged: () {
                                setState(() => _rememberMe = !_rememberMe);
                              },
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPassword(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.symmetric(
                                  horizontal: GlobalStyles.spacingSm,
                                  vertical: GlobalStyles.spacingXs,
                                ),
                              ),
                              child: Text(
                                "Forgot password?",
                                style: TextStyle(
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                  color: GlobalStyles.primaryMain,
                                  fontWeight: GlobalStyles.fontWeightSemiBold,
                                  fontSize: GlobalStyles.fontSizeBody2,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10.h),

                        // Sign In Button
                        _isLoading
                            ? AuthWidgetUtils.buildLoadingButton()
                            : AuthWidgetUtils.buildPrimaryButton(
                              onPressed: _handleSignIn,
                              text: "Sign in",
                            ),

                        // Extra space at bottom when keyboard is visible
                        if (isKeyboardVisible) SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),

                // Don't have an account section
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
                            "Don't have an account? ",
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textSecondary,
                              fontSize: GlobalStyles.fontSizeBody2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                fontFamily: GlobalStyles.fontFamilyBody,
                                color: GlobalStyles.primaryMain,
                                fontWeight: GlobalStyles.fontWeightBold,
                                fontSize: GlobalStyles.fontSizeBody2,
                                decoration: TextDecoration.underline,
                                decorationColor: GlobalStyles.primaryMain,
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
    return AuthWidgetUtils.buildInputLabel(label);
  }
}
