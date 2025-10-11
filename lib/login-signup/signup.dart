import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/services/supabase_service.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> with TickerProviderStateMixin {
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
  int _currentStep = 1; // 1 = personal info, 2 = password & terms
  // current step

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // Step transition controller (for sliding between steps)
  late AnimationController _stepController;
  Animation<Offset>? _step1Offset;
  Animation<Offset>? _step2Offset;
  Animation<double>? _step1Opacity;
  Animation<double>? _step2Opacity;
  // Tap recognizers for inline links
  late TapGestureRecognizer _tosRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    // Listen to controllers so button enablement updates live
    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final stepCurve = CurvedAnimation(
      parent: _stepController,
      curve: Curves.easeInOut,
    );
    _step1Offset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(stepCurve);
    _step2Offset = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(stepCurve);
    _step1Opacity = Tween<double>(begin: 1.0, end: 0.0).animate(stepCurve);
    _step2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(stepCurve);
    // Rebuild when step animation starts/ends so Offstage logic updates
    _stepController.addStatusListener((_) => setState(() {}));

    // initialize inline link recognizers
    _tosRecognizer = TapGestureRecognizer()..onTap = _openTermsOfService;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacyPolicy;
  }

  @override
  void dispose() {
    // dispose recognizers
    _tosRecognizer.dispose();
    _privacyRecognizer.dispose();
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
    _stepController.dispose();
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

  // Handlers to open terms/privacy - update to use internal routes or external URLs
  void _openTermsOfService() {
    // Example: navigate to an internal route named '/terms'
    Navigator.pushNamed(context, '/terms');
  }

  void _openPrivacyPolicy() {
    Navigator.pushNamed(context, '/policy');
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
        final provider = Provider.of<AuthProvider>(context, listen: false);

        // If auto sign-in succeeded, navigate directly to home
        if (provider.isLoggedIn) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (Route<dynamic> route) => false,
          );
          return;
        }

        // Otherwise, show success message and navigate to signin screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Account created successfully! Please sign in to continue.",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            margin: const EdgeInsets.all(20),
          ),
        );

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
    final double topSpacingHeight = isKeyboardVisible ? 20.h : 60.h;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalStyles.buildCustomAppBar(
        context: context,
        icon: Icons.arrow_back_rounded,
        color: Color(0xFF2A2A2A),
        appBarBackgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(color: Colors.white),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 20.h),
                              Text(
                                "Create Account",
                                style: GoogleFonts.inter(
                                  color: Color(0xFF2A2A2A),
                                  fontSize: 34.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Join InsureVis today",
                                style: GoogleFonts.inter(
                                  color: Color(0xFF2A2A2A),
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),

                          // Error Message Display
                          if (_errorMessage != null) ...[
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
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
                                      style: GoogleFonts.inter(
                                        color: Colors.red[300],
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8.h),
                          ],

                          SizedBox(height: 50.h),
                          // Form Container with animated step transitions
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.white.withAlpha(26),
                                width: 1.w,
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Step 1 (slides left when advancing)
                                Offstage(
                                  offstage:
                                      _currentStep != 1 &&
                                      !_stepController.isAnimating,
                                  child: SlideTransition(
                                    position:
                                        _step1Offset ??
                                        AlwaysStoppedAnimation(Offset.zero)
                                            as Animation<Offset>,
                                    child: FadeTransition(
                                      opacity:
                                          _step1Opacity ??
                                          const AlwaysStoppedAnimation<double>(
                                            1.0,
                                          ),
                                      child: _buildStepContentFor(1),
                                    ),
                                  ),
                                ),

                                // Step 2 (slides in from right)
                                Offstage(
                                  offstage:
                                      _currentStep != 2 &&
                                      !_stepController.isAnimating,
                                  child: SlideTransition(
                                    position:
                                        _step2Offset ??
                                        AlwaysStoppedAnimation(
                                              const Offset(1.0, 0.0),
                                            )
                                            as Animation<Offset>,
                                    child: FadeTransition(
                                      opacity:
                                          _step2Opacity ??
                                          const AlwaysStoppedAnimation<double>(
                                            0.0,
                                          ),
                                      child: _buildStepContentFor(2),
                                    ),
                                  ),
                                ),

                                // Back button for step 2 (larger tappable area)
                                if (_currentStep == 2)
                                  Positioned(
                                    right: 0.w,
                                    top: 0.h,

                                    child: GestureDetector(
                                      onTap: () {
                                        _stepController.reverse().then((_) {
                                          if (mounted) {
                                            setState(() {
                                              _currentStep = 1;
                                            });
                                            FocusScope.of(
                                              context,
                                            ).requestFocus(_nameFocusNode);
                                          }
                                        });
                                      },
                                      child: Center(
                                        child: Text(
                                          'Go Back',
                                          style: GoogleFonts.inter(
                                            color: GlobalStyles.primaryColor,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                GlobalStyles.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Terms moved into step 2 content inside _buildStepContentFor(2)

                          // Bottom Button area
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
                                onPressed:
                                    _currentStep == 1
                                        ? () {
                                          // validate and show errors if any; handler will proceed only if valid
                                          if (!(_formKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }
                                          _handleNext();
                                        }
                                        : () {
                                          // Validate form and then attempt sign-up
                                          if (!(_formKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }
                                          _handleSignUp();
                                        },
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
                                  _currentStep == 1 ? "Next" : "Create Account",
                                  style: GlobalStyles.buttonTextStyle.copyWith(
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
                            style: GoogleFonts.inter(
                              color: Color(0xFF2A2A2A),
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
                              style: GoogleFonts.inter(
                                color: GlobalStyles.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                decoration: TextDecoration.underline,
                                decorationColor: GlobalStyles.primaryColor,
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

  Widget _buildInputLabel(String label, String asterisk) {
    return Text.rich(
      TextSpan(
        text: label,
        style: GoogleFonts.inter(
          color: Color(0x992A2A2A),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: asterisk,
            style: GoogleFonts.inter(
              color: Colors.redAccent,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 14.sp, color: Color(0xFF2A2A2A)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: Color(0x992A2A2A),
            fontSize: 14.sp,
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 18.h,
            horizontal: 16.w,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
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
          errorStyle: GoogleFonts.inter(
            color: Colors.red[300],
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  // Build content for a specific step (used by animated stack)
  Widget _buildStepContentFor(int step) {
    if (step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field
          _buildInputLabel("Full Name ", "*"),
          SizedBox(height: 8.h),
          _buildTextFormField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            hintText: "Enter your full name",
            keyboardType: TextInputType.name,
            prefixIcon: Icons.person_outline,
            validator: _validateName,
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 20.h),

          // Email Field
          _buildInputLabel("Email Address ", "*"),
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
          _buildInputLabel("Phone Number ", ""),
          SizedBox(height: 8.h),
          _buildTextFormField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            hintText: "Enter your phone number (optional)",
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: _validatePhone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)\+]')),
            ],
          ),
          SizedBox(height: 20.h),
        ],
      );
    }

    // Step 2
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel("Password ", "*"),
        SizedBox(height: 8.h),
        _buildTextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          hintText: "Create a strong password",
          obscureText: !_isPasswordVisible,
          prefixIcon: Icons.lock_outline,
          validator: (v) => _currentStep == 2 ? _validatePassword(v) : null,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Color(0x992A2A2A),
              size: 20.sp,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        SizedBox(height: 20.h),

        _buildInputLabel("Confirm Password ", "*"),
        SizedBox(height: 8.h),
        _buildTextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          hintText: "Confirm your password",
          obscureText: !_isConfirmPasswordVisible,
          prefixIcon: Icons.lock_outline,
          validator:
              (v) => _currentStep == 2 ? _validateConfirmPassword(v) : null,
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Color(0x992A2A2A),
              size: 20.sp,
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
        SizedBox(height: 20.h),

        // Terms and Conditions placed inside step 2 content
        GestureDetector(
          onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      setState(() => _agreeToTerms = value ?? false);
                    },
                    fillColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _agreeToTerms
                              ? GlobalStyles.primaryColor
                              : Colors.transparent,
                    ),
                    checkColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: GlobalStyles.primaryColor.withAlpha(153),
                      width: 1.5.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: "I agree to the ",
                    style: GoogleFonts.inter(
                      color: Color(0xFF2A2A2A),
                      fontSize: 13.sp,
                    ),
                    children: [
                      TextSpan(
                        text: "Terms of Service",
                        style: GoogleFonts.inter(
                          color: GlobalStyles.primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: GlobalStyles.primaryColor,
                        ),
                        recognizer: _tosRecognizer,
                      ),
                      TextSpan(text: " and "),
                      TextSpan(
                        text: "Privacy Policy",
                        style: GoogleFonts.inter(
                          color: GlobalStyles.primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: GlobalStyles.primaryColor,
                        ),
                        recognizer: _privacyRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 69.h),
      ],
    );
  }

  void _handleNext() {
    // At this point the form should already be validated (onPressed does that).
    // Move to step 2 immediately so the UI responds, then run the slide animation
    if (mounted) {
      setState(() {
        _currentStep = 2;
      });
    }

    _stepController.forward().then((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      }
    });
  }
}
