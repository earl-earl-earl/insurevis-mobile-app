import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/utils/account_utils.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen>
    with TickerProviderStateMixin {
  bool _acknowledged = false;
  bool _isProcessing = false;
  bool _obscurePassword = true;
  final _confirmController = TextEditingController();
  final _passwordController = TextEditingController();
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

  Widget _buildAnimatedInfoSection() {
    final items = [
      'Your login access will be revoked.',
      'All documents and verifications will be deleted.',
      'Any pending processes will be canceled.',
    ];
    return Column(
      children: List.generate(
        items.length,
        (index) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset((1 - value) * 20, 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: GlobalStyles.errorMain.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(
                    LucideIcons.check,
                    size: 12.sp,
                    color: GlobalStyles.errorMain,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    items[index],
                    style: TextStyle(
                      fontSize: GlobalStyles.fontSizeBody2,
                      color: GlobalStyles.textPrimary,
                      fontFamily: GlobalStyles.fontFamilyBody,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _confirmController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeH5,
            fontWeight: GlobalStyles.fontWeightSemiBold,
          ),
        ),
        backgroundColor: GlobalStyles.surfaceMain,
        iconTheme: IconThemeData(color: GlobalStyles.textPrimary),
      ),
      backgroundColor: GlobalStyles.surfaceMain,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: GlobalStyles.errorMain.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(GlobalStyles.radiusMd),
                    border: Border.all(
                      color: GlobalStyles.errorMain.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: GlobalStyles.errorMain.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.radiusSm,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.triangleAlert,
                          color: GlobalStyles.errorMain,
                          size: GlobalStyles.iconSizeMd,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This action is permanent',
                              style: TextStyle(
                                fontSize: GlobalStyles.fontSizeBody1,
                                fontWeight: GlobalStyles.fontWeightBold,
                                color: GlobalStyles.errorMain,
                                fontFamily: GlobalStyles.fontFamilyHeading,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Your account and data will be permanently deleted.',
                              style: TextStyle(
                                fontSize: GlobalStyles.fontSizeCaption,
                                color: GlobalStyles.textSecondary,
                                fontFamily: GlobalStyles.fontFamilyBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: GlobalStyles.paddingLoose),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before you proceed',
                    style: TextStyle(
                      color: GlobalStyles.errorMain,
                      fontSize: GlobalStyles.fontSizeBody1,
                      fontWeight: GlobalStyles.fontWeightBold,
                      fontFamily: GlobalStyles.fontFamilyHeading,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Container(
                        height: 3.h,
                        width: 50.w * value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              GlobalStyles.errorMain,
                              GlobalStyles.errorMain.withValues(alpha: 0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _buildAnimatedInfoSection(),

              SizedBox(height: GlobalStyles.paddingLoose),

              Text(
                'Type CONFIRM to proceed',
                style: TextStyle(
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightSemiBold,
                  color: GlobalStyles.textPrimary,
                  fontFamily: GlobalStyles.fontFamilyHeading,
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _confirmController,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: GlobalStyles.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Type: CONFIRM',
                  hintStyle: TextStyle(
                    color: GlobalStyles.textSecondary,
                    fontSize: GlobalStyles.fontSizeBody2,
                    letterSpacing: 0.5,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.fileCheck,
                    color:
                        _confirmController.text.toUpperCase() == 'CONFIRM'
                            ? GlobalStyles.successMain
                            : GlobalStyles.textTertiary,
                    size: GlobalStyles.iconSizeSm,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16.h,
                    horizontal: 14.w,
                  ),
                  filled: true,
                  fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: GlobalStyles.primaryMain,
                      width: 2.w,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: GlobalStyles.inputBorderColor.withValues(
                        alpha: 0.2,
                      ),
                      width: 1,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              SizedBox(height: GlobalStyles.paddingNormal),
              Text(
                'Re-enter your password',
                style: TextStyle(
                  fontSize: GlobalStyles.fontSizeBody2,
                  fontWeight: GlobalStyles.fontWeightSemiBold,
                  color: GlobalStyles.textPrimary,
                  fontFamily: GlobalStyles.fontFamilyHeading,
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(
                  fontSize: GlobalStyles.fontSizeBody2,
                  color: GlobalStyles.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(
                    color: GlobalStyles.textSecondary,
                    fontSize: GlobalStyles.fontSizeBody2,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.lock,
                    color: GlobalStyles.textTertiary,
                    size: GlobalStyles.iconSizeSm,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16.h,
                    horizontal: 14.w,
                  ),
                  filled: true,
                  fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: GlobalStyles.primaryMain,
                      width: 2.w,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: GlobalStyles.inputBorderColor.withValues(
                        alpha: 0.2,
                      ),
                      width: 1,
                    ),
                  ),
                  suffixIcon: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: GlobalStyles.textTertiary,
                        size: GlobalStyles.iconSizeSm,
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: GlobalStyles.paddingNormal),
              GestureDetector(
                onTap: () => setState(() => _acknowledged = !_acknowledged),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 24.w,
                      height: 24.w,
                      margin: EdgeInsets.only(top: 2.h, right: 12.w),
                      decoration: BoxDecoration(
                        color:
                            _acknowledged
                                ? GlobalStyles.errorMain
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color:
                              _acknowledged
                                  ? GlobalStyles.errorMain
                                  : GlobalStyles.inputBorderColor.withValues(
                                    alpha: 0.5,
                                  ),
                          width: 2,
                        ),
                      ),
                      child:
                          _acknowledged
                              ? Center(
                                child: Icon(
                                  LucideIcons.check,
                                  color: GlobalStyles.surfaceMain,
                                  size: 14.sp,
                                ),
                              )
                              : null,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          'I understand that deleting my account is permanent and cannot be undone.',
                          style: TextStyle(
                            fontSize: GlobalStyles.fontSizeBody2,
                            color: GlobalStyles.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalStyles.errorMain,
                    disabledBackgroundColor: GlobalStyles.errorMain.withValues(
                      alpha: 0.4,
                    ),
                    elevation: 2,
                    shadowColor: GlobalStyles.errorMain.withValues(alpha: 0.3),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      (!_acknowledged || _isProcessing)
                          ? null
                          : () async {
                            // Validate deletion request
                            final error = AccountUtils.validateAccountDeletion(
                              confirmText: _confirmController.text.trim(),
                              password: _passwordController.text,
                            );

                            if (error != null) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(error)));
                              return;
                            }

                            setState(() => _isProcessing = true);
                            try {
                              final auth = context.read<AuthProvider>();
                              final ok = await AccountUtils.deleteAccount(
                                context: context,
                                authProvider: auth,
                                password: _passwordController.text,
                              );
                              if (ok) {
                                if (!mounted) return;
                                AccountUtils.navigateToSignIn(context);
                              } else {
                                if (!mounted) return;
                                final msg =
                                    auth.error ?? 'Failed to delete account';
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(msg)));
                              }
                            } finally {
                              if (mounted)
                                setState(() => _isProcessing = false);
                            }
                          },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child:
                        _isProcessing
                            ? SizedBox(
                              key: const ValueKey('loading'),
                              height: 20.sp,
                              width: 20.sp,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Row(
                              key: const ValueKey('text'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.trash2,
                                  color: GlobalStyles.surfaceMain,
                                  size: GlobalStyles.iconSizeSm,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Delete my account',
                                  style: TextStyle(
                                    color: GlobalStyles.surfaceMain,
                                    fontSize: GlobalStyles.fontSizeBody1,
                                    fontWeight: GlobalStyles.fontWeightSemiBold,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: GlobalStyles.primaryMain,
                      fontSize: GlobalStyles.fontSizeBody2,
                      fontWeight: GlobalStyles.fontWeightSemiBold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
