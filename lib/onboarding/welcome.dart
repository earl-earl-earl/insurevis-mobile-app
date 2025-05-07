import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/onboarding/app_onboarding_page.dart';
import 'package:insurevis/screen_size.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);

    double screenHeight = ScreenSize.height;
    double screenWidth = ScreenSize.width;

    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              height: screenHeight,
              decoration: GlobalStyles.gradientBackground,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 550.h,
                    width: 500.h,
                    child: Image(
                      image: AssetImage('assets/images/welcome_car.png'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ),
                    child: AutoSizeText.rich(
                      TextSpan(
                        text: "Vehicle Inspection Tech ",
                        style: GlobalStyles.welcomeHeadingStyle.copyWith(
                          color: GlobalStyles.secondaryColor,
                          fontSize: 40.h,
                        ),
                        children: [
                          TextSpan(
                            text: "in the palm of your hand.",
                            style: GlobalStyles.welcomeSubheadingStyle.copyWith(
                              fontSize: 40.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Stack(
          children: [
            Positioned(
              bottom: screenHeight * 0.025,
              right: screenWidth * 0.025,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 500),
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              const AppOnboardingScreen(),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                style: GlobalStyles.circularButtonStyle.copyWith(
                  fixedSize: WidgetStatePropertyAll(Size(60.w, 60.h)),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward,
                    size: 40.h,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
