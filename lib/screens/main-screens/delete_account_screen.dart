import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/utils/account_utils.dart';
import 'package:insurevis/utils/profile_widget_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _acknowledged = false;
  bool _isProcessing = false;
  bool _obscurePassword = true;
  final _confirmController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _confirmController.dispose();
    _passwordController.dispose();
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
            fontSize: GlobalStyles.fontSizeH3,
            fontWeight: GlobalStyles.fontWeightSemiBold,
          ),
        ),
        backgroundColor: GlobalStyles.surfaceMain,
        iconTheme: IconThemeData(color: GlobalStyles.textPrimary),
      ),
      backgroundColor: GlobalStyles.surfaceMain,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileWidgetUtils.buildWarningContainer(
              title: 'This action is permanent',
              message:
                  'Deleting your account will permanently remove your profile and related data. This cannot be undone.',
            ),

            SizedBox(height: GlobalStyles.paddingNormal),

            Text(
              'Before you proceed',
              style: TextStyle(
                color: GlobalStyles.primaryMain,
                fontSize: GlobalStyles.fontSizeBody1,
                fontWeight: GlobalStyles.fontWeightBold,
              ),
            ),
            SizedBox(height: GlobalStyles.spacingMd),
            ProfileWidgetUtils.buildInfoRow(
              'Your login access will be revoked.',
            ),
            ProfileWidgetUtils.buildInfoRow(
              'Stored documents and verifications may be deleted.',
            ),
            ProfileWidgetUtils.buildInfoRow(
              'Any pending processes may be canceled.',
            ),

            SizedBox(height: GlobalStyles.paddingLoose),

            Text(
              'Type CONFIRM to proceed',
              style: TextStyle(
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightSemiBold,
                color: GlobalStyles.textPrimary,
              ),
            ),
            SizedBox(height: GlobalStyles.spacingSm),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                hintText: 'CONFIRM',
                hintStyle: TextStyle(
                  color: GlobalStyles.textSecondary,
                  fontSize: GlobalStyles.fontSizeBody2,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 18.h,
                  horizontal: 16.w,
                ),
                filled: true,
                fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: GlobalStyles.primaryMain,
                    width: 1.5.w,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: GlobalStyles.errorMain,
                    width: 1.5.w,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: GlobalStyles.errorMain,
                    width: 1.5.w,
                  ),
                ),
              ),
            ),

            SizedBox(height: GlobalStyles.paddingNormal),
            Text(
              'Re-enter your password',
              style: TextStyle(
                fontSize: GlobalStyles.fontSizeBody2,
                fontWeight: GlobalStyles.fontWeightSemiBold,
                color: GlobalStyles.textPrimary,
              ),
            ),
            SizedBox(height: GlobalStyles.spacingSm),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(
                  color: GlobalStyles.textSecondary,
                  fontSize: GlobalStyles.fontSizeBody2,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 18.h,
                  horizontal: 16.w,
                ),
                filled: true,
                fillColor: Colors.black12.withAlpha((0.04 * 255).toInt()),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: GlobalStyles.primaryMain,
                    width: 1.5.w,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: GlobalStyles.textSecondary,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: GlobalStyles.errorMain,
                    width: 1.5.w,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: GlobalStyles.errorMain,
                    width: 1.5.w,
                  ),
                ),
              ),
            ),
            SizedBox(height: GlobalStyles.paddingNormal),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acknowledged,
                  onChanged: (v) => setState(() => _acknowledged = v ?? false),
                  activeColor: GlobalStyles.primaryMain,
                ),
                Expanded(
                  child: Text(
                    'I understand that deleting my account is permanent and cannot be undone.',
                    style: TextStyle(
                      fontSize: GlobalStyles.fontSizeBody2,
                      color: GlobalStyles.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalStyles.errorMain,
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
                            if (mounted) setState(() => _isProcessing = false);
                          }
                        },
                child:
                    _isProcessing
                        ? SizedBox(
                          height: 20.sp,
                          width: 20.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              GlobalStyles.surfaceMain,
                            ),
                          ),
                        )
                        : Text(
                          'Delete my account',
                          style: TextStyle(
                            color: GlobalStyles.surfaceMain,
                            fontSize: GlobalStyles.fontSizeBody1,
                            fontWeight: GlobalStyles.fontWeightSemiBold,
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
    );
  }
}
