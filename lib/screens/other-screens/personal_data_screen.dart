import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/providers/auth_provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:insurevis/utils/personal_data_utils.dart';

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
          SizedBox(height: GlobalStyles.spacingSm),
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: GlobalStyles.inputPadding.horizontal,
                vertical: GlobalStyles.inputPadding.vertical,
              ),
              filled: true,
              fillColor: GlobalStyles.backgroundMain,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
                borderSide: BorderSide(
                  color: GlobalStyles.inputFocusBorderColor,
                  width: GlobalStyles.focusOutlineWidth,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
                borderSide: BorderSide(
                  color: GlobalStyles.inputBorderColor,
                  width: GlobalStyles.focusOutlineWidth,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
                borderSide: BorderSide(
                  color: GlobalStyles.errorMain,
                  width: GlobalStyles.focusOutlineWidth,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GlobalStyles.radiusLg),
                borderSide: BorderSide(
                  color: GlobalStyles.errorMain,
                  width: GlobalStyles.focusOutlineWidth,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: GlobalStyles.backgroundMain,
      appBar: AppBar(
        backgroundColor: GlobalStyles.surfaceMain,
        elevation: 0,
        shadowColor: GlobalStyles.shadowSm.color,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: GlobalStyles.textPrimary,
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
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(color: GlobalStyles.backgroundMain),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(GlobalStyles.paddingNormal),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height:
                        isKeyboardVisible
                            ? GlobalStyles.spacingMd
                            : GlobalStyles.spacingXl,
                  ),

                  Text(
                    'Edit your personal information',
                    style: TextStyle(
                      color: GlobalStyles.textPrimary,
                      fontSize: GlobalStyles.fontSizeH4,
                      fontWeight: GlobalStyles.fontWeightBold,
                      fontFamily: GlobalStyles.fontFamilyHeading,
                      letterSpacing: GlobalStyles.letterSpacingH4,
                    ),
                  ),
                  SizedBox(height: GlobalStyles.spacingMd),
                  Text(
                    'Update your profile details below.',
                    style: TextStyle(
                      fontSize: GlobalStyles.fontSizeBody2,
                      color: GlobalStyles.textTertiary,
                      fontFamily: GlobalStyles.fontFamilyBody,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(
                    height:
                        isKeyboardVisible
                            ? GlobalStyles.spacingMd
                            : GlobalStyles.spacingXl,
                  ),

                  _buildField(
                    label: 'Name',
                    controller: _nameCtrl,
                    validator: PersonalDataUtils.validateName,
                    hint: 'Enter your full name',
                    isRequired: true,
                  ),

                  SizedBox(height: GlobalStyles.spacingMd),

                  _buildField(
                    label: 'Email',
                    controller: _emailCtrl,
                    validator: PersonalDataUtils.validateEmail,
                    hint: 'Enter your email address',
                    isRequired: true,
                  ),

                  SizedBox(height: GlobalStyles.spacingMd),

                  _buildField(
                    label: 'Phone Number',
                    controller: _phoneCtrl,
                    validator: PersonalDataUtils.validatePhone,
                    hint: 'Optional',
                    isRequired: false,
                  ),

                  SizedBox(height: GlobalStyles.spacingXl),

                  auth.isLoading
                      ? Container(
                        height: 56.h,
                        decoration: BoxDecoration(
                          color: GlobalStyles.primaryMain.withOpacity(
                            GlobalStyles.hoverOpacity,
                          ),
                          borderRadius: BorderRadius.circular(
                            GlobalStyles.buttonBorderRadius,
                          ),
                          boxShadow: [GlobalStyles.buttonShadow],
                        ),
                        child: Center(
                          child: SizedBox(
                            width: GlobalStyles.iconSizeMd,
                            height: GlobalStyles.iconSizeMd,
                            child: CircularProgressIndicator(
                              color: GlobalStyles.surfaceMain,
                              strokeWidth: GlobalStyles.iconStrokeWidthNormal,
                            ),
                          ),
                        ),
                      )
                      : ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalStyles.primaryMain,
                          foregroundColor: GlobalStyles.surfaceMain,
                          padding: GlobalStyles.buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              GlobalStyles.buttonBorderRadius,
                            ),
                          ),
                          minimumSize: Size(double.infinity, 56.h),
                          elevation: 0,
                          shadowColor: GlobalStyles.buttonShadow.color,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.save,
                              size: GlobalStyles.iconSizeSm,
                            ),
                            SizedBox(width: GlobalStyles.spacingSm),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: GlobalStyles.fontSizeButton,
                                fontWeight: GlobalStyles.fontWeightMedium,
                                fontFamily: GlobalStyles.fontFamilyBody,
                                letterSpacing: GlobalStyles.letterSpacingButton,
                              ),
                            ),
                          ],
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
