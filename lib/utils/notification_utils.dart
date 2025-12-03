import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/notification_provider.dart';

class NotificationUtils {
  /// Get icon for notification type
  static IconData getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.assessment:
        return LucideIcons.clipboardCheck;
      case NotificationType.document:
        return LucideIcons.fileText;
      case NotificationType.system:
        return LucideIcons.settings;
      case NotificationType.reminder:
        return LucideIcons.bell;
    }
  }

  /// Get color for notification type
  static Color getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.assessment:
        return GlobalStyles.primaryMain;
      case NotificationType.document:
        return GlobalStyles.warningMain;
      case NotificationType.system:
        return GlobalStyles.infoMain;
      case NotificationType.reminder:
        return GlobalStyles.successMain;
    }
  }

  /// Get icon for status (from notification data payload)
  static IconData getIconForStatus(String? status) {
    if (status == null) return LucideIcons.bell;
    switch (status.toLowerCase()) {
      case 'pending':
        return LucideIcons.clock;
      case 'in_progress':
      case 'in-progress':
      case 'processing':
        return LucideIcons.loader;
      case 'completed':
      case 'done':
        return LucideIcons.circleCheck;
      case 'failed':
      case 'error':
        return LucideIcons.circleX;
      case 'warning':
        return LucideIcons.triangleAlert;
      case 'review':
        return LucideIcons.fileSearch;
      case 'approved':
      case 'accept':
      case 'accepted':
        return LucideIcons.circleCheckBig;
      case 'rejected':
      case 'declined':
      case 'deny':
      case 'denied':
        return LucideIcons.circleX;
      default:
        return LucideIcons.bell;
    }
  }

  /// Get color for status (from notification data payload)
  static Color getStatusColor(String? status) {
    if (status == null) return GlobalStyles.primaryMain;
    switch (status.toLowerCase()) {
      case 'pending':
        return GlobalStyles.warningMain;
      case 'in_progress':
      case 'in-progress':
      case 'processing':
        return GlobalStyles.infoMain;
      case 'completed':
      case 'done':
        return GlobalStyles.successMain;
      case 'failed':
      case 'error':
        return GlobalStyles.errorMain;
      case 'warning':
        return GlobalStyles.warningLight;
      case 'review':
        return GlobalStyles.purpleMain;
      case 'approved':
      case 'accept':
      case 'accepted':
        return GlobalStyles.successMain;
      case 'rejected':
      case 'declined':
      case 'deny':
      case 'denied':
        return GlobalStyles.errorMain;
      default:
        return GlobalStyles.primaryMain;
    }
  }

  /// Format timestamp to human-readable string
  static String formatTimeAgo(DateTime timestamp) {
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

  /// Check if notification is high priority
  static bool isHighPriority(AppNotification notification) {
    return notification.priority == NotificationPriority.high ||
        notification.priority == NotificationPriority.urgent;
  }

  /// Filter notifications by type
  static List<AppNotification> filterByType(
    List<AppNotification> notifications,
    NotificationType? type,
  ) {
    if (type == null) return notifications;
    return notifications.where((n) => n.type == type).toList();
  }

  /// Get empty state message for notification type
  static String getEmptyStateMessage(NotificationType? type) {
    switch (type) {
      case NotificationType.assessment:
        return 'No assessment notifications';
      case NotificationType.document:
        return 'No document notifications';
      case NotificationType.system:
        return 'No system notifications';
      case NotificationType.reminder:
        return 'No reminder notifications';
      default:
        return 'No notifications yet';
    }
  }

  /// Get empty state icon for notification type
  static IconData getEmptyStateIcon(NotificationType? type) {
    switch (type) {
      case NotificationType.assessment:
        return LucideIcons.clipboardCheck;
      case NotificationType.document:
        return LucideIcons.fileText;
      case NotificationType.system:
        return LucideIcons.settings;
      case NotificationType.reminder:
        return LucideIcons.bell;
      default:
        return LucideIcons.bell;
    }
  }

  /// Check if notification has navigation target
  static bool hasNavigationTarget(AppNotification notification) {
    if (notification.data == null) return false;
    final data = notification.data!;
    return data.containsKey('assessmentId') ||
        data.containsKey('insuranceCompany');
  }

  /// Get navigation target from notification
  static NavigationTarget? getNavigationTarget(AppNotification notification) {
    if (notification.data == null) return null;
    final data = notification.data!;

    if (data.containsKey('assessmentId')) {
      return NavigationTarget(
        type: NavigationType.assessment,
        id: data['assessmentId'].toString(),
      );
    } else if (data.containsKey('insuranceCompany')) {
      return NavigationTarget(
        type: NavigationType.documents,
        id: data['insuranceCompany'].toString(),
      );
    }

    return null;
  }

  /// Check if notifications list is empty
  static bool isEmpty(List<AppNotification> notifications) {
    return notifications.isEmpty;
  }

  /// Get unread count
  static int getUnreadCount(List<AppNotification> notifications) {
    return notifications.where((n) => !n.isRead).length;
  }
}

/// Navigation target for notification
class NavigationTarget {
  final NavigationType type;
  final String id;

  NavigationTarget({required this.type, required this.id});
}

/// Navigation type enum
enum NavigationType { assessment, documents, settings, profile }
