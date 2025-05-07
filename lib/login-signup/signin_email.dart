import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart'; // Using your actual import

class SignInEmail extends StatefulWidget {
  const SignInEmail({super.key});

  @override
  SignInEmailState createState() => SignInEmailState();
}

class SignInEmailState extends State<SignInEmail> {
  bool _isPasswordVisible = false;
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  // State variable for the checkbox
  bool _rememberMe = false; // Default value is unchecked

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    // Height for the top spacer
    final double topSpacingHeight = isKeyboardVisible ? 40.h : 120.h;
    // Height for the middle spacer
    final double middleSpacingHeight = isKeyboardVisible ? 20.h : 60.h;
    // Animation Duration
    const Duration animationDuration = Duration(milliseconds: 250);

    return SafeArea(
      child: Scaffold(
        appBar: GlobalStyles.buildCustomAppBar(
          context: context,
          icon: Icons.arrow_back_rounded,
          color: GlobalStyles.paleWhite,
          appBarBackgroundColor: GlobalStyles.backgroundColorStart,
        ),
        backgroundColor: Colors.transparent,
        body: Container(
          // Using GlobalStyles.defaultPadding from the provided code version
          padding: GlobalStyles.defaultPadding,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GlobalStyles.backgroundColorStart,
                GlobalStyles.backgroundColorEnd,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Keep as is
            crossAxisAlignment: CrossAxisAlignment.start, // Keep as is
            children: [
              // Group 1
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Keep the first AnimatedContainer as is
                  AnimatedContainer(
                    duration: animationDuration,
                    curve: Curves.ease, // Curve from user's last code
                    height: topSpacingHeight,
                  ),
                  Text(
                    "Sign in to continue",
                    style: GlobalStyles.headingStyle.copyWith(
                      color: GlobalStyles.secondaryColor,
                      fontSize: 40.sp,
                    ),
                  ),
                ],
              ),
              // Middle AnimatedContainer
              AnimatedContainer(
                duration: animationDuration,
                curve: Curves.easeInOut, // Curve from user's last code
                height: middleSpacingHeight, // Use the dynamic height
              ),

              // Group 2
              SizedBox(height: 10.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20.w),
                    child: Text(
                      "Email",
                      style: GlobalStyles.subheadingStyle.copyWith(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  TextField(
                    style: TextStyle(fontSize: 14.sp, color: Colors.white),
                    keyboardType: TextInputType.emailAddress, // Good practice
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      hintStyle: TextStyle(
                        color: GlobalStyles.paleWhite,
                        fontSize: 14.sp,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 20.h,
                        horizontal: 20.w,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.r),
                        borderSide: BorderSide(
                          color: Colors.white10,
                          width: 1.w,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.r),
                        borderSide: BorderSide(
                          color: Colors.white10,
                          width: 1.w,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.r),
                        borderSide: BorderSide(
                          color: Colors.white54,
                          width: 1.w,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  Padding(
                    padding: EdgeInsets.only(left: 20.w),
                    child: Text(
                      "Password",
                      style: GlobalStyles.subheadingStyle.copyWith(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(fontSize: 14.sp, color: Colors.white),
                    decoration: InputDecoration(
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
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
                      hintText: "Enter your password",
                      hintStyle: TextStyle(
                        color: GlobalStyles.paleWhite,
                        fontSize: 14.sp,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 20.h,
                        horizontal: 20.w,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.r),
                        borderSide: BorderSide(
                          color: Colors.white10,
                          width: 1.w,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.r),
                        borderSide: BorderSide(
                          color: Colors.white10,
                          width: 1.w,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.r),
                        borderSide: BorderSide(
                          color: Colors.white54,
                          width: 1.w,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Wrap Checkbox and Text in a Row, then wrap that Row in GestureDetector for larger tap area
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _rememberMe = !_rememberMe; // Toggle on tap
                      });
                    },
                    child: Padding(
                      // Add padding for visual spacing if needed
                      padding: EdgeInsets.only(
                        left: 10.w,
                      ), // Keep original padding area
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _rememberMe, // Use the state variable
                            onChanged: (bool? newValue) {
                              // Update the state when changed directly on checkbox too
                              setState(() {
                                _rememberMe =
                                    newValue ?? false; // Handle null case
                              });
                            },
                            side: BorderSide(width: 1.w, color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                            activeColor: GlobalStyles.primaryColor,
                            checkColor: Colors.white, // Make checkmark visible
                            visualDensity:
                                VisualDensity.compact, // Reduce default padding
                            materialTapTargetSize:
                                MaterialTapTargetSize
                                    .shrinkWrap, // Reduce tap area of checkbox itself
                          ),
                          SizedBox(
                            width: 4.w,
                          ), // Small space between checkbox and text
                          Text(
                            "Remember me",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Add forgot password logic/navigation
                    },
                    child: Padding(
                      // Add padding for easier tapping
                      padding: EdgeInsets.symmetric(
                        vertical: 8.h,
                        horizontal: 10.w,
                      ),
                      child: Text(
                        "Forgot password",
                        style: TextStyle(
                          color: GlobalStyles.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  // Add sign-in logic here
                  // Access _rememberMe value if needed
                  print("Remember Me: $_rememberMe"); // Example
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home', // Ensure '/home' route exists
                    (Route<dynamic> route) => false,
                  );
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    GlobalStyles.primaryColor,
                  ),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
                  ),
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, 50.h),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Sign in",
                    style: GlobalStyles.buttonTextStyle.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
