import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'notification_view.dart';
import 'package:insurevis/utils/notification_utils.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  @override
  Widget build(BuildContext context) {
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
          'Notifications',
          style: TextStyle(
            fontSize: GlobalStyles.fontSizeH5,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            color: GlobalStyles.textPrimary,
            fontFamily: GlobalStyles.fontFamilyHeading,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Refresh notifications',
                    icon:
                        provider.isRefreshing
                            ? SizedBox(
                              width: GlobalStyles.iconSizeSm,
                              height: GlobalStyles.iconSizeSm,
                              child: CircularProgressIndicator(
                                strokeWidth: GlobalStyles.iconStrokeWidthNormal,
                                color: GlobalStyles.primaryMain,
                              ),
                            )
                            : Icon(
                              LucideIcons.refreshCw,
                              color: GlobalStyles.textPrimary,
                              size: GlobalStyles.iconSizeMd,
                            ),
                    onPressed:
                        provider.isRefreshing
                            ? null
                            : () => provider.refreshNotifications(),
                  ),
                  IconButton(
                    tooltip: 'Mark all as read',
                    icon: Icon(
                      LucideIcons.mailCheck,
                      color: GlobalStyles.textPrimary,
                      size: GlobalStyles.iconSizeMd,
                    ),
                    onPressed: () => provider.markAllAsRead(),
                  ),
                  IconButton(
                    tooltip: 'Clear all notifications',
                    icon: Icon(
                      LucideIcons.trash2,
                      color: GlobalStyles.errorMain,
                      size: GlobalStyles.iconSizeMd,
                    ),
                    onPressed: _showClearConfirmation,
                  ),
                  SizedBox(width: GlobalStyles.spacingSm),
                ],
              );
            },
          ),
        ],
      ),
      body: SizedBox(
        child: Column(
          children: [
            // Loading indicator during refresh
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return provider.isRefreshing
                    ? LinearProgressIndicator(
                      color: GlobalStyles.primaryMain,
                      backgroundColor: GlobalStyles.primaryMain.withOpacity(
                        0.2,
                      ),
                    )
                    : const SizedBox.shrink();
              },
            ),
            // Single notifications list (no tabs)
            Expanded(child: _buildNotificationList()),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList([NotificationType? filterType]) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        var notifications = provider.notifications;

        if (filterType != null) {
          notifications =
              notifications.where((n) => n.type == filterType).toList();
        }

        if (notifications.isEmpty) {
          return RefreshIndicator(
            backgroundColor: GlobalStyles.surfaceMain,
            color: GlobalStyles.primaryMain,
            onRefresh: () => provider.refreshNotifications(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmptyState(filterType),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          backgroundColor: GlobalStyles.surfaceMain,
          color: GlobalStyles.primaryMain,
          onRefresh: () => provider.refreshNotifications(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final timeAgo = NotificationUtils.formatTimeAgo(notification.timestamp);
    final isHighPriority = NotificationUtils.isHighPriority(notification);

    return Container(
      decoration: BoxDecoration(
        color:
            notification.isRead
                ? GlobalStyles.surfaceMain
                : GlobalStyles.primaryMain.withOpacity(0.08),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: GlobalStyles.paddingNormal,
              vertical: GlobalStyles.spacingMd,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Notification icon - prefer payload status when present
                Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: (notification.data != null &&
                                notification.data!.containsKey('status')
                            ? NotificationUtils.getStatusColor(
                              notification.data!['status']?.toString(),
                            )
                            : NotificationUtils.getTypeColor(notification.type))
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
                            : NotificationUtils.getTypeColor(notification.type),
                    size: GlobalStyles.iconSizeMd,
                  ),
                ),
                SizedBox(width: GlobalStyles.spacingMd),

                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: GlobalStyles.textPrimary,
                                fontSize: GlobalStyles.fontSizeH6,
                                fontWeight:
                                    notification.isRead
                                        ? GlobalStyles.fontWeightSemiBold
                                        : GlobalStyles.fontWeightBold,
                                fontFamily: GlobalStyles.fontFamilyHeading,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: GlobalStyles.spacingXs),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: GlobalStyles.textSecondary,
                          fontSize: GlobalStyles.fontSizeBody2,
                          fontFamily: GlobalStyles.fontFamilyBody,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: GlobalStyles.spacingSm),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: GlobalStyles.iconSizeXs,
                            color: GlobalStyles.textDisabled,
                          ),
                          SizedBox(width: GlobalStyles.spacingXs),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: GlobalStyles.textDisabled,
                              fontSize: GlobalStyles.fontSizeCaption,
                              fontFamily: GlobalStyles.fontFamilyBody,
                            ),
                          ),
                          if (isHighPriority) ...[
                            SizedBox(width: GlobalStyles.spacingSm),
                            Container(
                              padding: GlobalStyles.chipPadding,
                              decoration: BoxDecoration(
                                color: GlobalStyles.errorMain.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                  GlobalStyles.chipBorderRadius,
                                ),
                              ),
                              child: Text(
                                'HIGH',
                                style: TextStyle(
                                  color: GlobalStyles.errorMain,
                                  fontSize: GlobalStyles.chipFontSize,
                                  fontWeight: GlobalStyles.fontWeightBold,
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action button
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.ellipsis,
                    color: GlobalStyles.textTertiary,
                    size: GlobalStyles.iconSizeSm,
                  ),
                  color: GlobalStyles.surfaceMain,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
                  ),
                  elevation: 4,
                  onSelected: (value) {
                    final provider = Provider.of<NotificationProvider>(
                      context,
                      listen: false,
                    );
                    switch (value) {
                      case 'mark_read':
                        provider.markAsRead(notification.id);
                        break;
                      case 'remove':
                        provider.removeNotification(notification.id);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        if (!notification.isRead)
                          PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.mailCheck,
                                  color: GlobalStyles.textPrimary,
                                  size: GlobalStyles.iconSizeXs,
                                ),
                                SizedBox(width: GlobalStyles.spacingSm),
                                Text(
                                  'Mark as read',
                                  style: TextStyle(
                                    color: GlobalStyles.textPrimary,
                                    fontSize: GlobalStyles.fontSizeBody2,
                                    fontWeight: GlobalStyles.fontWeightMedium,
                                    fontFamily: GlobalStyles.fontFamilyBody,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trash2,
                                color: GlobalStyles.errorMain,
                                size: GlobalStyles.iconSizeXs,
                              ),
                              SizedBox(width: GlobalStyles.spacingSm),
                              Text(
                                'Remove',
                                style: TextStyle(
                                  color: GlobalStyles.errorMain,
                                  fontSize: GlobalStyles.fontSizeBody2,
                                  fontWeight: GlobalStyles.fontWeightMedium,
                                  fontFamily: GlobalStyles.fontFamilyBody,
                                ),
                              ),
                            ],
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

  Widget _buildEmptyState(NotificationType? type) {
    final message = NotificationUtils.getEmptyStateMessage(type);
    final icon = NotificationUtils.getEmptyStateIcon(type);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: GlobalStyles.primaryMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: GlobalStyles.iconSizeLg,
              color: GlobalStyles.primaryMain,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingMd),
          Text(
            message,
            style: TextStyle(
              color: GlobalStyles.textPrimary,
              fontSize: GlobalStyles.fontSizeH6,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              fontFamily: GlobalStyles.fontFamilyHeading,
            ),
          ),
          SizedBox(height: GlobalStyles.spacingSm),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              color: GlobalStyles.textTertiary,
              fontSize: GlobalStyles.fontSizeBody2,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    // Mark as read if not already
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Handle navigation based on notification data
    if (notification.data != null) {
      final data = notification.data!;

      if (data.containsKey('assessmentId')) {
        // Navigate to assessment details
        Navigator.pop(context); // Close notification center
        // Add navigation logic here
      } else if (data.containsKey('insuranceCompany')) {
        // Navigate to documents screen
        Navigator.pop(context);
        // Add navigation logic here
      } else {
        // No special target — open the notification viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationView(notification: notification),
          ),
        );
      }
    } else {
      // No data — open viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationView(notification: notification),
        ),
      );
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: GlobalStyles.dialogBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                GlobalStyles.dialogBorderRadius,
              ),
            ),
            title: Text(
              'Clear All Notifications',
              style: TextStyle(
                color: GlobalStyles.textPrimary,
                fontSize: GlobalStyles.fontSizeH5,
                fontWeight: GlobalStyles.fontWeightBold,
                fontFamily: GlobalStyles.fontFamilyHeading,
              ),
            ),
            content: Text(
              'Are you sure you want to clear all notifications? This action cannot be undone.',
              style: TextStyle(
                color: GlobalStyles.textSecondary,
                fontSize: GlobalStyles.fontSizeBody2,
                fontFamily: GlobalStyles.fontFamilyBody,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: GlobalStyles.textPrimary,
                  padding: GlobalStyles.buttonPadding,
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeButton,
                    fontWeight: GlobalStyles.fontWeightMedium,
                    fontFamily: GlobalStyles.fontFamilyBody,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Provider.of<NotificationProvider>(
                    context,
                    listen: false,
                  ).clearAllNotifications();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalStyles.errorMain,
                  foregroundColor: GlobalStyles.surfaceMain,
                  padding: GlobalStyles.buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      GlobalStyles.buttonBorderRadius,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeButton,
                    fontWeight: GlobalStyles.fontWeightMedium,
                    fontFamily: GlobalStyles.fontFamilyBody,
                    letterSpacing: GlobalStyles.letterSpacingButton,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
