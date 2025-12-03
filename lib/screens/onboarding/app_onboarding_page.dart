// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/screen_size.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OnboardingPageData {
  final String title;
  final String fancyTitle;
  final String description;
  final IconData icon;

  OnboardingPageData({
    required this.title,
    required this.fancyTitle,
    required this.description,
    required this.icon,
  });
}

class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({super.key});

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  late final PageController _controller;
  int _currentPage = 0;
  bool _isLastPage = false;

  // Add this field to hold the preloaded image
  late final ImageProvider _backgroundImage;
  bool _imageLoaded = false;
  bool _preloadStarted = false; // Add this flag to avoid duplicate calls

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Smart Car",
      fancyTitle: "Damage Detection",
      description:
          "Easily assess vehicle damages with just a photo. Let AI handle the inspection for you!",
      icon: LucideIcons.scan,
    ),
    OnboardingPageData(
      title: "Know the",
      fancyTitle: "Costs in Seconds",
      description:
          "Premium and prestige car hourly rental. Experience the thrill at a lower price.",
      icon: LucideIcons.clock,
    ),
    OnboardingPageData(
      title: "Fast-Track your",
      fancyTitle: "Insurance Process",
      description:
          "Seamlessly authenticate and submit damage reports to insurance provider with ease.",
      icon: LucideIcons.circleCheck,
    ),
    OnboardingPageData(
      title: "Snap.",
      fancyTitle: "Detect, Ensure",
      description:
          "Take a picture, let AI do the work, and secure your claim effortlessly.",
      icon: LucideIcons.camera,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();

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

    return Scaffold(
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
                color: GlobalStyles.textPrimary,
                child: Center(
                  child: CircularProgressIndicator(
                    color: GlobalStyles.primaryMain,
                    strokeWidth: GlobalStyles.iconStrokeWidthNormal,
                  ),
                ),
              ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF191919).withOpacity(0.6),
                  const Color(0xFF191919).withOpacity(0.85),
                ],
              ),
            ),
          ),
          SizedBox(
            height: screenHeight,
            width: screenWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: GlobalStyles.spacingXl,
                horizontal: GlobalStyles.paddingLoose,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: GlobalStyles.spacingXl),
                    child: Text.rich(
                      TextSpan(
                        text: "Insure",
                        style: TextStyle(
                          color: GlobalStyles.surfaceMain,
                          fontSize: GlobalStyles.fontSizeH1,
                          fontWeight: GlobalStyles.fontWeightBold,
                          fontFamily: GlobalStyles.fontFamilyHeading,
                          letterSpacing: GlobalStyles.letterSpacingH1,
                        ),
                        children: [
                          TextSpan(
                            text: "Vis",
                            style: TextStyle(
                              color: GlobalStyles.primaryMain,
                              fontWeight: GlobalStyles.fontWeightBold,
                              fontFamily: GlobalStyles.fontFamilyHeading,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.28,
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            double scale = 1.0;
                            double opacity = 1.0;

                            if (_controller.position.haveDimensions) {
                              double pageOffset = _controller.page! - index;
                              pageOffset = pageOffset.abs();
                              scale = (1 - pageOffset * 0.3).clamp(0.0, 1.0);
                              opacity = (1 - pageOffset).clamp(0.0, 1.0);
                            }

                            return AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: GlobalStyles.spacingSm,
                                      ),
                                      child: OnboardingPage(
                                        data: _pages[index],
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                      SizedBox(height: GlobalStyles.spacingLg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildPageIndicator(),
                      ),
                      SizedBox(height: GlobalStyles.spacingLg),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_isLastPage) {
                                  Navigator.pushNamed(context, '/signin');
                                } else {
                                  _controller.nextPage(
                                    duration: GlobalStyles.durationNormal,
                                    curve: GlobalStyles.easingStandard,
                                  );
                                }
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                  GlobalStyles.primaryMain,
                                ),
                                foregroundColor: WidgetStateProperty.all(
                                  GlobalStyles.surfaceMain,
                                ),
                                elevation: WidgetStateProperty.all(0),
                                shadowColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                                overlayColor: WidgetStateProperty.all(
                                  GlobalStyles.primaryDark.withOpacity(0.1),
                                ),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      GlobalStyles.buttonBorderRadius,
                                    ),
                                  ),
                                ),
                                padding: WidgetStateProperty.all(
                                  GlobalStyles.buttonPadding,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLastPage ? "Get Started" : "Next",
                                    style: TextStyle(
                                      color: GlobalStyles.surfaceMain,
                                      fontSize: GlobalStyles.fontSizeButton,
                                      fontWeight:
                                          GlobalStyles.fontWeightSemiBold,
                                      fontFamily: GlobalStyles.fontFamilyBody,
                                      letterSpacing:
                                          GlobalStyles.letterSpacingButton,
                                      height: 1,
                                    ),
                                  ),
                                  if (!_isLastPage) ...[
                                    SizedBox(width: GlobalStyles.spacingSm),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: GlobalStyles.iconSizeSm,
                                      color: GlobalStyles.surfaceMain,
                                    ),
                                  ],
                                ],
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
      duration: GlobalStyles.durationFast,
      curve: GlobalStyles.easingStandard,
      margin: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingXs),
      height: GlobalStyles.spacingSm,
      width: isActive ? GlobalStyles.spacingLg : GlobalStyles.spacingSm,
      decoration: BoxDecoration(
        color:
            isActive
                ? GlobalStyles.surfaceMain
                : GlobalStyles.surfaceMain.withOpacity(0.4),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusFull),
        boxShadow: isActive ? [GlobalStyles.shadowSm] : null,
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({super.key, required this.data});

  Future<String> _processDescription(String description) async {
    return compute(_parseDescription, description);
  }

  static String _parseDescription(String description) {
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
        Container(
          padding: EdgeInsets.all(GlobalStyles.paddingNormal),
          decoration: BoxDecoration(
            color: GlobalStyles.primaryMain.withOpacity(0.15),
            borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
            border: Border.all(
              color: GlobalStyles.primaryMain.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            data.icon,
            size: GlobalStyles.iconSizeLg,
            color: GlobalStyles.primaryLight,
          ),
        ),
        SizedBox(height: GlobalStyles.spacingLg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.title,
              style: TextStyle(
                color: GlobalStyles.surfaceMain,
                fontSize: GlobalStyles.fontSizeH2,
                fontWeight: GlobalStyles.fontWeightBold,
                fontFamily: GlobalStyles.fontFamilyHeading,
                height: 1.2,
                letterSpacing: GlobalStyles.letterSpacingH2,
              ),
            ),
            Text(
              data.fancyTitle,
              style: TextStyle(
                color: GlobalStyles.primaryLight,
                fontSize: GlobalStyles.fontSizeH2,
                fontWeight: GlobalStyles.fontWeightBold,
                fontFamily: GlobalStyles.fontFamilyHeading,
                height: 1.2,
                letterSpacing: GlobalStyles.letterSpacingH2,
              ),
            ),
          ],
        ),
        SizedBox(height: GlobalStyles.spacingMd),
        FutureBuilder<String>(
          future: _processDescription(data.description),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data!,
                style: TextStyle(
                  color: GlobalStyles.surfaceMain.withOpacity(0.85),
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightRegular,
                  fontFamily: GlobalStyles.fontFamilyBody,
                  height:
                      GlobalStyles.lineHeightBody2 / GlobalStyles.fontSizeBody2,
                ),
                textAlign: TextAlign.left,
              );
            } else {
              return SizedBox(
                height: GlobalStyles.spacingMd,
                child: Row(
                  children: [
                    SizedBox(
                      width: GlobalStyles.iconSizeSm,
                      height: GlobalStyles.iconSizeSm,
                      child: CircularProgressIndicator(
                        color: GlobalStyles.primaryLight,
                        strokeWidth: GlobalStyles.iconStrokeWidthThin,
                      ),
                    ),
                    SizedBox(width: GlobalStyles.spacingSm),
                    Text(
                      "Loading...",
                      style: TextStyle(
                        color: GlobalStyles.surfaceMain.withOpacity(0.6),
                        fontSize: GlobalStyles.fontSizeCaption,
                        fontFamily: GlobalStyles.fontFamilyBody,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
