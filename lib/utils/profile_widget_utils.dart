import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'dart:math';

/// Utility class for profile/settings UI components
class ProfileWidgetUtils {
  /// Generates a random color for profile avatar
  static Color randomColor([List<Color>? colors]) {
    final palette =
        (colors == null || colors.isEmpty)
            ? <Color>[
              Colors.red,
              Colors.orange,
              Colors.amber,
              Colors.green,
              Colors.blue,
              Colors.indigo,
              Colors.purple,
              Colors.teal,
              Colors.cyan,
            ]
            : colors;

    final rnd = Random();
    return palette[rnd.nextInt(palette.length)];
  }

  /// Gets the first letter of a name for avatar display
  static String getFirstLetterOfName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'D';
    final trimmed = fullName.trim();
    return trimmed.characters.first.toUpperCase();
  }

  /// Builds a settings list item
  static Widget buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.inputBorderColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
          splashColor: GlobalStyles.primaryMain.withValues(alpha: 0.08),
          highlightColor: GlobalStyles.primaryMain.withValues(alpha: 0.04),
          child: Padding(
            padding: EdgeInsets.all(GlobalStyles.paddingTight),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: GlobalStyles.primaryMain.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    color: GlobalStyles.primaryMain,
                    size: GlobalStyles.iconSizeMd,
                  ),
                ),
                SizedBox(width: GlobalStyles.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: GlobalStyles.textPrimary,
                          fontSize: GlobalStyles.fontSizeBody2,
                          fontWeight: GlobalStyles.fontWeightSemiBold,
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: GlobalStyles.textSecondary,
                          fontSize: GlobalStyles.fontSizeCaption,
                          fontFamily: GlobalStyles.fontFamilyBody,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: GlobalStyles.textTertiary,
                  size: GlobalStyles.iconSizeSm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a profile avatar with initial
  static Widget buildProfileAvatar({
    required String initial,
    required Color color,
    double size = 120,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: size.w,
        height: size.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.1),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: color,
              fontSize: (size * 0.48).sp,
              fontWeight: GlobalStyles.fontWeightBold,
              fontFamily: GlobalStyles.fontFamilyHeading,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a section header for settings
  static Widget buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: GlobalStyles.primaryMain,
              fontSize: GlobalStyles.fontSizeBody1,
              fontWeight: GlobalStyles.fontWeightBold,
              fontFamily: GlobalStyles.fontFamilyHeading,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: 6.h),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Container(
                height: 3.h,
                width: 40.w * value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GlobalStyles.primaryMain,
                      GlobalStyles.primaryMain.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds a password input field
  static Widget buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? error,
    bool isRequired = true,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TextStyle(
              color: GlobalStyles.textSecondary,
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            children:
                isRequired
                    ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: GlobalStyles.errorMain),
                      ),
                    ]
                    : null,
          ),
        ),
        SizedBox(height: GlobalStyles.spacingSm),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: GlobalStyles.textSecondary,
                fontSize: GlobalStyles.fontSizeBody2,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 18.h,
                horizontal: 16.w,
              ),
              filled: true,
              fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: GlobalStyles.textSecondary,
                ),
                onPressed: onToggle,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.primaryMain,
                  width: 1.5.w,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.errorMain,
                  width: 1.5.w,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.errorMain,
                  width: 1.5.w,
                ),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          SizedBox(height: GlobalStyles.spacingSm),
          Row(
            children: [
              Icon(
                LucideIcons.x,
                color: GlobalStyles.errorMain,
                size: GlobalStyles.iconSizeXs,
              ),
              SizedBox(width: GlobalStyles.spacingXs),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(
                    color: GlobalStyles.errorMain,
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontFamily: GlobalStyles.fontFamilyBody,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Builds a warning container
  static Widget buildWarningContainer({
    required String title,
    required String message,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: GlobalStyles.errorMain.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GlobalStyles.errorMain.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            color: GlobalStyles.errorMain,
            size: GlobalStyles.iconSizeLg,
          ),
          SizedBox(width: GlobalStyles.paddingTight),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeBody1,
                    fontWeight: GlobalStyles.fontWeightSemiBold,
                    color: GlobalStyles.textPrimary,
                  ),
                ),
                SizedBox(height: GlobalStyles.spacingXs),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeBody2,
                    color: GlobalStyles.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an info row with bullet point
  static Widget buildInfoRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: GlobalStyles.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              LucideIcons.circle,
              size: GlobalStyles.iconSizeXs * 0.4,
              color: GlobalStyles.textTertiary,
            ),
          ),
          SizedBox(width: GlobalStyles.spacingSm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: GlobalStyles.fontSizeBody2,
                color: GlobalStyles.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
