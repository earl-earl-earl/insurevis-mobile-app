import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:insurevis/global_ui_variables.dart';
import 'package:insurevis/providers/notification_provider.dart';
import 'package:file_picker/file_picker.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  String _selectedInsuranceCompany = 'Select Insurance Company';
  final List<String> _insuranceCompanies = [
    'Select Insurance Company',
    'AIG Philippines',
    'Allianz PNB Life',
    'Chubb Insurance',
    'FPG Insurance',
    'Generali Philippines',
    'Great Pacific Life',
    'Insular Life',
    'Malayan Insurance',
    'Philam Insurance',
    'Philippine AXA Life',
    'Pioneer Insurance',
    'Prudentialife Plans',
    'Standard Insurance',
    'Sun Life Philippines',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // Header
                  Text(
                    'Submit Documents',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    'Upload required documents for your insurance claim',
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),

                  SizedBox(height: 30.h),

                  // Insurance Company Selection
                  _buildInsuranceCompanyDropdown(),

                  SizedBox(height: 30.h),

                  // Document Types Section
                  _buildDocumentTypesSection(),

                  SizedBox(height: 30.h),

                  // Selected Files Section
                  if (_selectedFiles.isNotEmpty) _buildSelectedFilesSection(),

                  SizedBox(height: 30.h),

                  // Upload Button
                  _buildUploadButton(),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsuranceCompanyDropdown() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26), // 0.1 * 255
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedInsuranceCompany,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          iconSize: 24.sp,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          dropdownColor: Color(0xFF292832),
          onChanged: (String? newValue) {
            setState(() {
              _selectedInsuranceCompany = newValue!;
            });
          },
          items:
              _insuranceCompanies.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      color:
                          value == 'Select Insurance Company'
                              ? Colors.white54
                              : Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildDocumentTypesSection() {
    final documentTypes = [
      {
        'title': 'Damage Assessment Report',
        'description': 'Upload your vehicle damage assessment report',
        'icon': Icons.assessment_outlined,
        'required': true,
      },
      {
        'title': 'Vehicle Registration',
        'description': 'Official vehicle registration certificate',
        'icon': Icons.directions_car_outlined,
        'required': true,
      },
      {
        'title': 'Driver\'s License',
        'description': 'Valid driver\'s license copy',
        'icon': Icons.credit_card_outlined,
        'required': true,
      },
      {
        'title': 'Insurance Policy',
        'description': 'Your current insurance policy document',
        'icon': Icons.policy_outlined,
        'required': true,
      },
      {
        'title': 'Incident Report',
        'description': 'Police report or incident documentation',
        'icon': Icons.report_outlined,
        'required': false,
      },
      {
        'title': 'Photos/Videos',
        'description': 'Additional photos or videos of the damage',
        'icon': Icons.photo_library_outlined,
        'required': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Documents',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 16.h),

        ...documentTypes.map(
          (doc) => _buildDocumentTypeCard(
            title: doc['title'] as String,
            description: doc['description'] as String,
            icon: doc['icon'] as IconData,
            required: doc['required'] as bool,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required bool required,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13), // 0.05 * 255
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: GlobalStyles.primaryColor.withAlpha(51), // 0.2 * 255
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: GlobalStyles.primaryColor, size: 20.sp),
          ),

          SizedBox(width: 16.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (required) ...[
                      SizedBox(width: 4.w),
                      Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 4.h),

                Text(
                  description,
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () => _pickFiles(),
            icon: Icon(
              Icons.upload_file_outlined,
              color: GlobalStyles.primaryColor,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Files (${_selectedFiles.length})',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  _selectedFiles.clear();
                });
              },
              child: Text(
                'Clear All',
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        ...List.generate(_selectedFiles.length, (index) {
          final file = _selectedFiles[index];
          return _buildFileItem(file, index);
        }),
      ],
    );
  }

  Widget _buildFileItem(PlatformFile file, int index) {
    final fileSize = _formatFileSize(file.size);
    final fileExtension = file.extension?.toUpperCase() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26), // 0.1 * 255
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: _getFileTypeColor(fileExtension),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileTypeIcon(fileExtension),
              color: Colors.white,
              size: 16.sp,
            ),
          ),

          SizedBox(width: 12.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                Text(
                  '$fileExtension • $fileSize',
                  style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _selectedFiles.removeAt(index);
              });
            },
            icon: Icon(Icons.close, color: Colors.white54, size: 18.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    final bool canSubmit =
        _selectedFiles.isNotEmpty &&
        _selectedInsuranceCompany != 'Select Insurance Company';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit && !_isUploading ? _submitDocuments : null,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            canSubmit ? GlobalStyles.primaryColor : Colors.grey.shade600,
          ),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16.h)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        child:
            _isUploading
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Submitting...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : Text(
                  'Submit to Insurance Company',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitDocuments() async {
    if (_selectedFiles.isEmpty ||
        _selectedInsuranceCompany == 'Select Insurance Company') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select files and insurance company'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Documents submitted successfully to $_selectedInsuranceCompany!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Trigger notification
      if (mounted) {
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        notificationProvider.addDocumentSubmitted(_selectedInsuranceCompany);
      }

      // Clear form after successful submission
      setState(() {
        _selectedFiles.clear();
        _selectedInsuranceCompany = 'Select Insurance Company';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      case 'txt':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}
