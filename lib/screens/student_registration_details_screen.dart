import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
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
        return 'في الانتظار';
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return 'قيد المراجعة';
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        return 'تم القبول';
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        return 'تم الرفض';
      default:
        print('Warning: Unknown status in _getStatusText: $status, defaulting to في الانتظار');
        return 'في الانتظار';
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
      appBar: AppBar(
        title: Text(
          'تفاصيل التسجيل',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.surface),
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
                        'حدث خطأ',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRegistrationDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
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
                            'لم يتم العثور على التسجيل',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_registration!.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getStatusColor(_registration!.status).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getStatusIcon(_registration!.status),
                                  color: _getStatusColor(_registration!.status),
                                  size: 48,
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
                                    'تاريخ التسجيل: ${_registration!.createdAt!.toString().split(' ')[0]}',
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
                            title: 'المعلومات الشخصية',
                            icon: Icons.person,
                            children: [
                              _buildInfoRow('الاسم الكامل', _registration!.fullName),
                              _buildInfoRow('رقم الطالب', _registration!.studentId),
                              _buildInfoRow('رقم الهاتف', _registration!.phone),
                              if (_registration!.email != null)
                                _buildInfoRow('البريد الإلكتروني', _registration!.email!),
                              _buildInfoRow('الجنس', _registration!.gender),
                              _buildInfoRow('الحالة الاجتماعية', _registration!.maritalStatus),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Academic Information
                          _buildSection(
                            title: 'المعلومات الأكاديمية',
                            icon: Icons.school,
                            children: [
                              _buildInfoRow('الجامعة', _registration!.university),
                              _buildInfoRow('الكلية', _registration!.college),
                              _buildInfoRow('التخصص', _registration!.major),
                              _buildInfoRow('السنة الدراسية', _registration!.academicYear),
                              _buildInfoRow('المعدل التراكمي', _registration!.gpa.toString()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Financial Information
                          _buildSection(
                            title: 'المعلومات المالية',
                            icon: Icons.account_balance_wallet,
                            children: [
                              _buildInfoRow('مستوى الدخل', _registration!.incomeLevel),
                              _buildInfoRow('حجم الأسرة', _registration!.familySize),
                              if (_registration!.financialNeed != null)
                                _buildInfoRow('الاحتياج المالي', _registration!.financialNeed!),
                              if (_registration!.previousSupport != null)
                                _buildInfoRow('الدعم السابق', _registration!.previousSupport!),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Additional Information
                          if (_registration!.address != null ||
                              _registration!.emergencyContact != null ||
                              _registration!.emergencyPhone != null)
                            _buildSection(
                              title: 'معلومات إضافية',
                              icon: Icons.info,
                              children: [
                                if (_registration!.address != null)
                                  _buildInfoRow('العنوان', _registration!.address!),
                                if (_registration!.emergencyContact != null)
                                  _buildInfoRow('جهة اتصال للطوارئ', _registration!.emergencyContact!),
                                if (_registration!.emergencyPhone != null)
                                  _buildInfoRow('هاتف الطوارئ', _registration!.emergencyPhone!),
                              ],
                            ),

                          const SizedBox(height: 24),

                          // Action Buttons
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
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: Text('edit'.tr()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    foregroundColor: AppColors.surface,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Implement documents upload
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('feature_coming_soon'.tr()),
                                        backgroundColor: AppColors.info,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: Text('upload_documents'.tr()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.surface,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
