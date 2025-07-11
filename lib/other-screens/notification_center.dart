import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:intl/intl.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalStyles.backgroundColorStart,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColorStart,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                color: GlobalStyles.backgroundColorEnd,
                onSelected: (value) {
                  switch (value) {
                    case 'mark_all_read':
                      provider.markAllAsRead();
                      break;
                    case 'clear_all':
                      _showClearConfirmation();
                      break;
                    case 'settings':
                      _showNotificationSettings();
                      break;
                    case 'add_test':
                      provider.addTestNotifications();
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'mark_all_read',
                        child: Row(
                          children: [
                            Icon(Icons.mark_email_read, color: Colors.white70),
                            SizedBox(width: 12.w),
                            Text(
                              'Mark all as read',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, color: Colors.red),
                            SizedBox(width: 12.w),
                            Text(
                              'Clear all',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, color: Colors.white70),
                            SizedBox(width: 12.w),
                            Text(
                              'Settings',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'add_test',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle, color: Colors.blue),
                            SizedBox(width: 12.w),
                            Text(
                              'Add Test Notifications',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.backgroundColorStart,
              GlobalStyles.backgroundColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Tab bar for filtering notifications
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: GlobalStyles.primaryColor,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(fontSize: 12.sp),
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Assessments'),
                  Tab(text: 'Documents'),
                  Tab(text: 'System'),
                ],
              ),
            ),

            // Notification list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationList(),
                  _buildNotificationList(NotificationType.assessment),
                  _buildNotificationList(NotificationType.document),
                  _buildNotificationList(NotificationType.system),
                ],
              ),
            ),
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
          return _buildEmptyState(filterType);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification);
          },
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
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color:
            notification.isRead
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              notification.isRead
                  ? Colors.transparent
                  : isHighPriority
                  ? Colors.red.withValues(alpha: 0.5)
                  : GlobalStyles.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    _getTypeIcon(notification.type),
                    color: _getTypeColor(notification.type),
                    size: 20.sp,
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight:
                                    notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                color: GlobalStyles.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.white54,
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
                                style: TextStyle(
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
                    Icons.more_vert,
                    color: Colors.white54,
                    size: 16.sp,
                  ),
                  color: GlobalStyles.backgroundColorEnd,
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
                                  Icons.mark_email_read,
                                  color: Colors.white70,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Mark as read',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
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
                                Icons.delete,
                                color: Colors.red,
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Remove',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.sp,
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
              color: Colors.black.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40.sp,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Notifications will appear here',
            style: TextStyle(color: Colors.white54, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.assessment:
        return Icons.assessment;
      case NotificationType.document:
        return Icons.description;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.reminder:
        return Icons.alarm;
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
      }
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
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to clear all notifications? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.white70)),
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

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: GlobalStyles.backgroundColorStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Notification Settings',
              style: TextStyle(color: Colors.white),
            ),
            content: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Enable Notifications',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Turn on/off all notifications',
                        style: TextStyle(color: Colors.white54),
                      ),
                      value: provider.notificationsEnabled,
                      onChanged:
                          (value) => provider.setNotificationsEnabled(value),
                      activeColor: GlobalStyles.primaryColor,
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: GlobalStyles.primaryColor),
                ),
              ),
            ],
          ),
    );
  }
}
