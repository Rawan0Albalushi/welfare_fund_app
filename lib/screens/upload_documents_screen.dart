import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/student_registration_service.dart';

class UploadDocumentsScreen extends StatefulWidget {
  final String registrationId;

  const UploadDocumentsScreen({
    super.key,
    required this.registrationId,
  });

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final StudentRegistrationService _studentService = StudentRegistrationService();
  final ImagePicker _picker = ImagePicker();

  // Document paths and bytes
  String? _idCardImagePath;
  Uint8List? _idCardImageBytes;
  String? _transcriptPath;
  Uint8List? _transcriptBytes;
  String? _incomeCertificatePath;
  Uint8List? _incomeCertificateBytes;
  String? _familyCardPath;
  Uint8List? _familyCardBytes;
  String? _otherDocumentsPath;
  Uint8List? _otherDocumentsBytes;

  bool _isUploading = false;

  Future<void> _pickDocument({
    required String documentType,
    required Function(String, Uint8List?) onPicked,
  }) async {
    try {
      // Show options dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('اختر مصدر $documentType'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('التقاط صورة من الكاميرا'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickDocumentFromCamera(documentType, onPicked);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('اختيار من المعرض'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickDocumentFromGallery(documentType, onPicked);
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء اختيار $documentType'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickDocumentFromCamera(String documentType, Function(String, Uint8List?) onPicked) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        onPicked(image.path, bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم التقاط $documentType بنجاح'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التقاط $documentType'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickDocumentFromGallery(String documentType, Function(String, Uint8List?) onPicked) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        onPicked(image.path, bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم اختيار $documentType بنجاح'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء اختيار $documentType'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _uploadDocuments() async {
    if (_idCardImagePath == null &&
        _transcriptPath == null &&
        _incomeCertificatePath == null &&
        _familyCardPath == null &&
        _otherDocumentsPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار مستند واحد على الأقل'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _studentService.uploadStudentDocuments(
        registrationId: widget.registrationId,
        idCardImagePath: _idCardImagePath,
        idCardImageBytes: _idCardImageBytes,
        transcriptPath: _transcriptPath,
        transcriptBytes: _transcriptBytes,
        incomeCertificatePath: _incomeCertificatePath,
        incomeCertificateBytes: _incomeCertificateBytes,
        familyCardPath: _familyCardPath,
        familyCardBytes: _familyCardBytes,
        otherDocumentsPath: _otherDocumentsPath,
        otherDocumentsBytes: _otherDocumentsBytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع المستندات بنجاح'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء رفع المستندات: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildDocumentCard({
    required String title,
    required String description,
    required IconData icon,
    required String? documentPath,
    required Uint8List? documentBytes,
    required Function(String, Uint8List?) onPicked,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: documentPath != null 
              ? AppColors.success.withOpacity(0.3)
              : AppColors.textTertiary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: documentPath != null 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: documentPath != null 
                      ? AppColors.success
                      : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (documentPath != null)
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (documentBytes != null) ...[
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.textTertiary),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  documentBytes,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickDocument(
                    documentType: title,
                    onPicked: (path, bytes) {
                      setState(() {
                        onPicked(path, bytes);
                      });
                    },
                  ),
                  icon: Icon(documentPath != null ? Icons.edit : Icons.upload),
                  label: Text(documentPath != null ? 'تغيير' : 'رفع'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: documentPath != null 
                        ? AppColors.info
                        : AppColors.primary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (documentPath != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      onPicked('', null);
                    });
                  },
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withOpacity(0.1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'رفع المستندات',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.surface),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: AppColors.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'رفع المستندات المطلوبة',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى رفع المستندات المطلوبة لدعم طلبك',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Documents
                _buildDocumentCard(
                  title: 'صورة البطاقة الشخصية',
                  description: 'صورة واضحة من البطاقة الشخصية',
                  icon: Icons.credit_card,
                  documentPath: _idCardImagePath,
                  documentBytes: _idCardImageBytes,
                  onPicked: (path, bytes) {
                    _idCardImagePath = path.isNotEmpty ? path : null;
                    _idCardImageBytes = bytes;
                  },
                ),
                const SizedBox(height: 16),

                _buildDocumentCard(
                  title: 'كشف الدرجات',
                  description: 'كشف الدرجات الأكاديمي الحالي',
                  icon: Icons.school,
                  documentPath: _transcriptPath,
                  documentBytes: _transcriptBytes,
                  onPicked: (path, bytes) {
                    _transcriptPath = path.isNotEmpty ? path : null;
                    _transcriptBytes = bytes;
                  },
                ),
                const SizedBox(height: 16),

                _buildDocumentCard(
                  title: 'شهادة الدخل',
                  description: 'شهادة الدخل للأسرة',
                  icon: Icons.account_balance_wallet,
                  documentPath: _incomeCertificatePath,
                  documentBytes: _incomeCertificateBytes,
                  onPicked: (path, bytes) {
                    _incomeCertificatePath = path.isNotEmpty ? path : null;
                    _incomeCertificateBytes = bytes;
                  },
                ),
                const SizedBox(height: 16),

                _buildDocumentCard(
                  title: 'بطاقة العائلة',
                  description: 'صورة من بطاقة العائلة',
                  icon: Icons.family_restroom,
                  documentPath: _familyCardPath,
                  documentBytes: _familyCardBytes,
                  onPicked: (path, bytes) {
                    _familyCardPath = path.isNotEmpty ? path : null;
                    _familyCardBytes = bytes;
                  },
                ),
                const SizedBox(height: 16),

                _buildDocumentCard(
                  title: 'مستندات أخرى',
                  description: 'أي مستندات إضافية تدعم طلبك',
                  icon: Icons.description,
                  documentPath: _otherDocumentsPath,
                  documentBytes: _otherDocumentsBytes,
                  onPicked: (path, bytes) {
                    _otherDocumentsPath = path.isNotEmpty ? path : null;
                    _otherDocumentsBytes = bytes;
                  },
                ),
                const SizedBox(height: 32),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadDocuments,
                    icon: _isUploading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploading ? 'جاري الرفع...' : 'رفع المستندات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
