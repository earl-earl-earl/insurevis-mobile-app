import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/utils/notification_utils.dart';

class NotificationView extends StatelessWidget {
  final AppNotification notification;

  const NotificationView({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final timeLabel = NotificationUtils.formatTimeAgo(notification.timestamp);

    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 0,
        shadowColor: GlobalStyles.shadowSm.color,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: GlobalStyles.textPrimary,
            size: GlobalStyles.iconSizeMd,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification',
          style: TextStyle(
            fontSize: GlobalStyles.fontSizeH5,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            color: GlobalStyles.textPrimary,
            fontFamily: GlobalStyles.fontFamilyHeading,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(GlobalStyles.paddingNormal),
        child: Container(
          padding: GlobalStyles.cardPadding,
          decoration: BoxDecoration(
            color: GlobalStyles.cardBackground,
            borderRadius: BorderRadius.circular(GlobalStyles.cardBorderRadius),
            boxShadow: [GlobalStyles.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64.w,
                    height: 64.h,
                    decoration: BoxDecoration(
                      color: (notification.data != null &&
                                  notification.data!.containsKey('status')
                              ? NotificationUtils.getStatusColor(
                                notification.data!['status']?.toString(),
                              )
                              : NotificationUtils.getTypeColor(
                                notification.type,
                              ))
                          .withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notification.data != null &&
                              notification.data!.containsKey('status')
                          ? NotificationUtils.getIconForStatus(
                            notification.data!['status']?.toString(),
                          )
                          : NotificationUtils.getTypeIcon(notification.type),
                      color:
                          notification.data != null &&
                                  notification.data!.containsKey('status')
                              ? NotificationUtils.getStatusColor(
                                notification.data!['status']?.toString(),
                              )
                              : NotificationUtils.getTypeColor(
                                notification.type,
                              ),
                      size: GlobalStyles.iconSizeLg,
                    ),
                  ),
                  SizedBox(width: GlobalStyles.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            color: GlobalStyles.textPrimary,
                            fontSize: GlobalStyles.fontSizeH4,
                            fontWeight: GlobalStyles.fontWeightBold,
                            fontFamily: GlobalStyles.fontFamilyHeading,
                            letterSpacing: GlobalStyles.letterSpacingH4,
                          ),
                        ),
                        SizedBox(height: GlobalStyles.spacingXs),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: GlobalStyles.iconSizeXs,
                              color: GlobalStyles.textTertiary,
                            ),
                            SizedBox(width: GlobalStyles.spacingXs),
                            Text(
                              timeLabel,
                              style: TextStyle(
                                color: GlobalStyles.textTertiary,
                                fontSize: GlobalStyles.fontSizeBody2,
                                fontFamily: GlobalStyles.fontFamilyBody,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: GlobalStyles.spacingLg),
              Divider(color: GlobalStyles.inputBorderColor, thickness: 1),
              SizedBox(height: GlobalStyles.spacingLg),
              Text(
                notification.message,
                style: TextStyle(
                  color: GlobalStyles.textSecondary,
                  fontSize: GlobalStyles.fontSizeBody1,
                  fontFamily: GlobalStyles.fontFamilyBody,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
