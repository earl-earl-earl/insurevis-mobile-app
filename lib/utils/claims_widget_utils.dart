import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/models/insurevis_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/utils/claims_handler_utils.dart';

/// Utilities for building claims-related UI widgets
class ClaimsWidgetUtils {
  /// Get sort option label
  static String getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.dateNewest:
        return 'Date (Newest)';
      case SortOption.dateOldest:
        return 'Date (Oldest)';
      case SortOption.amountHighest:
        return 'Amount (Highest)';
      case SortOption.amountLowest:
        return 'Amount (Lowest)';
      case SortOption.statusAZ:
        return 'Status (A-Z)';
      case SortOption.statusZA:
        return 'Status (Z-A)';
      case SortOption.claimNumberAZ:
        return 'Claim # (A-Z)';
      case SortOption.claimNumberZA:
        return 'Claim # (Z-A)';
    }
  }

  /// Get sort option icon
  static IconData getSortOptionIcon(SortOption option) {
    switch (option) {
      case SortOption.dateNewest:
      case SortOption.dateOldest:
        return LucideIcons.calendar;
      case SortOption.amountHighest:
      case SortOption.amountLowest:
        return LucideIcons.dollarSign;
      case SortOption.statusAZ:
      case SortOption.statusZA:
        return LucideIcons.tag;
      case SortOption.claimNumberAZ:
      case SortOption.claimNumberZA:
        return LucideIcons.hash;
    }
  }

  /// Get status color
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return GlobalStyles.warningMain;
      case 'under review':
        return GlobalStyles.infoMain;
      case 'approved':
        return GlobalStyles.successMain;
      case 'rejected':
        return GlobalStyles.errorMain;
      case 'appealed':
        return GlobalStyles.purpleMain;
      case 'draft':
        return GlobalStyles.textDisabled;
      case 'closed':
        return GlobalStyles.textSecondary;
      default:
        return GlobalStyles.textSecondary;
    }
  }

  /// Format status text
  static String formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'Submitted';
      case 'under review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'appealed':
        return 'Appealed';
      case 'draft':
        return 'Draft';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  /// Format currency
  static String formatCurrency(double? amount) {
    if (amount == null) return '₱0.00';
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format date
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Build claim icon
  static Widget buildClaimIcon(String status, Color color) {
    IconData icon;
    switch (status.toLowerCase()) {
      case 'submitted':
        icon = LucideIcons.clock;
        break;
      case 'under review':
        icon = LucideIcons.search;
        break;
      case 'approved':
        icon = LucideIcons.circleCheck;
        break;
      case 'rejected':
        icon = LucideIcons.circleX;
        break;
      case 'appealed':
        icon = LucideIcons.circleAlert;
        break;
      case 'draft':
        icon = LucideIcons.pencil;
        break;
      case 'closed':
        icon = LucideIcons.archive;
        break;
      default:
        icon = LucideIcons.fileText;
    }

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
      ),
      child: Icon(icon, color: color, size: GlobalStyles.iconSizeLg),
    );
  }

  /// Build claim card
  static Widget buildClaimCard({
    required ClaimModel claim,
    required VoidCallback onTap,
  }) {
    final color = statusColor(claim.status);
    final formattedStatus = formatStatus(claim.status);
    final formattedAmount = formatCurrency(claim.estimatedDamageCost);
    final formattedDate = formatDate(claim.updatedAt);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                buildClaimIcon(claim.status, color),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.claimNumber,
                        style: TextStyle(
                          fontSize: GlobalStyles.fontSizeBody1,
                          fontWeight: GlobalStyles.fontWeightSemiBold,
                          fontFamily: GlobalStyles.fontFamilyBody,
                          color: GlobalStyles.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        claim.incidentDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: GlobalStyles.fontSizeBody2,
                          fontFamily: GlobalStyles.fontFamilyBody,
                          color: GlobalStyles.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                GlobalStyles.radiusSm,
                              ),
                            ),
                            child: Text(
                              formattedStatus,
                              style: TextStyle(
                                fontSize: GlobalStyles.fontSizeCaption,
                                fontWeight: GlobalStyles.fontWeightMedium,
                                color: color,
                                fontFamily: GlobalStyles.fontFamilyBody,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            formattedAmount,
                            style: TextStyle(
                              fontSize: GlobalStyles.fontSizeBody2,
                              fontWeight: GlobalStyles.fontWeightMedium,
                              fontFamily: GlobalStyles.fontFamilyBody,
                              color: GlobalStyles.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      LucideIcons.chevronRight,
                      color: GlobalStyles.textTertiary,
                      size: GlobalStyles.iconSizeSm,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: GlobalStyles.fontSizeCaption,
                        fontFamily: GlobalStyles.fontFamilyBody,
                        color: GlobalStyles.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build empty state widget
  static Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GlobalStyles.primaryMain.withValues(alpha: 0.02),
            GlobalStyles.surfaceMain,
          ],
        ),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: GlobalStyles.primaryMain.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: GlobalStyles.iconSizeXl * 1.2,
              color: GlobalStyles.textDisabled,
            ),
          ),
          SizedBox(height: GlobalStyles.paddingNormal),
          Text(
            title,
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody1,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textSecondary,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textTertiary,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            SizedBox(height: GlobalStyles.paddingNormal),
            action,
          ],
        ],
      ),
    );
  }

  /// Build sign-in CTA
  static Widget buildSignInCTA(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color: GlobalStyles.primaryMain.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.logIn,
            size: GlobalStyles.iconSizeXl,
            color: GlobalStyles.primaryMain,
          ),
          SizedBox(height: GlobalStyles.paddingTight),
          Text(
            'Sign in to view your claims',
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody1,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Access your insurance claims and track their status',
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textSecondary,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: GlobalStyles.paddingNormal),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalStyles.primaryMain,
              foregroundColor: GlobalStyles.surfaceMain,
              padding: EdgeInsets.symmetric(
                horizontal: GlobalStyles.paddingNormal,
                vertical: GlobalStyles.paddingTight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
              ),
            ),
            child: Text(
              'Sign In',
              style: TextStyle(
                fontSize: GlobalStyles.fontSizeButton,
                fontWeight: GlobalStyles.fontWeightSemiBold,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build action button (for home screen)
  static Widget buildActionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: GlobalStyles.surfaceMain,
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        elevation: 2,
        shadowColor: iconColor.withValues(alpha: 0.12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
          splashColor: iconColor.withValues(alpha: 0.15),
          highlightColor: iconColor.withValues(alpha: 0.08),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        GlobalStyles.radiusMd,
                      ),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: GlobalStyles.iconSizeLg,
                      color: iconColor,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontWeight: GlobalStyles.fontWeightMedium,
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
