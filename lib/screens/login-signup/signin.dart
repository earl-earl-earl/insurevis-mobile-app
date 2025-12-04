import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/utils/auth_validation_utils.dart';
import 'package:insurevis/utils/auth_handler_utils.dart';
import 'package:insurevis/utils/auth_widget_utils.dart';
import 'package:insurevis/screens/login-signup/forgot_password.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> with TickerProviderStateMixin {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _rememberMe = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Error messages for individual fields
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();

    // Main fade animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Slide up animation
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

    // Start animations with slight delay for smoother appearance
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
        _slideController.forward();
      }
    });

    // Auto-focus email field after animations
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _emailFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Light haptic feedback
    HapticFeedback.lightImpact();

    // Unfocus to dismiss keyboard
    FocusScope.of(context).unfocus();

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
      HapticFeedback.mediumImpact();
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
        HapticFeedback.mediumImpact();
      }
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = "Please enter your password";
      });
      hasErrors = true;
      HapticFeedback.mediumImpact();
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
        // Success haptic
        HapticFeedback.heavyImpact();

        // Show success message
        AuthWidgetUtils.showSnackBar(context, "Signed in successfully!");

        // Smooth transition to home
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (Route<dynamic> route) => false,
          );
        }
      } else if (mounted) {
        // Error haptic
        HapticFeedback.mediumImpact();

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
        HapticFeedback.mediumImpact();
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: GlobalStyles.backgroundMain),
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(color: GlobalStyles.backgroundMain),
          child: SlideTransition(
            position: _slideAnimation,
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

                          // Welcome Header Section with Hero Animation
                          Hero(
                            tag: 'app_logo_text',
                            child: Material(
                              color: Colors.transparent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome back to",
                                    style: TextStyle(
                                      fontFamily:
                                          GlobalStyles.fontFamilyHeading,
                                      fontSize: GlobalStyles.fontSizeH4,
                                      fontWeight: GlobalStyles.fontWeightMedium,
                                      color: GlobalStyles.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text.rich(
                                    TextSpan(
                                      text: "Insure",
                                      style: TextStyle(
                                        fontFamily:
                                            GlobalStyles.fontFamilyHeading,
                                        fontSize: 42.sp,
                                        fontWeight: GlobalStyles.fontWeightBold,
                                        color: GlobalStyles.textPrimary,
                                        height: 1.1,
                                        letterSpacing:
                                            GlobalStyles.letterSpacingH1,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "Vis",
                                          style: TextStyle(
                                            fontFamily:
                                                GlobalStyles.fontFamilyHeading,
                                            color: GlobalStyles.primaryMain,
                                            fontSize: 42.sp,
                                            fontWeight:
                                                GlobalStyles.fontWeightBold,
                                            letterSpacing:
                                                GlobalStyles.letterSpacingH1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Sign in to continue",
                                    style: TextStyle(
                                      fontFamily: GlobalStyles.fontFamilyBody,
                                      fontSize: GlobalStyles.fontSizeBody1,
                                      color: GlobalStyles.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isKeyboardVisible ? 30.h : 60.h),

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
                                  HapticFeedback.selectionClick();
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const ForgotPassword(),
                                      transitionsBuilder: (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOutCubic;
                                        var tween = Tween(
                                          begin: begin,
                                          end: end,
                                        ).chain(CurveTween(curve: curve));
                                        var offsetAnimation = animation.drive(
                                          tween,
                                        );
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(
                                        milliseconds: 350,
                                      ),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: GlobalStyles.spacingSm,
                                    vertical: GlobalStyles.spacingXs,
                                  ),
                                  overlayColor: GlobalStyles.primaryLight
                                      .withOpacity(0.1),
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
                                HapticFeedback.selectionClick();
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 2.h,
                                ),
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                    color: GlobalStyles.primaryMain,
                                    fontWeight: GlobalStyles.fontWeightBold,
                                    fontSize: GlobalStyles.fontSizeBody2,
                                    decoration: TextDecoration.underline,
                                    decorationColor: GlobalStyles.primaryMain,
                                    decorationThickness: 2.0,
                                  ),
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
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return AuthWidgetUtils.buildInputLabel(label);
  }
}
