import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:insurevis/global_ui_variables.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
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
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    // Call provider to update
    final success = await auth.updateProfile(
      name: name.isEmpty ? null : name,
      email: email.isEmpty ? null : email,
      phone: phone.isEmpty ? null : phone,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      // Refresh provider profile
      await auth.refreshProfile();
      Navigator.pop(context);
    } else {
      final message = auth.error ?? 'Failed to update profile';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
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
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: GoogleFonts.inter(
                color: const Color(0x992A2A2A),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              children:
                  isRequired
                      ? [
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ]
                      : null,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: controller,
            validator: validator,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF2A2A2A),
            ),
            decoration: InputDecoration(
              hintText: hint,
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
        ],
      );
    }

    return Scaffold(
      appBar: GlobalStyles.buildCustomAppBar(
        context: context,
        icon: Icons.arrow_back_rounded,
        color: const Color(0xFF2A2A2A),
        appBarBackgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: Colors.white),
          child: Padding(
            padding: GlobalStyles.defaultPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isKeyboardVisible ? 20.h : 40.h),

                  Text(
                    'Edit your personal information',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF2A2A2A),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Update your profile details below.',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0x992A2A2A),
                    ),
                  ),

                  SizedBox(height: isKeyboardVisible ? 20.h : 40.h),

                  _buildField(
                    label: 'Name',
                    controller: _nameCtrl,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : SupabaseService.validateName(v.trim()),
                    hint: 'Enter your full name',
                    isRequired: true,
                  ),

                  SizedBox(height: 20.h),

                  _buildField(
                    label: 'Email',
                    controller: _emailCtrl,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Email is required'
                                : SupabaseService.validateEmail(v.trim()),
                    hint: 'Enter your email address',
                    isRequired: true,
                  ),

                  SizedBox(height: 20.h),

                  _buildField(
                    label: 'Phone Number',
                    controller: _phoneCtrl,
                    validator: (v) => SupabaseService.validatePhone(v),
                    hint: 'Optional',
                    isRequired: false,
                  ),

                  SizedBox(height: 32.h),

                  auth.isLoading
                      ? Container(
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: GlobalStyles.primaryColor.withAlpha(180),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                      : ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalStyles.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 18.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          minimumSize: Size(double.infinity, 60.h),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
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
