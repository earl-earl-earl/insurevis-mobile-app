import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/auth_provider.dart';

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
          style: GoogleFonts.inter(
            color: const Color(0xFF2A2A2A),
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2A2A2A)),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(13), // subtle red tint
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 28.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This action is permanent',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2A2A2A),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Deleting your account will permanently remove your profile and related data. This cannot be undone.',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: const Color(0x992A2A2A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            Text(
              'Before you proceed',
              style: GoogleFonts.inter(
                color: GlobalStyles.primaryColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10.h),
            _InfoRow(text: 'Your login access will be revoked.'),
            _InfoRow(
              text: 'Stored documents and verifications may be deleted.',
            ),
            _InfoRow(text: 'Any pending processes may be canceled.'),

            SizedBox(height: 24.h),

            Text(
              'Type CONFIRM to proceed',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A2A2A),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                hintText: 'CONFIRM',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0x992A2A2A),
                  fontSize: 14.sp,
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
                    color: GlobalStyles.primaryColor,
                    width: 1.5.w,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.red[300]!, width: 1.5.w),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.red[300]!, width: 1.5.w),
                ),
              ),
            ),

            SizedBox(height: 16.h),
            Text(
              'Re-enter your password',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A2A2A),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0x992A2A2A),
                  fontSize: 14.sp,
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
                    color: GlobalStyles.primaryColor,
                    width: 1.5.w,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0x992A2A2A),
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.red[300]!, width: 1.5.w),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.red[300]!, width: 1.5.w),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acknowledged,
                  onChanged: (v) => setState(() => _acknowledged = v ?? false),
                  activeColor: GlobalStyles.primaryColor,
                ),
                Expanded(
                  child: Text(
                    'I understand that deleting my account is permanent and cannot be undone.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF2A2A2A),
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
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    (!_acknowledged || _isProcessing)
                        ? null
                        : () async {
                          final confirm = _confirmController.text.trim();
                          final password = _passwordController.text;
                          if (confirm.toUpperCase() != 'CONFIRM') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please type CONFIRM to proceed.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Password is required.')),
                            );
                            return;
                          }

                          setState(() => _isProcessing = true);
                          try {
                            // Use provider for deletion flow
                            final auth = context.read<AuthProvider>();
                            final ok = await auth.deleteAccount(
                              password: password,
                            );
                            if (ok) {
                              if (!mounted) return;
                              // Navigate to sign-in and clear stack
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/signin',
                                (route) => false,
                              );
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
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          'Delete my account',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
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
                  style: GoogleFonts.inter(
                    color: GlobalStyles.primaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
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

class _InfoRow extends StatelessWidget {
  final String text;
  const _InfoRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.circle,
              size: 6.sp,
              color: const Color(0x772A2A2A),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF2A2A2A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
