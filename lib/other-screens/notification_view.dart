import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/notification_provider.dart';

class NotificationView extends StatelessWidget {
  final AppNotification notification;

  const NotificationView({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final timeAgo = DateTime.now().difference(notification.timestamp);
    String timeLabel;
    if (timeAgo.inDays > 0) {
      timeLabel = '${timeAgo.inDays}d ago';
    } else if (timeAgo.inHours > 0) {
      timeLabel = '${timeAgo.inHours}h ago';
    } else if (timeAgo.inMinutes > 0) {
      timeLabel = '${timeAgo.inMinutes}m ago';
    } else {
      timeLabel = 'Just now';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2A2A2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A2A2A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56.w,
                  height: 56.h,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.inter(
                          color: Color(0xFF2A2A2A),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        timeLabel,
                        style: GoogleFonts.inter(
                          color: Color(0x992A2A2A),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // Message body - allow wrapping and long content via scrolling
            Text(
              notification.message,
              style: GoogleFonts.inter(
                color: Color(0xFF2A2A2A),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
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
}
