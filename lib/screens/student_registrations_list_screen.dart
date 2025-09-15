import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/student_registration.dart';
import '../services/student_registration_service.dart';
import 'student_registration_details_screen.dart';

class StudentRegistrationsListScreen extends StatefulWidget {
  const StudentRegistrationsListScreen({super.key});

  @override
  State<StudentRegistrationsListScreen> createState() => _StudentRegistrationsListScreenState();
}

class _StudentRegistrationsListScreenState extends State<StudentRegistrationsListScreen> {
  final StudentRegistrationService _studentService = StudentRegistrationService();
  
  List<StudentRegistration> _registrations = [];
  bool _isLoading = true;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  
  // Filters
  String _selectedStatus = 'all';
  String _searchQuery = '';
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrations({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          _isLoading = true;
          _error = null;
          _currentPage = 1;
          _hasMoreData = true;
        });
      }

      final data = await _studentService.getAllStudentRegistrations(
        page: _currentPage,
        limit: 20,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      final newRegistrations = data.map((json) => StudentRegistration.fromJson(json)).toList();

      setState(() {
        if (refresh) {
          _registrations = newRegistrations;
        } else {
          _registrations.addAll(newRegistrations);
        }
        _isLoading = false;
        _isLoadingMore = false;
        _hasMoreData = newRegistrations.length == 20; // Assuming 20 is the page size
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreRegistrations() async {
    if (!_hasMoreData || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadRegistrations();
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadRegistrations(refresh: true);
  }

  void _onStatusChanged(String status) {
    _selectedStatus = status;
    _loadRegistrations(refresh: true);
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'under_review':
        return 'قيد الدراسة';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'under_review':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تسجيلات الطلاب',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.surface),
        actions: [
          IconButton(
            onPressed: () => _loadRegistrations(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'البحث بالاسم أو رقم الطالب...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.textTertiary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.textTertiary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 'all', _selectedStatus == 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('قيد المراجعة', 'pending', _selectedStatus == 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('مقبول', 'approved', _selectedStatus == 'approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('مرفوض', 'rejected', _selectedStatus == 'rejected'),
                      const SizedBox(width: 8),
                      _buildFilterChip('قيد الدراسة', 'under_review', _selectedStatus == 'under_review'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Registrations List
          Expanded(
            child: _isLoading
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
                              onPressed: () => _loadRegistrations(refresh: true),
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
                    : _registrations.isEmpty
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
                                  'لا توجد تسجيلات',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'لم يتم العثور على أي تسجيلات للطلاب',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadRegistrations(refresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _registrations.length + (_hasMoreData ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _registrations.length) {
                                  // Load more indicator
                                  if (_hasMoreData) {
                                    _loadMoreRegistrations();
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }

                                final registration = _registrations[index];
                                return _buildRegistrationCard(registration);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onStatusChanged(value),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: AppColors.surfaceVariant,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.textTertiary,
      ),
    );
  }

  Widget _buildRegistrationCard(StudentRegistration registration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentRegistrationDetailsScreen(
                  registrationId: registration.id!,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registration.fullName,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'رقم الطالب: ${registration.studentId}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(registration.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(registration.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusText(registration.status),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _getStatusColor(registration.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.school, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${registration.university} - ${registration.college}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      registration.phone,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (registration.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'تاريخ التسجيل: ${registration.createdAt!.toString().split(' ')[0]}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'اضغط لعرض التفاصيل',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
