import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';

/// Utility class for common auth UI widgets
class AuthWidgetUtils {
  /// Shows a snackbar with a message
  /// Supports custom duration and optional action button
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? LucideIcons.circleAlert : LucideIcons.circleCheck,
              color: GlobalStyles.surfaceMain,
              size: GlobalStyles.iconSizeSm,
            ),
            SizedBox(width: GlobalStyles.spacingSm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightMedium,
                  color: GlobalStyles.surfaceMain,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? GlobalStyles.errorMain : GlobalStyles.successMain,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        ),
        margin: EdgeInsets.all(GlobalStyles.paddingNormal),
        duration: duration,
        action:
            actionLabel != null && onAction != null
                ? SnackBarAction(
                  label: actionLabel,
                  textColor: GlobalStyles.surfaceMain,
                  onPressed: onAction,
                )
                : null,
        elevation: 4,
      ),
    );
  }

  /// Builds an input label with optional asterisk
  static Widget buildInputLabel(String label, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: GlobalStyles.fontFamilyBody,
          color: GlobalStyles.textTertiary,
          fontSize: GlobalStyles.fontSizeBody2,
          fontWeight: GlobalStyles.fontWeightSemiBold,
        ),
        children:
            required
                ? [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.errorMain,
                      fontSize: GlobalStyles.fontSizeBody2,
                      fontWeight: GlobalStyles.fontWeightMedium,
                    ),
                  ),
                ]
                : [],
      ),
    );
  }

  /// Builds a text field with consistent styling
  static Widget buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
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
          contentPadding: EdgeInsets.symmetric(
            vertical: 18.h,
            horizontal: GlobalStyles.paddingNormal,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: GlobalStyles.surfaceMain,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
            borderSide: BorderSide(
              color: GlobalStyles.inputBorderColor,
              width: 1.w,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
            borderSide:
                hasError
                    ? BorderSide(color: GlobalStyles.errorMain, width: 1.5.w)
                    : BorderSide(
                      color: GlobalStyles.inputBorderColor,
                      width: 1.w,
                    ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GlobalStyles.inputBorderRadius),
            borderSide: BorderSide(
              color:
                  hasError
                      ? GlobalStyles.errorMain
                      : GlobalStyles.inputFocusBorderColor,
              width: 1.5.w,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds an error text with icon
  static Widget buildErrorText(String errorMessage) {
    return Row(
      children: [
        Icon(
          LucideIcons.circleAlert,
          color: GlobalStyles.errorMain,
          size: GlobalStyles.iconSizeXs,
        ),
        SizedBox(width: GlobalStyles.spacingXs),
        Expanded(
          child: Text(
            errorMessage,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.errorMain,
              fontSize: GlobalStyles.fontSizeCaption,
              fontWeight: GlobalStyles.fontWeightRegular,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a loading button with animated spinner
  static Widget buildLoadingButton({String? loadingText}) {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withOpacity(GlobalStyles.hoverOpacity),
        borderRadius: BorderRadius.circular(GlobalStyles.buttonBorderRadius),
        boxShadow: [GlobalStyles.buttonShadow],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: GlobalStyles.iconSizeMd,
              height: GlobalStyles.iconSizeMd,
              child: CircularProgressIndicator(
                color: GlobalStyles.surfaceMain,
                strokeWidth: 2.5,
              ),
            ),
            if (loadingText != null) ...[
              SizedBox(width: GlobalStyles.spacingSm),
              Text(
                loadingText,
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.surfaceMain,
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a primary button with consistent styling and press animation
  static Widget buildPrimaryButton({
    required VoidCallback onPressed,
    required String text,
    bool isEnabled = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(GlobalStyles.buttonBorderRadius),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return GlobalStyles.componentDisabled;
              }
              if (states.contains(WidgetState.pressed)) {
                return GlobalStyles.primaryPressed;
              }
              return GlobalStyles.primaryMain;
            }),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                vertical: 14.h,
                horizontal: GlobalStyles.paddingNormal,
              ),
            ),
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) return 0;
              if (states.contains(WidgetState.disabled)) return 0;
              return 3;
            }),
            shadowColor: WidgetStatePropertyAll(
              GlobalStyles.primaryMain.withValues(alpha: 0.3),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  GlobalStyles.buttonBorderRadius,
                ),
              ),
            ),
            minimumSize: WidgetStatePropertyAll(Size(double.infinity, 50.h)),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return GlobalStyles.surfaceMain.withValues(alpha: 0.2);
              }
              return GlobalStyles.surfaceMain.withValues(alpha: 0.1);
            }),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  color:
                      isEnabled
                          ? GlobalStyles.surfaceMain
                          : GlobalStyles.textOnDisabled,
                  size: GlobalStyles.iconSizeSm,
                ),
                SizedBox(width: GlobalStyles.spacingSm),
              ],
              Text(
                text,
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color:
                      isEnabled
                          ? GlobalStyles.surfaceMain
                          : GlobalStyles.textOnDisabled,
                  fontSize: GlobalStyles.fontSizeH6,
                  fontWeight: GlobalStyles.fontWeightSemiBold,
                  letterSpacing: GlobalStyles.letterSpacingButton,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: GlobalStyles.spacingSm),
                Icon(
                  trailingIcon,
                  color:
                      isEnabled
                          ? GlobalStyles.surfaceMain
                          : GlobalStyles.textOnDisabled,
                  size: GlobalStyles.iconSizeSm,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a secondary/outline button variant
  static Widget buildSecondaryButton({
    required VoidCallback onPressed,
    required String text,
    bool isEnabled = true,
    IconData? leadingIcon,
  }) {
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return GlobalStyles.primaryLight.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return GlobalStyles.textDisabled;
          }
          return GlobalStyles.primaryMain;
        }),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            vertical: 20.h,
            horizontal: GlobalStyles.paddingNormal,
          ),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: GlobalStyles.componentDisabled,
              width: 1.5.w,
            );
          }
          return BorderSide(color: GlobalStyles.primaryMain, width: 1.5.w);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GlobalStyles.buttonBorderRadius,
            ),
          ),
        ),
        minimumSize: WidgetStatePropertyAll(Size(double.infinity, 60.h)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: GlobalStyles.iconSizeSm),
            SizedBox(width: GlobalStyles.spacingSm),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeH6,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              letterSpacing: GlobalStyles.letterSpacingButton,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a password visibility toggle icon button
  static Widget buildPasswordVisibilityToggle({
    required bool isVisible,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
        color: GlobalStyles.textTertiary,
        size: GlobalStyles.iconSizeSm,
      ),
      onPressed: onPressed,
    );
  }

  /// Builds a password requirement checker row with animation
  static Widget buildPasswordRequirement(String requirement, bool isMet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.only(left: GlobalStyles.spacingSm, bottom: 4.h),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isMet ? LucideIcons.circleCheck : LucideIcons.circle,
              key: ValueKey<bool>(isMet),
              size: isMet ? GlobalStyles.iconSizeXs : 6.sp,
              color:
                  isMet ? GlobalStyles.successMain : GlobalStyles.textTertiary,
            ),
          ),
          SizedBox(width: GlobalStyles.spacingSm),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontFamily: GlobalStyles.fontFamilyBody,
                color:
                    isMet
                        ? GlobalStyles.successMain
                        : GlobalStyles.textTertiary,
                fontSize: GlobalStyles.fontSizeCaption,
                fontWeight:
                    isMet
                        ? GlobalStyles.fontWeightSemiBold
                        : GlobalStyles.fontWeightRegular,
              ),
              child: Text(requirement),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a password requirements list
  static Widget buildPasswordRequirementsList({
    required String password,
    required bool Function(String) hasMinLength,
    required bool Function(String) hasUppercase,
    required bool Function(String) hasLowercase,
    required bool Function(String) hasNumber,
    required bool Function(String) hasSpecialChar,
  }) {
    return Container(
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
          buildPasswordRequirement(
            "At least 8 characters",
            hasMinLength(password),
          ),
          buildPasswordRequirement(
            "One uppercase letter",
            hasUppercase(password),
          ),
          buildPasswordRequirement(
            "One lowercase letter",
            hasLowercase(password),
          ),
          buildPasswordRequirement("One number", hasNumber(password)),
          buildPasswordRequirement(
            "One special character (!@#\$%^&*)",
            hasSpecialChar(password),
          ),
        ],
      ),
    );
  }

  /// Builds a checkbox with label for terms agreement
  static Widget buildTermsCheckbox({
    required bool isChecked,
    required VoidCallback onChanged,
    required TapGestureRecognizer tosRecognizer,
    required TapGestureRecognizer privacyRecognizer,
  }) {
    return GestureDetector(
      onTap: onChanged,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 20.h,
            width: 20.w,
            child: Material(
              color: isChecked ? GlobalStyles.primaryMain : Colors.transparent,
              borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
              child: Checkbox(
                value: isChecked,
                onChanged: (bool? value) => onChanged(),
                fillColor: WidgetStateProperty.resolveWith(
                  (states) =>
                      isChecked ? GlobalStyles.primaryMain : Colors.transparent,
                ),
                checkColor: GlobalStyles.surfaceMain,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: GlobalStyles.primaryMain.withOpacity(0.6),
                  width: 1.5.w,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: "I agree to the ",
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.textSecondary,
                  fontSize: GlobalStyles.fontSizeBody2,
                ),
                children: [
                  TextSpan(
                    text: "Terms of Service",
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.primaryMain,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: GlobalStyles.primaryMain,
                    ),
                    recognizer: tosRecognizer,
                  ),
                  TextSpan(text: " and "),
                  TextSpan(
                    text: "Privacy Policy",
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      color: GlobalStyles.primaryMain,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: GlobalStyles.primaryMain,
                    ),
                    recognizer: privacyRecognizer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a text link button with hover/press states
  static Widget buildTextLink({
    required String text,
    required VoidCallback onTap,
    Color? color,
    bool underline = true,
    FontWeight? fontWeight,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: GlobalStyles.spacingXs,
          vertical: GlobalStyles.spacingXs,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: GlobalStyles.fontFamilyBody,
            color: color ?? GlobalStyles.primaryMain,
            fontSize: GlobalStyles.fontSizeBody2,
            fontWeight: fontWeight ?? GlobalStyles.fontWeightSemiBold,
            decoration: underline ? TextDecoration.underline : null,
            decorationColor: color ?? GlobalStyles.primaryMain,
          ),
        ),
      ),
    );
  }

  /// Builds an animated divider with text
  static Widget buildDividerWithText(String text) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: GlobalStyles.inputBorderColor, thickness: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: GlobalStyles.spacingSm),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textTertiary,
              fontSize: GlobalStyles.fontSizeCaption,
              fontWeight: GlobalStyles.fontWeightMedium,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: GlobalStyles.inputBorderColor, thickness: 1),
        ),
      ],
    );
  }

  /// Builds a remember me checkbox
  static Widget buildRememberMeCheckbox({
    required bool isChecked,
    required VoidCallback onChanged,
  }) {
    return GestureDetector(
      onTap: onChanged,
      child: Row(
        children: [
          SizedBox(
            height: 20.h,
            width: 20.w,
            child: Material(
              color: isChecked ? GlobalStyles.primaryMain : Colors.transparent,
              borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
              child: Checkbox(
                value: isChecked,
                onChanged: (bool? value) => onChanged(),
                fillColor: WidgetStateProperty.resolveWith(
                  (states) =>
                      isChecked ? GlobalStyles.primaryMain : Colors.transparent,
                ),
                checkColor: GlobalStyles.surfaceMain,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: GlobalStyles.primaryMain.withOpacity(0.6),
                  width: 1.5.w,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                ),
              ),
            ),
          ),
          SizedBox(width: GlobalStyles.spacingSm),
          Text(
            "Remember me",
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textSecondary,
              fontSize: GlobalStyles.fontSizeBody2,
            ),
          ),
        ],
      ),
    );
  }
}
