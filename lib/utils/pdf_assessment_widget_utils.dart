import 'package:flutter/material.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget utilities for PDF assessment view
class PDFAssessmentWidgetUtils {
  static Color getSeverityColor(String severity) {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') || lowerSeverity.contains('severe')) {
      return GlobalStyles.errorMain;
    }
    if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      return GlobalStyles.warningMain;
    }
    if (lowerSeverity.contains('low') || lowerSeverity.contains('minor')) {
      return GlobalStyles.successMain;
    }
    return GlobalStyles.infoMain;
  }

  static Widget buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: GlobalStyles.fontSizeH6),
          SizedBox(height: GlobalStyles.spacingSm),
          Text(
            value,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              fontWeight: GlobalStyles.fontWeightBold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: GlobalStyles.spacingXs),
          Text(
            label,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              fontSize: GlobalStyles.fontSizeBody2,
              color: color.withValues(alpha: 0.5),
              fontWeight: GlobalStyles.fontWeightBold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget buildOptionButton(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: GlobalStyles.spacingXs,
          horizontal: GlobalStyles.spacingMd,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : GlobalStyles.surfaceMain,
          borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
          border: Border.all(color: color, width: 2.5),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? GlobalStyles.surfaceMain : color,
              size: GlobalStyles.fontSizeH6,
            ),
            SizedBox(width: GlobalStyles.spacingSm),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? GlobalStyles.surfaceMain : color,
                fontSize: GlobalStyles.fontSizeCaption,
                fontWeight: GlobalStyles.fontWeightBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildCostItem(
    String label,
    double amount,
    String Function(double) formatCurrency,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: GlobalStyles.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textTertiary,
              fontSize: GlobalStyles.fontSizeCaption,
              fontWeight: GlobalStyles.fontWeightMedium,
            ),
          ),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              fontFamily: GlobalStyles.fontFamilyBody,
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeCaption,
              fontWeight: GlobalStyles.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildApiCostBreakdown(
    String option,
    Map<String, dynamic> apiPricing,
    Map<String, dynamic> damage,
    Map<String, dynamic>? bodyPaintPricing,
    String Function(double) formatCurrency,
  ) {
    double laborFee = 0.0;
    double finalPrice = 0.0;
    double bodyPaintPrice = 0.0;
    double thinsmithPrice = 0.0;

    if (option == 'replace') {
      thinsmithPrice = (apiPricing['insurance'] as num?)?.toDouble() ?? 0.0;
      laborFee =
          (apiPricing['cost_installation_personal'] as num?)?.toDouble() ??
          (bodyPaintPricing?['cost_installation_personal'] as num?)
              ?.toDouble() ??
          0.0;
      if (bodyPaintPricing != null) {
        bodyPaintPrice =
            (bodyPaintPricing['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      }
      finalPrice = thinsmithPrice + bodyPaintPrice;
    } else {
      laborFee =
          (apiPricing['cost_installation_personal'] as num?)?.toDouble() ?? 0.0;
      bodyPaintPrice = (apiPricing['srp_insurance'] as num?)?.toDouble() ?? 0.0;
      finalPrice = bodyPaintPrice;
    }

    return Container(
      padding: EdgeInsets.all(GlobalStyles.radiusXl),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Cost Breakdown',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeCaption,
                  fontWeight: GlobalStyles.fontWeightBold,
                  color: GlobalStyles.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: GlobalStyles.spacingSm),
          buildCostItem('Labor Fee', laborFee, formatCurrency),
          if (option == 'repair') ...[
            SizedBox(height: GlobalStyles.spacingSm),
            buildCostItem('Paint Price', bodyPaintPrice, formatCurrency),
          ] else if (option == 'replace') ...[
            SizedBox(height: GlobalStyles.spacingSm),
            buildCostItem('Part Price', thinsmithPrice, formatCurrency),
            buildCostItem('Paint Price', bodyPaintPrice, formatCurrency),
          ],
          Divider(
            color: GlobalStyles.textSecondary.withValues(alpha: 0.3),
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Estimated Total:',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    color: GlobalStyles.textPrimary,
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontWeight: GlobalStyles.fontWeightBold,
                  ),
                ),
              ),
              Text(
                formatCurrency(finalPrice),
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  color: GlobalStyles.primaryMain,
                  fontSize: GlobalStyles.fontSizeBody1,
                  fontWeight: GlobalStyles.fontWeightBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildDamageInfo(String damagedPart, String damageType) {
    return Container(
      padding: EdgeInsets.all(GlobalStyles.spacingMd),
      decoration: BoxDecoration(
        color: GlobalStyles.primaryMain.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(color: GlobalStyles.surfaceMain.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.wrench,
                color: GlobalStyles.primaryMain,
                size: GlobalStyles.fontSizeBody1,
              ),
              SizedBox(width: GlobalStyles.spacingSm),
              Text(
                'Part:',
                style: TextStyle(
                  fontFamily: GlobalStyles.fontFamilyBody,
                  fontSize: GlobalStyles.fontSizeCaption,
                  color: GlobalStyles.textTertiary,
                ),
              ),
              Expanded(
                child: Text(
                  ' $damagedPart',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeCaption,
                    fontWeight: GlobalStyles.fontWeightBold,
                    color: GlobalStyles.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (damageType.trim().isNotEmpty) ...[
            SizedBox(height: GlobalStyles.spacingSm),
            Row(
              children: [
                Icon(
                  LucideIcons.info,
                  color: GlobalStyles.warningMain,
                  size: GlobalStyles.fontSizeBody1,
                ),
                SizedBox(width: GlobalStyles.spacingSm),
                Text(
                  'Damage:',
                  style: TextStyle(
                    fontFamily: GlobalStyles.fontFamilyBody,
                    fontSize: GlobalStyles.fontSizeCaption,
                    color: GlobalStyles.textTertiary,
                  ),
                ),
                Expanded(
                  child: Text(
                    ' $damageType',
                    style: TextStyle(
                      fontFamily: GlobalStyles.fontFamilyBody,
                      fontSize: GlobalStyles.fontSizeCaption,
                      fontWeight: GlobalStyles.fontWeightBold,
                      color: GlobalStyles.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
