import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/utils/notification_utils.dart';

class NotificationView extends StatefulWidget {
  final AppNotification notification;

  const NotificationView({super.key, required this.notification});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: GlobalStyles.durationNormal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: GlobalStyles.easingDecelerate,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: GlobalStyles.easingDecelerate,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: GlobalStyles.easingDecelerate,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getIconContainerColor() {
    return (widget.notification.data != null &&
                widget.notification.data!.containsKey('status')
            ? NotificationUtils.getStatusColor(
              widget.notification.data!['status']?.toString(),
            )
            : NotificationUtils.getTypeColor(widget.notification.type))
        .withOpacity(0.12);
  }

  Color _getIconColor() {
    return widget.notification.data != null &&
            widget.notification.data!.containsKey('status')
        ? NotificationUtils.getStatusColor(
          widget.notification.data!['status']?.toString(),
        )
        : NotificationUtils.getTypeColor(widget.notification.type);
  }

  IconData _getNotificationIcon() {
    return widget.notification.data != null &&
            widget.notification.data!.containsKey('status')
        ? NotificationUtils.getIconForStatus(
          widget.notification.data!['status']?.toString(),
        )
        : NotificationUtils.getTypeIcon(widget.notification.type);
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = NotificationUtils.formatTimeAgo(
      widget.notification.timestamp,
    );

    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 0,
        shadowColor: GlobalStyles.shadowSm.color,
        leading: ScaleTransition(
          scale: Tween<double>(
            begin: 1.0,
            end: 0.85,
          ).animate(_animationController),
          child: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: GlobalStyles.textPrimary,
              size: GlobalStyles.iconSizeMd,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Go back',
          ),
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'Notification',
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeH5,
              fontWeight: GlobalStyles.fontWeightSemiBold,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyHeading,
              letterSpacing: GlobalStyles.letterSpacingH4,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: GlobalStyles.paddingNormal,
          vertical: GlobalStyles.spacingLg,
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: GlobalStyles.cardPadding,
                decoration: BoxDecoration(
                  color: GlobalStyles.cardBackground,
                  borderRadius: BorderRadius.circular(
                    GlobalStyles.cardBorderRadius,
                  ),
                  boxShadow: [GlobalStyles.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section with Icon and Title
                    _buildHeaderSection(timeLabel),
                    SizedBox(height: GlobalStyles.spacingXl),
                    // Divider with enhanced styling
                    Container(
                      height: 1.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            GlobalStyles.inputBorderColor.withOpacity(0),
                            GlobalStyles.inputBorderColor,
                            GlobalStyles.inputBorderColor.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: GlobalStyles.spacingXl),
                    // Content Section
                    _buildContentSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(String timeLabel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated Icon Container
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_scaleAnimation.value * 0.2),
              child: child,
            );
          },
          child: Container(
            width: 72.w,
            height: 72.h,
            decoration: BoxDecoration(
              color: _getIconContainerColor(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getIconColor().withOpacity(0.2),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              _getNotificationIcon(),
              color: _getIconColor(),
              size: GlobalStyles.iconSizeLg,
            ),
          ),
        ),
        SizedBox(width: GlobalStyles.spacingLg),
        // Title and Time Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with enhanced typography
              Text(
                widget.notification.title,
                style: TextStyle(
                  color: GlobalStyles.textPrimary,
                  fontSize: GlobalStyles.fontSizeH4,
                  fontWeight: GlobalStyles.fontWeightBold,
                  fontFamily: GlobalStyles.fontFamilyHeading,
                  letterSpacing: GlobalStyles.letterSpacingH4,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: GlobalStyles.spacingMd),
              // Timestamp with Icon
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value * 0.8,
                    child: child,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: GlobalStyles.spacingMd,
                    vertical: GlobalStyles.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: GlobalStyles.backgroundAlternative,
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: GlobalStyles.iconSizeSm,
                        color: GlobalStyles.textTertiary,
                      ),
                      SizedBox(width: GlobalStyles.spacingSm),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: GlobalStyles.textTertiary,
                          fontSize: GlobalStyles.fontSizeBody2,
                          fontFamily: GlobalStyles.fontFamilyBody,
                          fontWeight: GlobalStyles.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message Content
        AnimatedBuilder(
          animation: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(_animationController),
          builder: (context, child) {
            return Opacity(opacity: _fadeAnimation.value, child: child);
          },
          child: Text(
            widget.notification.message,
            style: TextStyle(
              color: GlobalStyles.textSecondary,
              fontSize: GlobalStyles.fontSizeBody1,
              fontFamily: GlobalStyles.fontFamilyBody,
              height: 1.7,
              fontWeight: GlobalStyles.fontWeightRegular,
            ),
          ),
        ),
        SizedBox(height: GlobalStyles.spacingXl),
        // Action Button
        _buildActionButton(),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlobalStyles.buttonBorderRadius),
        boxShadow: [GlobalStyles.shadowSm],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle action - navigate or close
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(GlobalStyles.buttonBorderRadius),
          child: AnimatedContainer(
            duration: GlobalStyles.durationNormal,
            curve: GlobalStyles.easingDefault,
            padding: GlobalStyles.buttonPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                GlobalStyles.buttonBorderRadius,
              ),
              gradient: LinearGradient(
                colors: [_getIconColor().withOpacity(0.9), _getIconColor()],
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.arrowRight,
                    color: Colors.white,
                    size: GlobalStyles.iconSizeMd,
                  ),
                  SizedBox(width: GlobalStyles.spacingSm),
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: GlobalStyles.fontSizeButton,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                      fontFamily: GlobalStyles.fontFamilyBody,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
