import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/services/supabase_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  EmailVerificationScreenState createState() => EmailVerificationScreenState();
}

class EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isResending = false;

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

    // Listen to auth state changes for automatic navigation
    SupabaseService.authStateChanges.listen((state) {
      if (state.session != null &&
          state.session!.user.emailConfirmedAt != null &&
          mounted) {
        // Email verified, navigate to home
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleResendEmail() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.resendEmailVerification();

    setState(() => _isResending = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Verification email sent! Check your inbox."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
    } else if (mounted) {
      final errorMessage = authProvider.error ?? 'Failed to resend email';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  void _handleSignInInstead() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/signin',
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              child: Padding(
                padding: GlobalStyles.defaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 100.h),

                    // Email verification icon
                    Container(
                      width: 120.w,
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: GlobalStyles.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60.r),
                        border: Border.all(
                          color: GlobalStyles.primaryColor.withOpacity(0.3),
                          width: 2.w,
                        ),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: 60.sp,
                        color: GlobalStyles.primaryColor,
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Title
                    Text(
                      "Verify Your Email",
                      style: GlobalStyles.headingStyle.copyWith(
                        color: Colors.white,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 16.h),

                    // Subtitle
                    Text(
                      "We've sent a verification link to:",
                      style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8.h),

                    // Email address
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: GlobalStyles.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.email,
                        style: TextStyle(
                          color: GlobalStyles.primaryColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Instructions
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: GlobalStyles.primaryColor,
                            size: 24.sp,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "Please check your email and click the verification link to activate your account.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "• Check your spam or junk folder\n• Make sure you entered the correct email\n• The link expires in 24 hours",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Resend email button
                    _isResending
                        ? Container(
                          height: 55.h,
                          decoration: BoxDecoration(
                            color: GlobalStyles.primaryColor.withOpacity(0.7),
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
                          onPressed: _handleResendEmail,
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              GlobalStyles.primaryColor,
                            ),
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                vertical: 18.h,
                                horizontal: 20.w,
                              ),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            minimumSize: WidgetStatePropertyAll(
                              Size(double.infinity, 55.h),
                            ),
                          ),
                          child: Text(
                            "Resend Verification Email",
                            style: GlobalStyles.buttonTextStyle.copyWith(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                    SizedBox(height: 20.h),

                    // Sign in button
                    OutlinedButton(
                      onPressed: _handleSignInInstead,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5.w,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 18.h,
                          horizontal: 20.w,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        minimumSize: Size(double.infinity, 55.h),
                      ),
                      child: Text(
                        "Back to Sign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(height: 60.h),
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
