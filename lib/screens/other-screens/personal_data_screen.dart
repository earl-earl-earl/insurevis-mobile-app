import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/utils/personal_data_utils.dart';
import 'package:insurevis/utils/auth_widget_utils.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.lightImpact();

    final profileData = PersonalDataUtils.prepareProfileData(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
    );

    // Call provider to update
    final success = await auth.updateProfile(
      name: profileData['name'],
      email: profileData['email'],
      phone: profileData['phone'],
    );

    if (success) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSuccessSnackBar('Profile updated successfully');
        // Refresh provider profile
        await auth.refreshProfile();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } else {
      if (mounted) {
        HapticFeedback.mediumImpact();
        final message = auth.error ?? 'Failed to update profile';
        _showErrorSnackBar(message);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    AuthWidgetUtils.showSnackBar(context, message, isError: false);
  }

  void _showErrorSnackBar(String message) {
    AuthWidgetUtils.showSnackBar(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    Widget _buildField({
      required String label,
      required TextEditingController controller,
      String? Function(String?)? validator,
      String? hint,
      bool isRequired = false,
      IconData? icon,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: TextStyle(
                color: GlobalStyles.textSecondary,
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightSemiBold,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
              children:
                  isRequired
                      ? [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: GlobalStyles.errorMain),
                        ),
                      ]
                      : null,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: controller,
            validator: validator,
            style: TextStyle(
              fontSize: GlobalStyles.fontSizeBody2,
              color: GlobalStyles.textPrimary,
              fontFamily: GlobalStyles.fontFamilyBody,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: GlobalStyles.textDisabled,
                fontSize: GlobalStyles.fontSizeBody2,
                fontFamily: GlobalStyles.fontFamilyBody,
              ),
              prefixIcon:
                  icon != null
                      ? Icon(icon, color: GlobalStyles.primaryMain, size: 20.sp)
                      : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              filled: true,
              fillColor: GlobalStyles.surfaceMain,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.primaryMain,
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.textDisabled.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.errorMain,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: GlobalStyles.errorMain,
                  width: 2.0,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: GlobalStyles.textSecondary,
            size: GlobalStyles.iconSizeMd,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Personal Information',
          style: TextStyle(
            color: GlobalStyles.textPrimary,
            fontSize: GlobalStyles.fontSizeH5,
            fontWeight: GlobalStyles.fontWeightSemiBold,
            fontFamily: GlobalStyles.fontFamilyHeading,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(color: GlobalStyles.surfaceMain),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: isKeyboardVisible ? 16.h : 32.h),

                    // Animated header with icon
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
                          gradient: LinearGradient(
                            colors: [
                              GlobalStyles.primaryMain.withValues(alpha: 0.08),
                              GlobalStyles.primaryMain.withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.radiusMd,
                          ),
                          border: Border.all(
                            color: GlobalStyles.primaryMain.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: GlobalStyles.primaryMain.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  GlobalStyles.radiusSm,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.user,
                                color: GlobalStyles.primaryMain,
                                size: GlobalStyles.iconSizeMd,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Your Profile',
                                    style: TextStyle(
                                      fontSize: GlobalStyles.fontSizeBody1,
                                      fontWeight:
                                          GlobalStyles.fontWeightSemiBold,
                                      fontFamily:
                                          GlobalStyles.fontFamilyHeading,
                                      color: GlobalStyles.textPrimary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Update your personal information below',
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

                    SizedBox(height: isKeyboardVisible ? 24.h : 48.h),

                    // Animated name field
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
                      child: _buildField(
                        label: 'Name',
                        controller: _nameCtrl,
                        validator: PersonalDataUtils.validateName,
                        hint: 'Enter your full name',
                        isRequired: true,
                        icon: LucideIcons.user,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Animated email field
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: _buildField(
                        label: 'Email',
                        controller: _emailCtrl,
                        validator: PersonalDataUtils.validateEmail,
                        hint: 'Enter your email address',
                        isRequired: true,
                        icon: LucideIcons.mail,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Animated phone field
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: _buildField(
                        label: 'Phone Number',
                        controller: _phoneCtrl,
                        validator: PersonalDataUtils.validatePhone,
                        hint: 'Optional',
                        isRequired: false,
                        icon: LucideIcons.phone,
                      ),
                    ),

                    SizedBox(height: 48.h),

                    // Animated save button
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child:
                          auth.isLoading
                              ? AuthWidgetUtils.buildLoadingButton()
                              : AuthWidgetUtils.buildPrimaryButton(
                                onPressed: _save,
                                text: 'Save Changes',
                              ),
                    ),

                    SizedBox(height: isKeyboardVisible ? 16.h : 32.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
