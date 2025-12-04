import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/models/insurevis_models.dart';
import 'package:insurevis/utils/claim_details_handler_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Utilities for building claim details UI widgets
class ClaimDetailsWidgetUtils {
  /// Build party status chip (car company or insurance)
  static Widget buildPartyStatusChip(
    BuildContext context,
    DocumentModel doc, {
    required bool isCarCompany,
  }) {
    final info = ClaimDetailsHandlerUtils.getPartyStatusInfo(doc, isCarCompany);
    final color = info['color'] as Color;
    final text = info['text'] as String;
    final note = info['note'] as String?;

    return GestureDetector(
      onTap: () {
        if (note != null && note.trim().isNotEmpty) {
          final date =
              isCarCompany
                  ? doc.carCompanyVerificationDate
                  : doc.insuranceVerificationDate;
          showDialog<void>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(
                    isCarCompany
                        ? 'Car Company Rejection'
                        : 'Insurance Rejection',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (date != null) ...[
                        Text(
                          'Rejected on: ${DateFormat.yMMMd().format(date)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
                            color: GlobalStyles.textSecondary,
                            fontFamily: GlobalStyles.fontFamilyBody,
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                      Text(
                        'Reason:',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        ClaimDetailsHandlerUtils.formatRejectionNote(note),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ],
                ),
          );
          return;
        }
        showDialog<void>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  isCarCompany ? 'Car Company Status' : 'Insurance Status',
                ),
                content: Text(
                  text == 'Pending' ? 'No verification yet.' : 'Status: $text',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                ],
              ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isCarCompany ? 'Car Company' : 'Insurance Company'}: $text',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
              if (note != null && note.trim().isNotEmpty) ...[
                SizedBox(width: 4.w),
                Icon(
                  Icons.info_outline,
                  size: 12.sp,
                  color: color.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build status chips for document
  static List<Widget> buildStatusChips(
    BuildContext context,
    DocumentModel doc,
  ) {
    List<Widget> chips = [];
    chips.add(buildPartyStatusChip(context, doc, isCarCompany: true));
    chips.add(buildPartyStatusChip(context, doc, isCarCompany: false));

    List<Widget> spaced = [];
    for (int i = 0; i < chips.length; i++) {
      spaced.add(chips[i]);
      if (i < chips.length - 1) {
        spaced.add(SizedBox(width: 6.w));
      }
    }
    return spaced;
  }

  /// Show discard changes dialog
  static Future<bool> showDiscardChangesDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Discard Changes?'),
            content: Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Discard'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  /// Show delete document confirmation dialog
  static Future<bool> showDeleteDocumentDialog(
    BuildContext context,
    String fileName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Document?'),
            content: Text('Are you sure you want to delete $fileName?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
    );
    return confirm ?? false;
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GlobalStyles.successMain,
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Build document category header
  static Widget buildDocumentCategoryHeader(String category) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GlobalStyles.primaryMain.withValues(alpha: 0.08),
            GlobalStyles.primaryMain.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusSm),
        border: Border(
          left: BorderSide(color: GlobalStyles.primaryMain, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.fileText,
            size: GlobalStyles.iconSizeSm,
            color: GlobalStyles.primaryMain,
          ),
          SizedBox(width: 8.w),
          Text(
            ClaimDetailsHandlerUtils.getDocumentCategoryDisplayName(category),
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody1,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              fontFamily: GlobalStyles.fontFamilyHeading,
              color: GlobalStyles.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading indicator
  static Widget buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(color: GlobalStyles.primaryMain),
    );
  }

  /// Build error message
  static Widget buildErrorMessage(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Text(
          message,
          style: TextStyle(
            fontSize: GlobalStyles.fontSizeBody2,
            color: GlobalStyles.errorMain,
            fontFamily: GlobalStyles.fontFamilyBody,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
