import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:insurevis/global_ui_variables.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: GlobalStyles.buildCustomAppBar(
          context: context,
          color: GlobalStyles.paleWhite,
          icon: Icons.arrow_back_rounded,
          appBarBackgroundColor: GlobalStyles.backgroundColorStart,
        ),
        backgroundColor: Colors.transparent,
        body: Container(
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
          child: Padding(
            padding: EdgeInsets.only(bottom: 20.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group 1
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 60.h),
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/loggers.png"),
                        ),
                      ),
                      height: 100.h,
                      width: 100.w,
                    ),
                    Text(
                      "Hello!",
                      style: GlobalStyles.headingStyle.copyWith(
                        color: GlobalStyles.secondaryColor,
                        fontSize: 40.sp,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: "Welcome to Insurevis",
                        style: GlobalStyles.subheadingStyle.copyWith(
                          fontSize: 20.sp,
                        ),
                        children: [
                          TextSpan(
                            text: ".",
                            style: GlobalStyles.subheadingStyle.copyWith(
                              color: GlobalStyles.primaryColor,
                              fontSize: 20.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Group 2
                Column(
                  children: [
                    SizedBox(height: 40.h),
                    Column(
                      children: [
                        buildSignInButton(
                          context,
                          FontAwesomeIcons.facebookF,
                          "Facebook",
                          10.w,
                        ),
                        SizedBox(height: 15.h),
                        buildSignInButton(
                          context,
                          FontAwesomeIcons.google,
                          "Google",
                          10.w,
                        ),
                        SizedBox(height: 15.h),
                        buildSignInButton(
                          context,
                          FontAwesomeIcons.whatsapp,
                          "WhatsApp",
                          10.w,
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 1.h,
                          width: 40.w,
                          decoration: BoxDecoration(color: Colors.white),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          "or",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Container(
                          height: 1.h,
                          width: 40.w,
                          decoration: BoxDecoration(color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signin_email');
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
                      ),
                      child: Center(
                        child: Text(
                          "Sign in with Email",
                          style: GlobalStyles.buttonTextStyle.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
                // Group 3
                SizedBox(
                  height: 30.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                      SizedBox(width: 5.w),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/app_onboarding');
                        },
                        child: Text(
                          "Sign up",
                          style: TextStyle(
                            color: GlobalStyles.primaryColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                            decorationThickness: 2.h,
                            decorationColor: GlobalStyles.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ElevatedButton buildSignInButton(
    BuildContext context,
    IconData icon,
    String text,
    double sizedBoxWidth,
  ) {
    return ElevatedButton(
      onPressed: () {},
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0x377f7f7f)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Icon(
                icon,
                color: GlobalStyles.primaryColor,
                size: 15.sp, // Adjust size as needed
              ),
            ),
            SizedBox(width: sizedBoxWidth),
            Text(
              "Continue with $text",
              style: GlobalStyles.buttonTextStyle.copyWith(fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}
