// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/screen_size.dart';
import 'package:google_fonts/google_fonts.dart';

class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({super.key});

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  // Add this field to hold the preloaded image
  late final ImageProvider _backgroundImage;
  bool _imageLoaded = false;
  bool _preloadStarted = false; // Add this flag to avoid duplicate calls

  final List<Widget> _pages = [
    OnboardingPage(
      title: "Smart Car",
      fancyTitle: "Damage Detection",
      description:
          "Easily assess vehicle damages with just a photo. \nLet AI handle the inspection for you!",
    ),
    OnboardingPage(
      title: "Know the",
      fancyTitle: "Costs in Seconds",
      description:
          "Premium and prestige car hourly rental. \nExperience the thrill at a lower price.",
    ),
    OnboardingPage(
      title: "Fast-Track your",
      fancyTitle: "Insurance Process",
      description:
          "Seamlessly authenticate and submit \ndamage reports to  insurance provider with ease.",
    ),
    OnboardingPage(
      title: "Snap.",
      fancyTitle: "Detect, Ensure",
      description:
          "Take a picture, let AI do the work,  \nand secure your claim effortlessly.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _currentPage = _controller.page?.round() ?? 0;
        _isLastPage = _currentPage == _pages.length - 1;
      });
    });

    // Initialize the image provider without precaching yet
    _backgroundImage = const AssetImage('assets/images/onboarding.jpeg');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only start preloading once
    if (!_preloadStarted) {
      _preloadStarted = true;
      _preloadBackgroundImage();
    }
  }

  Future<void> _preloadBackgroundImage() async {
    // Now context is safely available
    await precacheImage(_backgroundImage, context)
        .then((_) {
          if (mounted) {
            setState(() {
              _imageLoaded = true;
            });
          }
        })
        .catchError((error) {
          // DEBUG: print("Error loading image: $error");
          // If image fails to load, still set imageLoaded to show a fallback
          if (mounted) {
            setState(() {
              _imageLoaded = true;
            });
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
            _imageLoaded
                ? Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _backgroundImage,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                )
                : Container(
                  // Show a placeholder until image loads
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: GlobalStyles.primaryColor,
                    ),
                  ),
                ),
            Container(
              decoration: const BoxDecoration(color: Color(0x80191919)),
            ),
            SizedBox(
              height: screenHeight,
              width: screenWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.05,
                  horizontal: screenWidth * 0.075,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.05),
                      child: Text.rich(
                        TextSpan(
                          text: "Insurevis",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 35.sp,
                            fontWeight: FontWeight.w900,
                          ),
                          children: [
                            TextSpan(
                              text: ".",
                              style: TextStyle(color: Color(0xFF6B4AFF)),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Column(
                      children: [
                        SizedBox(
                          height: screenHeight * 0.20,
                          child: PageView.builder(
                            // Use PageView.builder for animation
                            controller: _controller,
                            itemCount: _pages.length,
                            itemBuilder: (context, index) {
                              double scale = 1.0;
                              double opacity = 1.0;

                              // Calculate scale and opacity based on current page
                              if (_controller.position.haveDimensions) {
                                double pageOffset = _controller.page! - index;
                                pageOffset =
                                    pageOffset
                                        .abs(); // Make the offset absolute
                                // Shrink and fade out the previous page
                                scale = (1 - pageOffset * 0.3).clamp(0.0, 1.0);
                                opacity = (1 - pageOffset).clamp(0.0, 1.0);
                              }

                              return Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.01,
                                    ),
                                    child: _pages[index],
                                  ),
                                ),
                              );
                            },
                            onPageChanged: (int page) {
                              setState(() {
                                _currentPage = page;
                                _isLastPage = page == _pages.length - 1;
                              });
                            },
                          ),
                        ),
                        // Add the Page Indicator here
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buildPageIndicator(),
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_isLastPage) {
                                    // Navigate to the SignIn screen
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/signin',
                                    );
                                  } else {
                                    _controller.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.ease,
                                    );
                                  }
                                },
                                style: const ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    GlobalStyles.primaryColor,
                                  ),
                                  splashFactory: InkRipple.splashFactory,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(20.sp),
                                  child: Text(
                                    _isLastPage
                                        ? "Get Started"
                                        : "Next", // Change Text based on last page
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < _pages.length; i++) {
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 5.0.w), // Reduced margin
      height: 8.0.h, // Adjusted size
      width: 8.0.w, // Adjusted size
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey,
        shape: BoxShape.circle, // Make it a perfect circle
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String fancyTitle;
  final String description;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.fancyTitle,
    required this.description,
  });

  // A function to process the description off the main thread.
  Future<String> _processDescription(String description) async {
    return compute(_parseDescription, description);
  }

  // This function runs in a separate isolate.
  static String _parseDescription(String description) {
    // Simulate some CPU-intensive work.  In a real scenario, this could be
    // text parsing, complex calculations, or other tasks that would
    // normally block the main thread.  For demonstration, we just add
    // some dummy operation.
    String parsedDescription = description;
    for (int i = 0; i < 100; i++) {
      parsedDescription = parsedDescription.replaceAll(" ", "  ");
      parsedDescription = parsedDescription.replaceAll("  ", " ");
    }
    return parsedDescription;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 35.sp,
                fontWeight: FontWeight.w900,
                height: 1.h,
              ),
            ),
            Text(
              fancyTitle,
              style: TextStyle(
                color: GlobalStyles.secondaryColor,
                fontSize: 35.sp,
                fontWeight: FontWeight.w900,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        FutureBuilder<String>(
          future: _processDescription(description),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data!,
                style: TextStyle(color: Colors.white, fontSize: 13.sp),
                textAlign: TextAlign.left,
              );
            } else {
              // While the description is being processed, display a placeholder.
              return Text(
                "Loading...", // Or a more sophisticated loading indicator
                style: TextStyle(color: Colors.white, fontSize: 13.sp),
                textAlign: TextAlign.left,
              );
            }
          },
        ),
      ],
    );
  }
}
