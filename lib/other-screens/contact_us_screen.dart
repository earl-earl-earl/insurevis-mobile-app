import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insurevis/global_ui_variables.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General Inquiry';

  final List<String> _categories = [
    'General Inquiry',
    'Technical Support',
    'Billing Question',
    'Feature Request',
    'Bug Report',
    'Insurance Claim Help',
    'Account Issues',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contact Us',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GlobalStyles.backgroundColorStart,
              GlobalStyles.backgroundColorEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Information Cards
                _buildContactCard(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'support@insurevis.com',
                  description: 'Get help via email',
                  onTap: () {
                    // Open email app
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening email app...')),
                    );
                  },
                ),

                _buildContactCard(
                  icon: Icons.phone_outlined,
                  title: 'Phone Support',
                  subtitle: '+63 (2) 123-4567',
                  description: 'Mon-Fri 9AM-6PM',
                  onTap: () {
                    // Open phone dialer
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening phone dialer...')),
                    );
                  },
                ),

                _buildContactCard(
                  icon: Icons.chat_outlined,
                  title: 'Live Chat',
                  subtitle: 'Chat with support',
                  description: 'Available 24/7',
                  onTap: () {
                    // Open live chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live chat coming soon!')),
                    );
                  },
                ),

                SizedBox(height: 30.h),

                // Contact Form
                Text(
                  'Send us a message',
                  style: TextStyle(
                    color: GlobalStyles.primaryColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 20.h),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name Field
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Category Dropdown
                      _buildCategoryDropdown(),

                      SizedBox(height: 16.h),

                      // Subject Field
                      _buildTextField(
                        controller: _subjectController,
                        label: 'Subject',
                        icon: Icons.subject_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Message Field
                      _buildTextField(
                        controller: _messageController,
                        label: 'Message',
                        icon: Icons.message_outlined,
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your message';
                          }
                          if (value.length < 10) {
                            return 'Message must be at least 10 characters';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 30.h),

                      // Send Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalStyles.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Send Message',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                // FAQ Section
                _buildFAQSection(),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: GlobalStyles.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: GlobalStyles.primaryColor, size: 24.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: GlobalStyles.primaryColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              description,
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.white54, size: 20.sp),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: GlobalStyles.primaryColor),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GlobalStyles.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: GlobalStyles.primaryColor,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
      ),
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
      items:
          _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: GlobalStyles.primaryColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 15.h),

        _buildFAQItem(
          'How accurate are the damage assessments?',
          'Our AI provides estimates with 85-90% accuracy. For final claims, we recommend professional inspection.',
        ),

        _buildFAQItem(
          'How long does processing take?',
          'Most damage assessments are completed within 30 seconds to 2 minutes.',
        ),

        _buildFAQItem(
          'Can I use this for insurance claims?',
          'Yes, our reports are accepted by major insurance companies as preliminary assessments.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            answer,
            style: TextStyle(color: Colors.white70, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_formKey.currentState!.validate()) {
      // Simulate sending message
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Message Sent',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Thank you for contacting us! We\'ll get back to you within 24 hours.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _clearForm();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();
    setState(() {
      _selectedCategory = 'General Inquiry';
    });
  }
}
