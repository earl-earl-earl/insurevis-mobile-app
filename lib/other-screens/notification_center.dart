import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'notification_view.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2A2A2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A2A2A),
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
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2A2A2A),
                              ),
                            )
                            : Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF2A2A2A),
                            ),
                    onPressed:
                        provider.isRefreshing
                            ? null
                            : () => provider.refreshNotifications(),
                  ),
                  IconButton(
                    tooltip: 'Mark all as read',
                    icon: Icon(
                      Icons.mark_email_read_rounded,
                      color: Color(0xFF2A2A2A),
                    ),
                    onPressed: () => provider.markAllAsRead(),
                  ),
                  IconButton(
                    tooltip: 'Clear all notifications',
                    icon: Icon(
                      Icons.playlist_remove_rounded,
                      color: Colors.red,
                    ),
                    onPressed: _showClearConfirmation,
                  ),
                  SizedBox(width: 8.w),
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
                      color: GlobalStyles.primaryColor,
                      backgroundColor: GlobalStyles.primaryColor.withOpacity(
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
            backgroundColor: Colors.white,
            color: GlobalStyles.primaryColor,

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
          backgroundColor: Colors.white,
          color: GlobalStyles.primaryColor,
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
    final timeAgo = _formatTimeAgo(notification.timestamp);
    final isHighPriority =
        notification.priority == NotificationPriority.high ||
        notification.priority == NotificationPriority.urgent;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color:
            notification.isRead
                ? Colors.white
                : GlobalStyles.primaryColor.withValues(alpha: 0.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Notification icon - prefer payload status when present
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: (notification.data != null &&
                                notification.data!.containsKey('status')
                            ? _getStatusColor(
                              notification.data!['status']?.toString(),
                            )
                            : _getTypeColor(notification.type))
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.data != null &&
                            notification.data!.containsKey('status')
                        ? _getIconForStatus(
                          notification.data!['status']?.toString(),
                        )
                        : _getTypeIcon(notification.type),
                    color:
                        notification.data != null &&
                                notification.data!.containsKey('status')
                            ? _getStatusColor(
                              notification.data!['status']?.toString(),
                            )
                            : _getTypeColor(notification.type),
                    size: 30.sp,
                  ),
                ),
                SizedBox(width: 12.w),

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
                              style: GoogleFonts.inter(
                                color: Color(0xFF2A2A2A),
                                fontSize: 16.sp,
                                fontWeight:
                                    notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        notification.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Color(0xFF2A2A2A),
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Text(
                            timeAgo,
                            style: GoogleFonts.inter(
                              color: Color(0x772A2A2A),
                              fontSize: 10.sp,
                            ),
                          ),
                          if (isHighPriority) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'HIGH',
                                style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
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
                    Icons.more_horiz_rounded,
                    color: Color(0x992A2A2A),
                    size: 20.sp,
                  ),
                  color: Colors.white,
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
                                  Icons.mark_email_read_rounded,
                                  color: Color(0xFF2A2A2A),
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Mark as read',
                                  style: GoogleFonts.inter(
                                    color: Color(0xFF2A2A2A),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
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
                                Icons.delete_rounded,
                                color: Colors.red,
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Remove',
                                style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
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
    String message;
    IconData icon;

    switch (type) {
      case NotificationType.assessment:
        message = 'No assessment notifications';
        icon = Icons.assessment;
        break;
      case NotificationType.document:
        message = 'No document notifications';
        icon = Icons.description;
        break;
      case NotificationType.system:
        message = 'No system notifications';
        icon = Icons.settings;
        break;
      default:
        message = 'No notifications yet';
        icon = Icons.notifications_none;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: GoogleFonts.inter(
              color: Color(0xFF2A2A2A),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Pull down to refresh',
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.assessment:
        return Icons.assessment_rounded;
      case NotificationType.document:
        return Icons.description_rounded;
      case NotificationType.system:
        return Icons.settings_rounded;
      case NotificationType.reminder:
        return Icons.alarm_rounded;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.assessment:
        return GlobalStyles.primaryColor;
      case NotificationType.document:
        return Colors.orange;
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.reminder:
        return Colors.green;
    }
  }

  // Map payload status string to a specific icon
  IconData _getIconForStatus(String? status) {
    if (status == null) return Icons.notifications;
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_bottom_rounded;
      case 'in_progress':
      case 'in-progress':
      case 'processing':
        return Icons.autorenew_rounded;
      case 'completed':
      case 'done':
        return Icons.check_circle_rounded;
      case 'failed':
      case 'error':
        return Icons.error_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'review':
        return Icons.rate_review_rounded;
      case 'approved':
      case 'accept':
      case 'accepted':
        return Icons.fact_check_rounded;
      case 'rejected':
      case 'declined':
      case 'deny':
      case 'denied':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // Map payload status to a color to use for icon background and tint
  Color _getStatusColor(String? status) {
    if (status == null) return GlobalStyles.primaryColor;
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
      case 'in-progress':
      case 'processing':
        return Colors.blue;
      case 'completed':
      case 'done':
        return Colors.green;
      case 'failed':
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.deepOrange;
      case 'review':
        return Colors.purple;
      case 'approved':
      case 'accept':
      case 'accepted':
        return Colors.green;
      case 'rejected':
      case 'declined':
      case 'deny':
      case 'denied':
        return Colors.red;
      default:
        return GlobalStyles.primaryColor;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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
            backgroundColor: GlobalStyles.backgroundColorStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Clear All Notifications',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to clear all notifications? This action cannot be undone.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: Colors.white70),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Clear All'),
              ),
            ],
          ),
    );
  }
}
