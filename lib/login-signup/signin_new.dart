import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';

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
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate inputs first
    bool hasErrors = false;

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = "Please enter your email";
      });
      hasErrors = true;
    } else if (!_isValidEmail(_emailController.text)) {
      setState(() {
        _emailError = "Please enter a valid email address";
      });
      hasErrors = true;
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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // After API call completes
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) => false,
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final double topSpacingHeight = isKeyboardVisible ? 40.h : 80.h;
    final double middleSpacingHeight = isKeyboardVisible ? 20.h : 40.h;

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: topSpacingHeight),

                          // Welcome Header Section
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
                                "Hello!",
                                style: GlobalStyles.headingStyle.copyWith(
                                  color: GlobalStyles.secondaryColor,
                                  fontSize: 36.sp,
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  text: "Welcome to InsureVis",
                                  style: GlobalStyles.subheadingStyle.copyWith(
                                    fontSize: 18.sp,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ".",
                                      style: GlobalStyles.subheadingStyle
                                          .copyWith(
                                            color: GlobalStyles.primaryColor,
                                            fontSize: 18.sp,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: middleSpacingHeight),

                          // Email Field
                          _buildInputLabel("Email"),
                          SizedBox(height: 8.h),
                          _buildTextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            hintText: "Enter your email",
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            hasError: _emailError != null,
                          ),
                          if (_emailError != null) ...[
                            SizedBox(height: 8.h),
                            _buildErrorText(_emailError!),
                          ],

                          SizedBox(height: 24.h),

                          // Password Field
                          _buildInputLabel("Password"),
                          SizedBox(height: 8.h),
                          _buildTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            hintText: "Enter your password",
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            hasError: _passwordError != null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white54,
                                size: 20.sp,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          if (_passwordError != null) ...[
                            SizedBox(height: 8.h),
                            _buildErrorText(_passwordError!),
                          ],

                          SizedBox(height: 20.h),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap:
                                    () => setState(
                                      () => _rememberMe = !_rememberMe,
                                    ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: Material(
                                        color:
                                            _rememberMe
                                                ? GlobalStyles.primaryColor
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (bool? value) {
                                            setState(
                                              () =>
                                                  _rememberMe = value ?? false,
                                            );
                                          },
                                          fillColor:
                                              WidgetStateProperty.resolveWith(
                                                (states) =>
                                                    _rememberMe
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
                                    SizedBox(width: 8.w),
                                    Text(
                                      "Remember me",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Forgot password logic
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                ),
                                child: Text(
                                  "Forgot password?",
                                  style: TextStyle(
                                    color: GlobalStyles.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 30.h),

                          // Sign In Button
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
                                onPressed: _handleSignIn,
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
                                  "Sign in",
                                  style: GlobalStyles.buttonTextStyle.copyWith(
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
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: GlobalStyles.primaryColor,
                                fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
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
          fillColor: Colors.white.withAlpha(20), // 0.08 * 255
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
                hasError
                    ? BorderSide(color: Colors.red.withAlpha(153), width: 1.5.w)
                    : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color:
                  hasError
                      ? Colors.red.withAlpha(153)
                      : GlobalStyles.primaryColor.withAlpha(153), // 0.6 * 255
              width: 1.5.w,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorText(String errorMessage) {
    return Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red[300], size: 16.sp),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            errorMessage,
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
