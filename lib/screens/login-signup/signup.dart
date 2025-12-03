import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/utils/auth_validation_utils.dart';
import 'package:insurevis/utils/auth_handler_utils.dart';
import 'package:insurevis/utils/auth_widget_utils.dart';

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

  // Validation methods using AuthValidationUtils
  String? _validateName(String? value) {
    return AuthValidationUtils.validateName(value);
  }

  String? _validateEmail(String? value) {
    return AuthValidationUtils.validateEmail(value);
  }

  String? _validatePhone(String? value) {
    return AuthValidationUtils.validatePhone(value);
  }

  String? _validatePassword(String? value) {
    return AuthValidationUtils.validatePassword(value);
  }

  String? _validateConfirmPassword(String? value) {
    return AuthValidationUtils.validateConfirmPassword(
      value,
      _passwordController.text,
    );
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

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage =
            "Please agree to the Terms of Service and Privacy Policy";
      });
      AuthWidgetUtils.showSnackBar(context, _errorMessage!, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthHandlerUtils.handleSignUp(
        context: context,
        authProvider: authProvider,
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone:
            _phoneController.text.trim().isNotEmpty
                ? _phoneController.text
                : null,
      );

      setState(() => _isLoading = false);

      if (result['success'] && mounted) {
        // If auto sign-in succeeded, navigate directly to home
        if (result['autoSignedIn']) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (Route<dynamic> route) => false,
          );
          return;
        }

        // Otherwise, show success message and navigate to signin screen
        AuthWidgetUtils.showSnackBar(
          context,
          "Account created successfully! Please sign in to continue.",
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/signin',
          (Route<dynamic> route) => false,
        );
      } else if (mounted) {
        // Show error message
        setState(() {
          _errorMessage =
              result['error'] ?? 'Sign-up failed. Please try again.';
        });
        AuthWidgetUtils.showSnackBar(context, _errorMessage!, isError: true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });

      if (mounted) {
        AuthWidgetUtils.showSnackBar(context, _errorMessage!, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final double topSpacingHeight = isKeyboardVisible ? 20.h : 60.h;

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
                                style: TextStyle(
                                  fontFamily: GlobalStyles.fontFamilyHeading,
                                  color: GlobalStyles.textPrimary,
                                  fontSize: GlobalStyles.fontSizeH1,
                                  fontWeight: GlobalStyles.fontWeightBold,
                                ),
                              ),
                              Text(
                                "Join InsureVis today",
                                style: TextStyle(
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                  color: GlobalStyles.textSecondary,
                                  fontSize: GlobalStyles.fontSizeBody1,
                                ),
                              ),
                            ],
                          ),

                          // Error Message Display
                          if (_errorMessage != null) ...[
                            Container(
                              padding: EdgeInsets.all(
                                GlobalStyles.paddingTight,
                              ),
                              decoration: BoxDecoration(
                                color: GlobalStyles.errorLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  GlobalStyles.radiusMd,
                                ),
                                border: Border.all(
                                  color: GlobalStyles.errorMain.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.circleAlert,
                                    color: GlobalStyles.errorMain,
                                    size: GlobalStyles.iconSizeSm,
                                  ),
                                  SizedBox(width: GlobalStyles.spacingSm),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        fontFamily: GlobalStyles.fontFamilyBody,
                                        color: GlobalStyles.errorMain,
                                        fontSize: GlobalStyles.fontSizeBody2,
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
                              color: GlobalStyles.surfaceMain.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.radiusXl,
                              ),
                              border: Border.all(
                                color: GlobalStyles.inputBorderColor
                                    .withOpacity(0.3),
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
                                          style: TextStyle(
                                            fontFamily:
                                                GlobalStyles.fontFamilyBody,
                                            color: GlobalStyles.primaryMain,
                                            fontSize:
                                                GlobalStyles.fontSizeBody2,
                                            fontWeight:
                                                GlobalStyles.fontWeightSemiBold,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                GlobalStyles.primaryMain,
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
                              ? AuthWidgetUtils.buildLoadingButton()
                              : AuthWidgetUtils.buildPrimaryButton(
                                onPressed:
                                    _currentStep == 1
                                        ? () {
                                          if (!(_formKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }
                                          _handleNext();
                                        }
                                        : () {
                                          if (!(_formKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }
                                          _handleSignUp();
                                        },
                                text:
                                    _currentStep == 1
                                        ? "Next"
                                        : "Create Account",
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
                            style: TextStyle(
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textSecondary,
                              fontSize: GlobalStyles.fontSizeBody2,
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

  Widget _buildInputLabel(String label, String asterisk) {
    return AuthWidgetUtils.buildInputLabel(
      label,
      required: asterisk.isNotEmpty,
    );
  }

  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return AuthWidgetUtils.buildPasswordRequirement(requirement, isMet);
  }

  // Password requirement checkers
  bool _hasMinLength() =>
      AuthValidationUtils.hasMinLength(_passwordController.text);
  bool _hasUppercase() =>
      AuthValidationUtils.hasUppercase(_passwordController.text);
  bool _hasLowercase() =>
      AuthValidationUtils.hasLowercase(_passwordController.text);
  bool _hasNumber() => AuthValidationUtils.hasNumber(_passwordController.text);
  bool _hasSpecialChar() =>
      AuthValidationUtils.hasSpecialChar(_passwordController.text);

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
        style: TextStyle(
          fontFamily: GlobalStyles.fontFamilyBody,
          fontSize: GlobalStyles.fontSizeBody2,
          color: GlobalStyles.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: GlobalStyles.textTertiary,
            fontSize: GlobalStyles.fontSizeBody2,
          ),
          contentPadding: GlobalStyles.inputPadding,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: GlobalStyles.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
            borderSide: BorderSide(
              color: GlobalStyles.inputBorderColor,
              width: 1.w,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
            borderSide: BorderSide(
              color: GlobalStyles.inputFocusBorderColor,
              width: 1.5.w,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
            borderSide: BorderSide(color: GlobalStyles.errorMain, width: 1.5.w),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
            borderSide: BorderSide(color: GlobalStyles.errorMain, width: 1.5.w),
          ),
          errorStyle: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: GlobalStyles.errorMain,
            fontSize: GlobalStyles.fontSizeCaption,
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
            prefixIcon: LucideIcons.user,
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
            prefixIcon: LucideIcons.mail,
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
            prefixIcon: LucideIcons.phone,
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
          prefixIcon: LucideIcons.lock,
          validator: (v) => _currentStep == 2 ? _validatePassword(v) : null,
          suffixIcon: AuthWidgetUtils.buildPasswordVisibilityToggle(
            isVisible: _isPasswordVisible,
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        SizedBox(height: 8.h),
        // Password Requirements Hint
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: GlobalStyles.spacingXs,
            vertical: GlobalStyles.spacingXs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Password must contain:",
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.textTertiary,
                  fontSize: GlobalStyles.fontSizeCaption,
                  fontWeight: GlobalStyles.fontWeightMedium,
                ),
              ),
              SizedBox(height: 4.h),
              _buildPasswordRequirement(
                "At least 8 characters",
                _hasMinLength(),
              ),
              _buildPasswordRequirement(
                "One uppercase letter",
                _hasUppercase(),
              ),
              _buildPasswordRequirement(
                "One lowercase letter",
                _hasLowercase(),
              ),
              _buildPasswordRequirement("One number", _hasNumber()),
              _buildPasswordRequirement(
                "One special character (!@#\$%^&*)",
                _hasSpecialChar(),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        _buildInputLabel("Confirm Password ", "*"),
        SizedBox(height: 8.h),
        _buildTextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          hintText: "Confirm your password",
          obscureText: !_isConfirmPasswordVisible,
          prefixIcon: LucideIcons.lock,
          validator:
              (v) => _currentStep == 2 ? _validateConfirmPassword(v) : null,
          suffixIcon: AuthWidgetUtils.buildPasswordVisibilityToggle(
            isVisible: _isConfirmPasswordVisible,
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
        SizedBox(height: 20.h),

        // Terms and Conditions placed inside step 2 content
        AuthWidgetUtils.buildTermsCheckbox(
          isChecked: _agreeToTerms,
          onChanged: () => setState(() => _agreeToTerms = !_agreeToTerms),
          tosRecognizer: _tosRecognizer,
          privacyRecognizer: _privacyRecognizer,
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
