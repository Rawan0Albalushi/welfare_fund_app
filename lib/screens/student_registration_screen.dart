import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/student_registration_service.dart';


class StudentRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final bool isReadOnly;

  const StudentRegistrationScreen({
    super.key,
    this.existingData,
    this.isReadOnly = false,
  });

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController();
  final _collegeController = TextEditingController();
  final _majorController = TextEditingController();
  final _programController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _gpaController = TextEditingController();

  // Programs data
  List<Map<String, dynamic>> _programs = [];
  String? _selectedProgramId;
  bool _isLoadingPrograms = false;

  // Form Values
  String _selectedGender = 'ذكر';
  final String _selectedMaritalStatus = 'أعزب';
  String _selectedIncomeLevel = 'منخفض';
  String _selectedFamilySize = '1-3';
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  
  // Application Status
  String _applicationStatus = 'pending'; // pending, under_review, approved, rejected
  String? _rejectionReason; // سبب الرفض
  
  // Services
  final AuthService _authService = AuthService();
  final StudentRegistrationService _studentService = StudentRegistrationService();




  // Academic Year Options
  final List<String> _academicYears = [
    'السنة الأولى',
    'السنة الثانية',
    'السنة الثالثة',
    'السنة الرابعة',
    'السنة الخامسة',
    'السنة السادسة',
  ];

  // Income Level Options
  final List<String> _incomeLevels = [
    'منخفض',
    'متوسط',
    'مرتفع',
  ];

  // Family Size Options
  final List<String> _familySizes = [
    '1-3',
    '4-6',
    '7-9',
    '10+',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Load existing data if provided
    if (widget.existingData != null) {
      _loadExistingData();
    }
    
    // فحص المصادقة بعد تهيئة جميع العناصر
    _initializeScreen();
    
    // Load programs from API
    _loadPrograms().then((_) {
      print('Programs loaded: ${_programs.length} programs');
      if (_programs.isNotEmpty) {
        print('Available programs: ${_programs.map((p) => '${p['id']}: ${p['name']}').join(', ')}');
      }
    }).catchError((error) {
      print('Error loading programs: $error');
    });
  }

  void _loadExistingData() {
    final data = widget.existingData!;
    
    // Debug: Print data being loaded
    print('=== Loading Existing Data Debug ===');
    print('Data: $data');
    print('Status: ${data['status']}');
    print('Rejection reason: ${data['rejection_reason']}');
    print('===================================');
    
    // Load application status
    _applicationStatus = data['status'] ?? 'pending';
    _rejectionReason = data['rejection_reason']; // Load rejection reason
    
    // Debug: Print final loaded status
    print('Final loaded status: $_applicationStatus');
    print('Is read-only: $_isReadOnly');
    print('Is rejected: $_isRejected');
    
    // Load personal data
    _fullNameController.text = data['personal']?['full_name'] ?? '';
    _studentIdController.text = data['personal']?['student_id'] ?? '';
    _emailController.text = data['personal']?['email'] ?? '';
    _phoneController.text = data['personal']?['phone'] ?? '';
    
    // Load academic data
    _universityController.text = data['academic']?['university'] ?? '';
    _collegeController.text = data['academic']?['college'] ?? '';
    _majorController.text = data['academic']?['major'] ?? '';
    _programController.text = data['academic']?['program'] ?? '';
    _selectedProgramId = data['program_id']?.toString();
    _academicYearController.text = _convertAcademicYearToString(data['academic']?['academic_year'] ?? 1);
    _gpaController.text = (data['academic']?['gpa'] ?? 0.0).toString();
    
    // Load programs first if not already loaded
    if (_programs.isEmpty) {
      _loadPrograms();
    }
    
    // Load financial data
    _selectedIncomeLevel = _convertIncomeLevelToArabic(data['financial']?['income_level'] ?? 'low');
    _selectedFamilySize = _convertFamilySizeToString(data['financial']?['family_size'] ?? 3);
    
    // Load gender
    _selectedGender = data['personal']?['gender'] == 'male' ? 'ذكر' : 'أنثى';
  }

  String _convertAcademicYearToString(dynamic year) {
    final yearNum = year is int ? year : int.tryParse(year.toString()) ?? 1;
    switch (yearNum) {
      case 1: return 'السنة الأولى';
      case 2: return 'السنة الثانية';
      case 3: return 'السنة الثالثة';
      case 4: return 'السنة الرابعة';
      case 5: return 'السنة الخامسة';
      case 6: return 'السنة السادسة';
      default: return 'السنة الأولى';
    }
  }

  String _convertIncomeLevelToArabic(String level) {
    switch (level.toLowerCase()) {
      case 'low': return 'منخفض';
      case 'medium': return 'متوسط';
      case 'high': return 'مرتفع';
      default: return 'منخفض';
    }
  }

  String _convertFamilySizeToString(dynamic size) {
    final sizeNum = size is int ? size : int.tryParse(size.toString()) ?? 3;
    if (sizeNum <= 3) return '1-3';
    if (sizeNum <= 6) return '4-6';
    if (sizeNum <= 9) return '7-9';
    return '10+';
  }

  // Check if the form should be read-only
  // Returns true for: under_review, approved, accepted
  // Returns false for: pending, rejected (allows editing)
  bool get _isReadOnly {
    return widget.isReadOnly || 
           _applicationStatus.toLowerCase() == 'under_review' || 
           _applicationStatus.toLowerCase() == 'approved' ||
           _applicationStatus.toLowerCase() == 'accepted';
    // Note: rejected status allows editing for re-submission
  }

  // Check if the form should show rejection status
  bool get _isRejected {
    return _applicationStatus.toLowerCase() == 'rejected';
  }

  // Get status text in Arabic
  String _getStatusText(String status) {
    // Debug: Print status text decision
    print('=== Status Text Debug ===');
    print('Status: $status');
    
    switch (status.toLowerCase()) {
      case 'pending':
        print('Status text: في الانتظار');
        return 'في الانتظار';
      case 'under_review':
        print('Status text: قيد المراجعة');
        return 'قيد المراجعة';
      case 'approved':
      case 'accepted':
        print('Status text: تم القبول');
        return 'تم القبول';
      case 'rejected':
        print('Status text: تم الرفض');
        return 'تم الرفض';
      default:
        print('Status text: في الانتظار (default)');
        return 'في الانتظار';
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'under_review':
        return AppColors.info;
      case 'approved':
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  // Build status indicator widget
  Widget _buildStatusIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(_applicationStatus).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(_applicationStatus).withOpacity(0.1),
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
                  color: _getStatusColor(_applicationStatus),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(_applicationStatus),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حالة الطلب',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getStatusText(_applicationStatus),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: _getStatusColor(_applicationStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isReadOnly) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.textTertiary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getStatusDescription(_applicationStatus),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _refreshApplicationStatus,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('تحديث حالة الطلب'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isRejected && _rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'سبب الرفض:',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rejectionReason!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ],
      ),
    );
  }

  // Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'under_review':
        return Icons.hourglass_empty;
      case 'approved':
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  // Get status description
  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'طلبك في قائمة الانتظار. سيتم مراجعته قريباً من قبل اللجنة المختصة.';
      case 'under_review':
        return 'طلبك قيد المراجعة من قبل اللجنة المختصة. لا يمكن تعديل البيانات في هذه المرحلة.';
      case 'approved':
      case 'accepted':
        return 'مبروك! تم قبول طلبك. سيتم التواصل معك قريباً لتأكيد التفاصيل.';
      case 'rejected':
        return 'للأسف تم رفض طلبك. اضغط على زر إعادة التسجيل لتعديل البيانات وإعادة التقديم.';
      default:
        return 'طلبك في قائمة الانتظار. سيتم مراجعته قريباً.';
    }
  }

  // Allow editing for rejected applications
  void _allowEditing() {
    setState(() {
      _applicationStatus = 'pending'; // Reset to pending to allow editing
      _rejectionReason = null; // Clear rejection reason
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تفعيل التعديل. يمكنك الآن تعديل البيانات وإعادة التسجيل',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressAnimationController.dispose();
    _fullNameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _collegeController.dispose();
    _majorController.dispose();
    _programController.dispose();
    _academicYearController.dispose();
    _gpaController.dispose();

    super.dispose();
  }

  Future<void> _initializeScreen() async {
    print('Initializing screen, starting animations...');
    _startAnimations();
  }

  void _startAnimations() {
    _animationController.forward();
    _progressAnimationController.forward();
  }

  // Load programs from API
  Future<void> _loadPrograms() async {
    setState(() {
      _isLoadingPrograms = true;
    });

    try {
      final programs = await _studentService.getSupportPrograms();
      
      print('Raw programs received: $programs');
      print('Programs length: ${programs.length}');
      
      // Validate programs data
      final validPrograms = programs.where((program) {
        // Check for different possible field names
        final hasId = program['id'] != null;
        final hasName = program['title'] != null; // الباكند يستخدم 'title' بدلاً من 'name'
        
        print('Program validation: id=$hasId, name=$hasName, program=$program');
        print('Available keys: ${program.keys.toList()}');
        
        return hasId && hasName;
      }).map((program) {
        // Normalize the data structure
        return {
          'id': program['id'],
          'name': program['title'], // استخدام 'title' من الباكند
          'description': program['description'] ?? '',
        };
      }).toList();
      
      setState(() {
        _programs = validPrograms;
        _isLoadingPrograms = false;
      });
      
      print('Loaded ${validPrograms.length} valid programs out of ${programs.length} total');
      if (validPrograms.isNotEmpty) {
        print('Valid programs: ${validPrograms.map((p) => '${p['id']}: ${p['name']}').join(', ')}');
      } else {
        print('No valid programs found. All programs: ${programs.map((p) => p.toString()).join(', ')}');
      }
    } catch (error) {
      print('Error loading programs: $error');
      setState(() {
        _isLoadingPrograms = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في تحميل البرامج: ${error.toString()}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }







  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // Show options dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر مصدر الصورة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('التقاط صورة من الكاميرا'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('اختيار من المعرض'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImagePath = image.path;
          _selectedImageBytes = bytes;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التقاط صورة البطاقة الشخصية بنجاح'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء التقاط الصورة'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImagePath = image.path;
          _selectedImageBytes = bytes;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع صورة البطاقة الشخصية بنجاح'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء رفع الصورة'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _submitRegistration() async {
    // This function handles both new registration and re-submission after rejection
    // التحقق من الحقول المطلوبة
    if (_selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الجنس'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedMaritalStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الحالة الاجتماعية'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedIncomeLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار مستوى الدخل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedFamilySize.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار حجم الأسرة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_programs.isEmpty && !_isLoadingPrograms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد برامج متاحة. يرجى المحاولة مرة أخرى'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedProgramId == null || _selectedProgramId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار البرنامج'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Verify that the selected program exists in the programs list
    final selectedProgramExists = _programs.any(
      (program) => program['id']?.toString() == _selectedProgramId,
    );
    
    if (!selectedProgramExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('البرنامج المحدد غير صحيح. يرجى اختيار برنامج آخر'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      print('User authenticated, proceeding with registration');
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  'جاري إرسال الطلب...',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى الانتظار قليلاً',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        // Print registration data for debugging
        print('Submitting registration with data:');
        print('Full Name: ${_fullNameController.text.trim()}');
        print('Student ID: ${_studentIdController.text.trim()}');
        print('Phone: ${_phoneController.text.trim()}');
        print('University: ${_universityController.text.trim()}');
        print('College: ${_collegeController.text.trim()}');
        print('Major: ${_majorController.text.trim()}');
        print('Program: ${_programController.text.trim()}');
        print('Academic Year: ${_academicYearController.text}');
        print('GPA: ${_gpaController.text}');
        print('Gender: $_selectedGender');
        print('Marital Status: $_selectedMaritalStatus');
        print('Income Level: $_selectedIncomeLevel');
        print('Family Size: $_selectedFamilySize');
        print('Email: ${_emailController.text.trim()}');
        
        // Submit student registration
        await _studentService.submitStudentRegistration(
          fullName: _fullNameController.text.trim(),
          studentId: _studentIdController.text.trim(),
          phone: _phoneController.text.trim(),
          university: _universityController.text.trim(),
          college: _collegeController.text.trim(),
          major: _majorController.text.trim(),
          program: _programController.text.trim(),
          academicYear: _academicYearController.text,
          gpa: double.tryParse(_gpaController.text) ?? 0.0,
          gender: _selectedGender,
          maritalStatus: _selectedMaritalStatus,
          incomeLevel: _selectedIncomeLevel,
          familySize: _selectedFamilySize,
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          idCardImagePath: _selectedImagePath,
          idCardImageBytes: _selectedImageBytes,
          programId: _selectedProgramId != null ? int.tryParse(_selectedProgramId!) : 1,
        );

        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show success dialog
        _showSuccessDialog();
      } catch (error) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show error message
        if (mounted) {
          print('Registration error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'خطأ في التسجيل: ${error.toString()}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }



  void _showSuccessDialog() {
    // تحديث حالة الطلب فوراً
    _updateApplicationStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تم التسجيل بنجاح! 🎉',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'تم إرسال طلب التسجيل في صندوق الطالب الجامعي بنجاح. سيتم مراجعة طلبك والرد عليك في أقرب وقت ممكن.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close success dialog
                    // Navigate back to home screen and clear navigation stack
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppConstants.homeRoute,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'حسناً',
                    style: AppTextStyles.buttonMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // App Header - Consistent with App Design
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,

                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.modernGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.largePadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row with Title
                            Row(
                              children: [
                                // Page Title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'تسجيل الطالب',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.surface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'صندوق الطالب الجامعي',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.surface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Description Section
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.surface.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.school_outlined,
                                      color: AppColors.surface,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'املأ النموذج التالي لتسجيل طلبك',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.surface,
                                        fontWeight: FontWeight.w500,
                                      ),
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
              ),
              

              
              // Form Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Application Status Indicator (if data exists)
                        if (widget.existingData != null) ...[
                          _buildStatusIndicator(),
                          const SizedBox(height: 24),
                        ],
                        // Personal Information Section
                        _buildSectionHeader(
                          title: 'المعلومات الشخصية',
                          icon: Icons.person_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _fullNameController,
                          label: 'الاسم الكامل',
                          hint: 'أدخل اسمك الكامل',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال الاسم الكامل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _studentIdController,
                                label: 'رقم الطالب',
                                hint: 'أدخل رقم الطالب',
                                icon: Icons.badge,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال رقم الطالب';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'الجنس',
                                value: _selectedGender,
                                items: ['ذكر', 'أنثى'],
                                                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGender = value!;
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                                                      const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'البريد الإلكتروني',
                                hint: 'أدخل بريدك الإلكتروني',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال البريد الإلكتروني';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'يرجى إدخال بريد إلكتروني صحيح';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'رقم الهاتف',
                                hint: 'أدخل رقم الهاتف',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال رقم الهاتف';
                                  }
                                  return null;
                                },
                              ),
                        
                        
                        const SizedBox(height: 32),
                        
                        // Academic Information Section
                        _buildSectionHeader(
                          title: 'المعلومات الأكاديمية',
                          icon: Icons.school_outlined,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _universityController,
                          label: 'الجامعة',
                          hint: 'أدخل اسم الجامعة',
                          icon: Icons.account_balance,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال اسم الجامعة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _collegeController,
                                label: 'الكلية',
                                hint: 'أدخل اسم الكلية',
                                icon: Icons.business,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال اسم الكلية';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _majorController,
                                label: 'التخصص',
                                hint: 'أدخل التخصص',
                                icon: Icons.book,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال التخصص';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildProgramDropdown(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'السنة الدراسية',
                                value: _academicYearController.text.isEmpty 
                                    ? null 
                                    : _academicYearController.text,
                                items: _academicYears,
                                onChanged: (value) {
                                  setState(() {
                                    _academicYearController.text = value ?? '';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _gpaController,
                                label: 'المعدل التراكمي',
                                hint: 'أدخل المعدل التراكمي',
                                icon: Icons.grade,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال المعدل التراكمي';
                                  }
                                  final gpa = double.tryParse(value);
                                  if (gpa == null || gpa < 0 || gpa > 5) {
                                    return 'يرجى إدخال معدل تراكمي صحيح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Financial Information Section
                        _buildSectionHeader(
                          title: 'المعلومات المالية',
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'مستوى الدخل',
                                value: _selectedIncomeLevel,
                                items: _incomeLevels,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedIncomeLevel = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'حجم الأسرة',
                                value: _selectedFamilySize,
                                items: _familySizes,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFamilySize = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                                                // Required Documents Section
                        _buildSectionHeader(
                          title: 'المستندات المطلوبة',
                          icon: Icons.upload_file_outlined,
                          color: AppColors.info,
                        ),
                        const SizedBox(height: 16),
                        _buildDocumentUploadTile(
                          title: 'صورة البطاقة الشخصية',
                          subtitle: 'يرجى رفع صورة واضحة للبطاقة الشخصية',
                          icon: Icons.credit_card,
                          onTap: () => _pickImage(),
                        ),
                        
                        const SizedBox(height: 32),
                        

                        
                        const SizedBox(height: 40),
                        
                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                                                  ),
                        child: ElevatedButton(
                          onPressed: _isReadOnly ? null : _submitRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.surface,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isReadOnly ? Icons.lock_outline : (_isRejected ? Icons.refresh : Icons.send),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isReadOnly ? 'لا يمكن التعديل' : (_isRejected ? 'إعادة التسجيل' : 'تسجيل'),
                                style: AppTextStyles.buttonLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Privacy Note
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.info.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.privacy_tip_outlined,
                                color: AppColors.info,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'جميع المعلومات محمية ومؤمنة ولن يتم مشاركتها مع أي طرف ثالث',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isReadOnly ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isReadOnly ? AppColors.textTertiary.withOpacity(0.3) : AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: _isReadOnly ? null : validator,
        enabled: !_isReadOnly,
        readOnly: _isReadOnly,
        style: AppTextStyles.bodyLarge.copyWith(
          color: _isReadOnly ? AppColors.textSecondary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: _isReadOnly ? null : hint,
          prefixIcon: Icon(
            icon,
            color: _isReadOnly ? AppColors.textSecondary : AppColors.primary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: _isReadOnly ? AppColors.textSecondary : AppColors.textSecondary,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          suffixIcon: _isReadOnly ? const Icon(
            Icons.lock_outline,
            color: AppColors.textSecondary,
            size: 16,
          ) : null,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isReadOnly ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isReadOnly ? AppColors.textTertiary.withOpacity(0.3) : AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: _isReadOnly 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value ?? '',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          )
        : DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: AppTextStyles.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            style: AppTextStyles.bodyLarge,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.primary,
            ),
          ),
    );
  }

  Widget _buildProgramDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: _isReadOnly ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isReadOnly ? AppColors.textTertiary.withOpacity(0.3) : AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: _isReadOnly 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'البرنامج',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSelectedProgramName(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          )
        : _isLoadingPrograms
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'جاري تحميل البرامج...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _programs.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'لا توجد برامج متاحة',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadPrograms,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('إعادة تحميل البرامج'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : DropdownButtonFormField<String>(
                value: _selectedProgramId,
                items: _programs.map((program) {
                  return DropdownMenuItem<String>(
                    value: program['id']?.toString(),
                    child: Text(
                      program['name'] ?? 'برنامج غير محدد',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProgramId = value;
                  // Update program name in text controller for display
                  if (value != null) {
                    final selectedProgram = _programs.firstWhere(
                      (program) => program['id']?.toString() == value,
                      orElse: () => {},
                    );
                    _programController.text = selectedProgram['name'] ?? '';
                  } else {
                    _programController.text = '';
                  }
                });
              },
              decoration: InputDecoration(
                labelText: 'البرنامج',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.school,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              style: AppTextStyles.bodyLarge,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار البرنامج';
                }
                return null;
              },
            ),
    );
  }

  String _getSelectedProgramName() {
    if (_selectedProgramId == null) return 'لم يتم اختيار برنامج';
    
    final selectedProgram = _programs.firstWhere(
      (program) => program['id']?.toString() == _selectedProgramId,
      orElse: () => {},
    );
    
    return selectedProgram['name'] ?? 'برنامج غير محدد';
  }

  // تحديث حالة الطلب فوراً بعد التسجيل
  void _updateApplicationStatus() {
    setState(() {
      // تحديث حالة الطلب إلى "pending" (في الانتظار)
      _applicationStatus = 'pending';
      _rejectionReason = null; // مسح سبب الرفض إذا كان موجوداً
    });
    
    print('StudentRegistrationScreen: Application status updated to: $_applicationStatus');
    print('StudentRegistrationScreen: Will navigate to home screen after success dialog');
    
    // إظهار رسالة نجاح إضافية
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تحديث حالة الطلب إلى: في الانتظار',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // دالة مساعدة لتحويل السنة الدراسية إلى رقم
  int _convertAcademicYearToNumber(String academicYear) {
    switch (academicYear) {
      case 'السنة الأولى':
        return 1;
      case 'السنة الثانية':
        return 2;
      case 'السنة الثالثة':
        return 3;
      case 'السنة الرابعة':
        return 4;
      case 'السنة الخامسة':
        return 5;
      case 'السنة السادسة':
        return 6;
      default:
        return 1;
    }
  }

  // دالة مساعدة لتحويل مستوى الدخل إلى الإنجليزية
  String _convertIncomeLevelToEnglish(String incomeLevel) {
    switch (incomeLevel) {
      case 'منخفض':
        return 'low';
      case 'متوسط':
        return 'medium';
      case 'مرتفع':
        return 'high';
      default:
        return 'medium';
    }
  }

  // إعادة تحميل حالة الطلب من الخادم
  Future<void> _refreshApplicationStatus() async {
    try {
      // إظهار مؤشر التحميل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('جاري تحديث حالة الطلب...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // جلب أحدث حالة الطلب من الخادم
      final currentRegistration = await _studentService.getCurrentUserRegistration();
      
      if (currentRegistration != null) {
        setState(() {
          _applicationStatus = currentRegistration['status'] ?? 'pending';
          _rejectionReason = currentRegistration['rejection_reason'];
        });
        
        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث حالة الطلب: ${_getStatusText(_applicationStatus)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // إظهار رسالة خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لم يتم العثور على طلب تسجيل',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      print('Error refreshing application status: $error');
      
      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في تحديث حالة الطلب: ${error.toString()}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildDocumentUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.info,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: _selectedImagePath != null
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                                  child: _selectedImageBytes != null
                    ? Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.upload,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}