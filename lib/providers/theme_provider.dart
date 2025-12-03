import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:insurevis/global_ui_variables.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false; // Default to light mode

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Theme data for light mode - Using Design System
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: GlobalStyles.primaryMain,
    scaffoldBackgroundColor: GlobalStyles.backgroundMain,
    fontFamily: GlobalStyles.fontFamilyBody,
    appBarTheme: AppBarTheme(
      backgroundColor: GlobalStyles.surfaceMain,
      foregroundColor: GlobalStyles.textPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: GlobalStyles.textPrimary,
        fontWeight: GlobalStyles.fontWeightSemiBold,
        fontSize: GlobalStyles.fontSizeH4,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH4,
      ),
      toolbarTextStyle: TextStyle(
        color: GlobalStyles.textPrimary,
        fontFamily: GlobalStyles.fontFamilyBody,
        fontSize: GlobalStyles.fontSizeBody1,
      ),
      iconTheme: IconThemeData(
        color: GlobalStyles.textPrimary,
        size: GlobalStyles.iconSizeMd,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: GlobalStyles.textPrimary,
        fontWeight: GlobalStyles.fontWeightBold,
        fontSize: GlobalStyles.fontSizeH1,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH1,
        height: GlobalStyles.lineHeightH1 / GlobalStyles.fontSizeH1,
      ),
      displayMedium: TextStyle(
        color: GlobalStyles.textPrimary,
        fontWeight: GlobalStyles.fontWeightBold,
        fontSize: GlobalStyles.fontSizeH2,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH2,
        height: GlobalStyles.lineHeightH2 / GlobalStyles.fontSizeH2,
      ),
      displaySmall: TextStyle(
        color: GlobalStyles.textPrimary,
        fontWeight: GlobalStyles.fontWeightBold,
        fontSize: GlobalStyles.fontSizeH3,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH3,
        height: GlobalStyles.lineHeightH3 / GlobalStyles.fontSizeH3,
      ),
      headlineMedium: TextStyle(
        color: GlobalStyles.textPrimary,
        fontWeight: GlobalStyles.fontWeightSemiBold,
        fontSize: GlobalStyles.fontSizeH4,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH4,
        height: GlobalStyles.lineHeightH4 / GlobalStyles.fontSizeH4,
      ),
      headlineSmall: TextStyle(
        color: GlobalStyles.textPrimary,
        fontWeight: GlobalStyles.fontWeightSemiBold,
        fontSize: GlobalStyles.fontSizeH5,
        fontFamily: GlobalStyles.fontFamilyHeading,
        height: GlobalStyles.lineHeightH5 / GlobalStyles.fontSizeH5,
      ),
      titleLarge: TextStyle(
        color: GlobalStyles.textPrimary,
        fontWeight: GlobalStyles.fontWeightSemiBold,
        fontSize: GlobalStyles.fontSizeH6,
        fontFamily: GlobalStyles.fontFamilyHeading,
        height: GlobalStyles.lineHeightH6 / GlobalStyles.fontSizeH6,
      ),
      bodyLarge: TextStyle(
        color: GlobalStyles.textPrimary,
        fontWeight: GlobalStyles.fontWeightRegular,
        fontSize: GlobalStyles.fontSizeBody1,
        fontFamily: GlobalStyles.fontFamilyBody,
        height: GlobalStyles.lineHeightBody1 / GlobalStyles.fontSizeBody1,
      ),
      bodyMedium: TextStyle(
        color: GlobalStyles.textSecondary,
        fontWeight: GlobalStyles.fontWeightRegular,
        fontSize: GlobalStyles.fontSizeBody2,
        fontFamily: GlobalStyles.fontFamilyBody,
        height: GlobalStyles.lineHeightBody2 / GlobalStyles.fontSizeBody2,
      ),
      bodySmall: TextStyle(
        color: GlobalStyles.textTertiary,
        fontWeight: GlobalStyles.fontWeightRegular,
        fontSize: GlobalStyles.fontSizeCaption,
        fontFamily: GlobalStyles.fontFamilyBody,
        height: GlobalStyles.lineHeightCaption / GlobalStyles.fontSizeCaption,
      ),
      labelLarge: TextStyle(
        color: GlobalStyles.textPrimary,
        fontWeight: GlobalStyles.fontWeightMedium,
        fontSize: GlobalStyles.fontSizeButton,
        fontFamily: GlobalStyles.fontFamilyBody,
        letterSpacing: GlobalStyles.letterSpacingButton,
        height: GlobalStyles.lineHeightButton / GlobalStyles.fontSizeButton,
      ),
    ),
    cardTheme: CardThemeData(
      color: GlobalStyles.cardBackground,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.cardBorderRadius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return GlobalStyles.primaryMain.withOpacity(
              GlobalStyles.disabledOpacity,
            );
          }
          return GlobalStyles.primaryMain;
        }),
        foregroundColor: WidgetStateProperty.all(GlobalStyles.surfaceMain),
        elevation: WidgetStateProperty.all(0),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
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
        padding: WidgetStateProperty.all(GlobalStyles.buttonPadding),
        textStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: GlobalStyles.fontSizeButton,
            fontWeight: GlobalStyles.fontWeightMedium,
            fontFamily: GlobalStyles.fontFamilyBody,
            letterSpacing: GlobalStyles.letterSpacingButton,
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(GlobalStyles.primaryMain),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: GlobalStyles.primaryMain.withOpacity(
                GlobalStyles.disabledOpacity,
              ),
              width: 1.5,
            );
          }
          return const BorderSide(color: GlobalStyles.primaryMain, width: 1.5);
        }),
        overlayColor: WidgetStateProperty.all(
          GlobalStyles.primaryMain.withOpacity(0.1),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GlobalStyles.buttonBorderRadius,
            ),
          ),
        ),
        padding: WidgetStateProperty.all(GlobalStyles.buttonPadding),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GlobalStyles.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: const BorderSide(
          color: GlobalStyles.inputBorderColor,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: const BorderSide(
          color: GlobalStyles.inputBorderColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: const BorderSide(
          color: GlobalStyles.inputFocusBorderColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: const BorderSide(color: GlobalStyles.errorMain, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: const BorderSide(color: GlobalStyles.errorMain, width: 2),
      ),
      contentPadding: GlobalStyles.inputPadding,
      hintStyle: TextStyle(
        color: GlobalStyles.textTertiary,
        fontSize: GlobalStyles.fontSizeBody2,
        fontFamily: GlobalStyles.fontFamilyBody,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: GlobalStyles.chipBackground,
      deleteIconColor: GlobalStyles.textSecondary,
      labelStyle: TextStyle(
        color: GlobalStyles.textPrimary,
        fontSize: GlobalStyles.chipFontSize,
        fontFamily: GlobalStyles.fontFamilyBody,
      ),
      padding: GlobalStyles.chipPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.chipBorderRadius),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: GlobalStyles.dialogBackground,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.dialogBorderRadius),
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: GlobalStyles.primaryMain,
      primaryContainer: GlobalStyles.primaryLight,
      secondary: GlobalStyles.accent1,
      secondaryContainer: GlobalStyles.accent2,
      surface: GlobalStyles.surfaceMain,
      error: GlobalStyles.errorMain,
      onPrimary: GlobalStyles.surfaceMain,
      onSecondary: GlobalStyles.textPrimary,
      onSurface: GlobalStyles.textPrimary,
      onError: GlobalStyles.surfaceMain,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  // Theme data for dark mode - Using Design System (Dark variant)
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: GlobalStyles.primaryMain,
    scaffoldBackgroundColor: const Color(0xFF121316),
    fontFamily: GlobalStyles.fontFamilyBody,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: GlobalStyles.surfaceMain,
      elevation: 0,
      shadowColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontWeight: GlobalStyles.fontWeightSemiBold,
        fontSize: GlobalStyles.fontSizeH4,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH4,
      ),
      toolbarTextStyle: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontFamily: GlobalStyles.fontFamilyBody,
        fontSize: GlobalStyles.fontSizeBody1,
      ),
      iconTheme: IconThemeData(
        color: GlobalStyles.surfaceMain,
        size: GlobalStyles.iconSizeMd,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontWeight: GlobalStyles.fontWeightBold,
        fontSize: GlobalStyles.fontSizeH1,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH1,
        height: GlobalStyles.lineHeightH1 / GlobalStyles.fontSizeH1,
      ),
      displayMedium: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontWeight: GlobalStyles.fontWeightBold,
        fontSize: GlobalStyles.fontSizeH2,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH2,
        height: GlobalStyles.lineHeightH2 / GlobalStyles.fontSizeH2,
      ),
      displaySmall: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontWeight: GlobalStyles.fontWeightBold,
        fontSize: GlobalStyles.fontSizeH3,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH3,
        height: GlobalStyles.lineHeightH3 / GlobalStyles.fontSizeH3,
      ),
      headlineMedium: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontWeight: GlobalStyles.fontWeightSemiBold,
        fontSize: GlobalStyles.fontSizeH4,
        fontFamily: GlobalStyles.fontFamilyHeading,
        letterSpacing: GlobalStyles.letterSpacingH4,
        height: GlobalStyles.lineHeightH4 / GlobalStyles.fontSizeH4,
      ),
      headlineSmall: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontWeight: GlobalStyles.fontWeightSemiBold,
        fontSize: GlobalStyles.fontSizeH5,
        fontFamily: GlobalStyles.fontFamilyHeading,
        height: GlobalStyles.lineHeightH5 / GlobalStyles.fontSizeH5,
      ),
      titleLarge: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontWeight: GlobalStyles.fontWeightSemiBold,
        fontSize: GlobalStyles.fontSizeH6,
        fontFamily: GlobalStyles.fontFamilyHeading,
        height: GlobalStyles.lineHeightH6 / GlobalStyles.fontSizeH6,
      ),
      bodyLarge: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontWeight: GlobalStyles.fontWeightRegular,
        fontSize: GlobalStyles.fontSizeBody1,
        fontFamily: GlobalStyles.fontFamilyBody,
        height: GlobalStyles.lineHeightBody1 / GlobalStyles.fontSizeBody1,
      ),
      bodyMedium: TextStyle(
        color: GlobalStyles.surfaceMain.withOpacity(0.7),
        fontWeight: GlobalStyles.fontWeightRegular,
        fontSize: GlobalStyles.fontSizeBody2,
        fontFamily: GlobalStyles.fontFamilyBody,
        height: GlobalStyles.lineHeightBody2 / GlobalStyles.fontSizeBody2,
      ),
      bodySmall: TextStyle(
        color: GlobalStyles.surfaceMain.withOpacity(0.6),
        fontWeight: GlobalStyles.fontWeightRegular,
        fontSize: GlobalStyles.fontSizeCaption,
        fontFamily: GlobalStyles.fontFamilyBody,
        height: GlobalStyles.lineHeightCaption / GlobalStyles.fontSizeCaption,
      ),
      labelLarge: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontWeight: GlobalStyles.fontWeightMedium,
        fontSize: GlobalStyles.fontSizeButton,
        fontFamily: GlobalStyles.fontFamilyBody,
        letterSpacing: GlobalStyles.letterSpacingButton,
        height: GlobalStyles.lineHeightButton / GlobalStyles.fontSizeButton,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.cardBorderRadius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return GlobalStyles.primaryMain.withOpacity(
              GlobalStyles.disabledOpacity,
            );
          }
          return GlobalStyles.primaryMain;
        }),
        foregroundColor: WidgetStateProperty.all(GlobalStyles.surfaceMain),
        elevation: WidgetStateProperty.all(0),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
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
        padding: WidgetStateProperty.all(GlobalStyles.buttonPadding),
        textStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: GlobalStyles.fontSizeButton,
            fontWeight: GlobalStyles.fontWeightMedium,
            fontFamily: GlobalStyles.fontFamilyBody,
            letterSpacing: GlobalStyles.letterSpacingButton,
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(GlobalStyles.primaryLight),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: GlobalStyles.primaryLight.withOpacity(
                GlobalStyles.disabledOpacity,
              ),
              width: 1.5,
            );
          }
          return const BorderSide(color: GlobalStyles.primaryLight, width: 1.5);
        }),
        overlayColor: WidgetStateProperty.all(
          GlobalStyles.primaryLight.withOpacity(0.1),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GlobalStyles.buttonBorderRadius,
            ),
          ),
        ),
        padding: WidgetStateProperty.all(GlobalStyles.buttonPadding),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: BorderSide(
          color: GlobalStyles.surfaceMain.withOpacity(0.2),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: BorderSide(
          color: GlobalStyles.surfaceMain.withOpacity(0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: const BorderSide(
          color: GlobalStyles.primaryLight,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: const BorderSide(color: GlobalStyles.errorMain, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        borderSide: const BorderSide(color: GlobalStyles.errorMain, width: 2),
      ),
      contentPadding: GlobalStyles.inputPadding,
      hintStyle: TextStyle(
        color: GlobalStyles.surfaceMain.withOpacity(0.5),
        fontSize: GlobalStyles.fontSizeBody2,
        fontFamily: GlobalStyles.fontFamilyBody,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      deleteIconColor: GlobalStyles.surfaceMain.withOpacity(0.7),
      labelStyle: TextStyle(
        color: GlobalStyles.surfaceMain,
        fontSize: GlobalStyles.chipFontSize,
        fontFamily: GlobalStyles.fontFamilyBody,
      ),
      padding: GlobalStyles.chipPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.chipBorderRadius),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.dialogBorderRadius),
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: GlobalStyles.primaryMain,
      primaryContainer: GlobalStyles.primaryLight,
      secondary: GlobalStyles.accent1,
      secondaryContainer: GlobalStyles.accent2,
      surface: const Color(0xFF1E1E1E),
      error: GlobalStyles.errorMain,
      onPrimary: GlobalStyles.surfaceMain,
      onSecondary: GlobalStyles.surfaceMain,
      onSurface: GlobalStyles.surfaceMain,
      onError: GlobalStyles.surfaceMain,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  // Get current theme
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // Toggle theme
  void toggleTheme() {
    // Force light mode only. Ignore toggle requests to enable dark mode.
    _isDarkMode = false;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // Set theme directly
  void setTheme(bool isDark) {
    // Always enforce light mode regardless of request
    _isDarkMode = false;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // Load theme preference from SharedPreferences
  void _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Always enforce light mode regardless of any previously saved preference
    _isDarkMode = false;
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  void _saveThemeToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }
}
