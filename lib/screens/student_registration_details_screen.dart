import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_config.dart';
import '../models/student_registration.dart';
import '../services/student_registration_service.dart';

class StudentRegistrationDetailsScreen extends StatefulWidget {
  final String registrationId;

  const StudentRegistrationDetailsScreen({
    super.key,
    required this.registrationId,
  });

  @override
  State<StudentRegistrationDetailsScreen> createState() => _StudentRegistrationDetailsScreenState();
}

class _StudentRegistrationDetailsScreenState extends State<StudentRegistrationDetailsScreen> {
  final StudentRegistrationService _studentService = StudentRegistrationService();
  StudentRegistration? _registration;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRegistrationDetails();
  }

  Future<void> _loadRegistrationDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _studentService.getStudentRegistrationById(widget.registrationId);
      final registration = StudentRegistration.fromJson(data);

      setState(() {
        _registration = registration;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String status) {
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        return 'pending'.tr();
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return 'under_review'.tr();
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        return 'application_approved'.tr();
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        return 'application_rejected'.tr();
      default:
        print('Warning: Unknown status in _getStatusText: $status, defaulting to pending');
        return 'pending'.tr();
    }
  }

  Color _getStatusColor(String status) {
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        return AppColors.warning;
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return AppColors.info;
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        return AppColors.success;
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        return AppColors.error;
      default:
        print('Warning: Unknown status in _getStatusColor: $status, defaulting to warning color');
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        return Icons.schedule;
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return Icons.info;
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        return Icons.check_circle;
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        return Icons.cancel;
      default:
        print('Warning: Unknown status in _getStatusIcon: $status, defaulting to schedule icon');
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.surface),
        title: Text(
          'application_details'.tr(),
          style: AppTextStyles.appBarTitleDark,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.modernGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'error'.tr(),
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadRegistrationDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('retry'.tr()),
                      ),
                    ],
                  ),
                )
              : _registration == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_off,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'registration_not_found'.tr(),
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_registration!.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(_registration!.status).withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getStatusIcon(_registration!.status),
                                  color: _getStatusColor(_registration!.status),
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _getStatusText(_registration!.status),
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: _getStatusColor(_registration!.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_registration!.createdAt != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${'registration_date'.tr()}: ${_registration!.createdAt!.toString().split(' ')[0]}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Personal Information
                          _buildSection(
                            title: 'personal_information'.tr(),
                            icon: Icons.person_outline,
                            color: AppColors.primary,
                            children: [
                              _buildInfoRow('full_name'.tr(), _registration!.fullName),
                              _buildInfoRow('student_id'.tr(), _registration!.studentId),
                              _buildInfoRow('phone_number'.tr(), _registration!.phone),
                              if (_registration!.email != null)
                                _buildInfoRow('email'.tr(), _registration!.email!),
                              _buildInfoRow('gender'.tr(), _registration!.gender),
                              _buildInfoRow('marital_status'.tr(), _registration!.maritalStatus),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Academic Information
                          _buildSection(
                            title: 'academic_information'.tr(),
                            icon: Icons.school_outlined,
                            color: AppColors.secondary,
                            children: [
                              _buildInfoRow('university'.tr(), _registration!.university),
                              _buildInfoRow('college'.tr(), _registration!.college),
                              _buildInfoRow('major'.tr(), _registration!.major),
                              _buildInfoRow('academic_year'.tr(), _registration!.academicYear),
                              _buildInfoRow('gpa'.tr(), _registration!.gpa.toString()),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Financial Information
                          _buildSection(
                            title: 'financial_information'.tr(),
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.accent,
                            children: [
                              _buildInfoRow('income_level'.tr(), _registration!.incomeLevel),
                              _buildInfoRow('family_size'.tr(), _registration!.familySize),
                              if (_registration!.financialNeed != null)
                                _buildInfoRow('financial_need'.tr(), _registration!.financialNeed!),
                              if (_registration!.previousSupport != null)
                                _buildInfoRow('previous_support'.tr(), _registration!.previousSupport!),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ID Card Image Section
                          if (_registration!.idCardImagePath != null) ...[
                            _buildSection(
                              title: 'id_photo'.tr(),
                              icon: Icons.credit_card,
                              color: AppColors.info,
                              children: [
                                _buildIdCardImage(_registration!.idCardImagePath!),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Additional Information
                          if (_registration!.address != null ||
                              _registration!.emergencyContact != null ||
                              _registration!.emergencyPhone != null) ...[
                            _buildSection(
                              title: 'additional_information'.tr(),
                              icon: Icons.info_outlined,
                              color: AppColors.info,
                              children: [
                                if (_registration!.address != null)
                                  _buildInfoRow('address'.tr(), _registration!.address!),
                                if (_registration!.emergencyContact != null)
                                  _buildInfoRow('emergency_contact'.tr(), _registration!.emergencyContact!),
                                if (_registration!.emergencyPhone != null)
                                  _buildInfoRow('emergency_phone'.tr(), _registration!.emergencyPhone!),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          const SizedBox(height: 16),

                          // Action Buttons (only show if status allows editing)
                          if (_registration!.status == 'pending' || _registration!.status == 'rejected') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Implement edit functionality
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('feature_coming_soon'.tr()),
                                          backgroundColor: AppColors.info,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: Text('edit'.tr()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.info,
                                      foregroundColor: AppColors.surface,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Implement documents upload
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('feature_coming_soon'.tr()),
                                          backgroundColor: AppColors.info,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.upload_file, size: 18),
                                    label: Text('upload_documents'.tr()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.surface,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    final sectionColor = color ?? AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: sectionColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: sectionColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, return it
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // Otherwise, construct the full URL
    String baseUrl = AppConfig.serverBaseUrl;
    String cleanPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$baseUrl$cleanPath';
  }

  Widget _buildIdCardImage(String imagePath) {
    final imageUrl = _getImageUrl(imagePath);
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 300,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  // Show full screen image
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          Center(
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                color: Colors.black87,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.black87,
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                shape: const CircleBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: AppColors.surfaceVariant,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'error_loading_image'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
                height: 200,
                color: AppColors.surfaceVariant,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'image_not_available'.tr(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
