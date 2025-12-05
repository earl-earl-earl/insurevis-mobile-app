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

class _NotificationCenterState extends State<NotificationCenter>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 1,
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
            fontSize: GlobalStyles.fontSizeH4,
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
                              width: 20.sp,
                              height: 20.sp,
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
      body: FadeTransition(
        opacity: _fadeAnimation,
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
              return _buildAnimatedNotificationCard(notification, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimatedNotificationCard(
    AppNotification notification,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _buildNotificationCard(notification),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final timeAgo = NotificationUtils.formatTimeAgo(notification.timestamp);
    final isHighPriority = NotificationUtils.isHighPriority(notification);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color:
            notification.isRead
                ? GlobalStyles.surfaceMain
                : GlobalStyles.primaryMain.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
        border: Border.all(
          color:
              notification.isRead
                  ? GlobalStyles.textDisabled.withValues(alpha: 0.1)
                  : GlobalStyles.primaryMain.withValues(alpha: 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread indicator dot
                if (!notification.isRead)
                  Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: GlobalStyles.primaryMain,
                      shape: BoxShape.circle,
                    ),
                    margin: EdgeInsets.only(top: 8.h, right: 8.w),
                  )
                else
                  SizedBox(width: 8.w, height: 8.h),

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
                    borderRadius: BorderRadius.circular(12.r),
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
                                fontSize: GlobalStyles.fontSizeBody1,
                                fontWeight:
                                    notification.isRead
                                        ? GlobalStyles.fontWeightSemiBold
                                        : GlobalStyles.fontWeightBold,
                                fontFamily: GlobalStyles.fontFamilyBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
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
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 14.sp,
                            color: GlobalStyles.textDisabled,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: GlobalStyles.textDisabled,
                              fontSize: GlobalStyles.fontSizeCaption,
                              fontFamily: GlobalStyles.fontFamilyBody,
                            ),
                          ),
                          if (isHighPriority) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: GlobalStyles.errorMain.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'HIGH',
                                style: TextStyle(
                                  color: GlobalStyles.errorMain,
                                  fontSize: 10.sp,
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
                    size: 20.sp,
                  ),
                  color: GlobalStyles.surfaceMain,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
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
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
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
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
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
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 30),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.sp,
              height: 80.sp,
              decoration: BoxDecoration(
                color: GlobalStyles.primaryMain.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40.sp, color: GlobalStyles.primaryMain),
            ),
            SizedBox(height: 24.h),
            Text(
              message,
              style: TextStyle(
                color: GlobalStyles.textPrimary,
                fontSize: GlobalStyles.fontSizeH5,
                fontWeight: GlobalStyles.fontWeightSemiBold,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Pull down to refresh',
              style: TextStyle(
                color: GlobalStyles.textSecondary,
                fontSize: GlobalStyles.fontSizeBody2,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
            ),
          ],
        ),
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
            backgroundColor: GlobalStyles.surfaceMain,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
            ),
            elevation: 8,
            title: Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 40.sp,
                    height: 40.sp,
                    decoration: BoxDecoration(
                      color: GlobalStyles.errorMain.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      LucideIcons.trash2,
                      size: 20.sp,
                      color: GlobalStyles.errorMain,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Clear All Notifications',
                      style: TextStyle(
                        color: GlobalStyles.textPrimary,
                        fontSize: GlobalStyles.fontSizeH6,
                        fontWeight: GlobalStyles.fontWeightBold,
                        fontFamily: GlobalStyles.fontFamilyBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            content: Text(
              'Are you sure you want to clear all notifications? This action cannot be undone.',
              style: TextStyle(
                color: GlobalStyles.textSecondary,
                fontSize: GlobalStyles.fontSizeBody2,
                fontFamily: GlobalStyles.fontFamilyBody,
                height: 1.6,
              ),
            ),
            actionsPadding: EdgeInsets.all(16.w),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: GlobalStyles.textPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: GlobalStyles.fontSizeBody1,
                    fontWeight: GlobalStyles.fontWeightMedium,
                    fontFamily: GlobalStyles.fontFamilyBody,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
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
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
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
