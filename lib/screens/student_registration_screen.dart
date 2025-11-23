import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../services/student_registration_service.dart';
import '../providers/auth_provider.dart';


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
  String _selectedGender = 'male';
  final String _selectedMaritalStatus = 'single';
  String _selectedIncomeLevel = 'low';
  String _selectedFamilySize = '1-3';
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  
  // Application Status
  String _applicationStatus = 'pending'; // pending, under_review, approved, rejected
  String? _rejectionReason; // سبب الرفض
  
  // Services
  final StudentRegistrationService _studentService = StudentRegistrationService();




  // Academic Year Options
  final List<String> _academicYears = [
    'first_year',
    'second_year',
    'third_year',
    'fourth_year',
    'fifth_year',
    'sixth_year',
  ];

  // Income Level Options
  final List<String> _incomeLevels = [
    'low',
    'medium',
    'high',
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
    // Prefill user profile data (name, email, phone) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromUserProfile();
    });
    
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh program names when locale changes
    _refreshProgramNamesForCurrentLocale();
  }

  void _refreshProgramNamesForCurrentLocale() {
    if (_programs.isNotEmpty && _selectedProgramId != null) {
      setState(() {
        // Update the selected program name in the controller
        final selectedProgram = _programs.firstWhere(
          (program) => program['id']?.toString() == _selectedProgramId,
          orElse: () => {},
        );
        if (selectedProgram.isNotEmpty) {
          _programController.text = StudentRegistrationService.getLocalizedProgramName(selectedProgram, context.locale.languageCode);
        }
      });
    }
  }

  void _loadExistingData() {
    final data = widget.existingData!;
    
    // Debug: Print data being loaded
    print('=== Loading Existing Data Debug ===');
    print('Data: $data');
    print('Status: ${data['status']}');
    print('Status type: ${data['status']?.runtimeType}');
    print('Rejection reason: ${data['rejection_reason']}');
    print('Rejection reason type: ${data['rejection_reason']?.runtimeType}');
    print('===================================');
    
    // Load and normalize application status
    String rawStatus = data['status']?.toString() ?? 'pending';
    String normalizedStatus = rawStatus.toLowerCase();
    
    // Normalize status values
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        _applicationStatus = 'pending';
        break;
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        _applicationStatus = 'under_review';
        break;
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        _applicationStatus = 'approved';
        break;
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        _applicationStatus = 'rejected';
        break;
      default:
        print('Warning: Unknown status: $rawStatus, defaulting to pending');
        _applicationStatus = 'pending';
    }
    
    // Load rejection reason
    _rejectionReason = data['rejection_reason']?.toString();
    if (_rejectionReason != null && _rejectionReason!.isEmpty) {
      _rejectionReason = null;
    }
    
    // Debug: Print final loaded status
    print('Final loaded status: $_applicationStatus');
    print('Final rejection reason: $_rejectionReason');
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
      print('StudentRegistrationScreen: Programs not loaded yet, loading programs first...');
      _loadPrograms();
      
      // After loading programs, try to select the correct program
      if (_selectedProgramId != null && _programs.isNotEmpty) {
        final programExists = _programs.any((program) => program['id']?.toString() == _selectedProgramId);
        if (!programExists) {
          print('StudentRegistrationScreen: Selected program ID $_selectedProgramId not found in loaded programs');
          print('StudentRegistrationScreen: Available program IDs: ${_programs.map((p) => p['id']).join(', ')}');
          
          // Auto-select first program if the selected one doesn't exist
          if (_programs.isNotEmpty) {
            _selectedProgramId = _programs.first['id']?.toString();
            _programController.text = _programs.first['name'] ?? '';
            print('StudentRegistrationScreen: Auto-selected first program: ${_programs.first['name']}');
          }
        } else {
          // Update program controller text with the correct program name
          final selectedProgram = _programs.firstWhere(
            (program) => program['id']?.toString() == _selectedProgramId,
            orElse: () => {},
          );
          if (selectedProgram.isNotEmpty) {
            _programController.text = selectedProgram['name'] ?? '';
            print('StudentRegistrationScreen: Updated program controller with: ${selectedProgram['name']}');
          }
        }
      }
    } else {
      // Programs already loaded, try to select the correct program
      if (_selectedProgramId != null) {
        final programExists = _programs.any((program) => program['id']?.toString() == _selectedProgramId);
        if (!programExists) {
          print('StudentRegistrationScreen: Selected program ID $_selectedProgramId not found in already loaded programs');
          if (_programs.isNotEmpty) {
            _selectedProgramId = _programs.first['id']?.toString();
            _programController.text = _programs.first['name'] ?? '';
            print('StudentRegistrationScreen: Auto-selected first program: ${_programs.first['name']}');
          }
        } else {
          // Update program controller text with the correct program name
          final selectedProgram = _programs.firstWhere(
            (program) => program['id']?.toString() == _selectedProgramId,
            orElse: () => {},
          );
          if (selectedProgram.isNotEmpty) {
            _programController.text = selectedProgram['name'] ?? '';
            print('StudentRegistrationScreen: Updated program controller with: ${selectedProgram['name']}');
          }
        }
      }
    }
    
    // Load financial data
    _selectedIncomeLevel = _convertIncomeLevelToArabic(data['financial']?['income_level'] ?? 'low');
    _selectedFamilySize = _convertFamilySizeToString(data['financial']?['family_size'] ?? 3);
    
    // Load gender
    _selectedGender = data['personal']?['gender'] == 'male' ? 'male' : 'female';
  }

  void _prefillFromUserProfile() {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profile = auth.userProfile;
      if (profile == null) return;

      final extractedName = profile['name'] ?? profile['user']?['name'] ?? '';
      final extractedEmail = profile['email'] ?? profile['user']?['email'] ?? '';
      final extractedPhone = profile['phone'] ?? profile['user']?['phone'] ?? '';

      setState(() {
        if (extractedName is String && extractedName.isNotEmpty) {
          _fullNameController.text = extractedName;
        }
        if (extractedEmail is String && extractedEmail.isNotEmpty) {
          _emailController.text = extractedEmail;
        }
        if (extractedPhone is String && extractedPhone.isNotEmpty) {
          _phoneController.text = extractedPhone;
        }
      });
    } catch (e) {
      // Ignore prefill errors; keep form usable
      debugPrint('Prefill error: $e');
    }
  }

  String _convertAcademicYearToString(dynamic year) {
    final yearNum = year is int ? year : int.tryParse(year.toString()) ?? 1;
    switch (yearNum) {
      case 1: return 'first_year'.tr();
      case 2: return 'second_year'.tr();
      case 3: return 'third_year'.tr();
      case 4: return 'fourth_year'.tr();
      case 5: return 'fifth_year'.tr();
      case 6: return 'sixth_year'.tr();
      default: return 'first_year'.tr();
    }
  }

  String _convertIncomeLevelToArabic(String level) {
    switch (level.toLowerCase()) {
      case 'low': return 'low'.tr();
      case 'medium': return 'medium'.tr();
      case 'high': return 'high'.tr();
      default: return 'low'.tr();
    }
  }

  String _convertFamilySizeToString(dynamic size) {
    final sizeNum = size is int ? size : int.tryParse(size.toString()) ?? 3;
    if (sizeNum <= 3) return '1-3';
    if (sizeNum <= 6) return '4-6';
    if (sizeNum <= 9) return '7-9';
    return '10+';
  }

  String _getTranslatedValue(String value) {
    // Handle family size values
    if (['1-3', '4-6', '7-9', '10+'].contains(value)) {
      return value.tr();
    }
    
    // Handle income level values
    if (['low', 'medium', 'high'].contains(value)) {
      return value.tr();
    }
    
    // Handle academic year values
    if (['first_year', 'second_year', 'third_year', 'fourth_year', 'fifth_year', 'sixth_year'].contains(value)) {
      return value.tr();
    }
    
    // Handle gender values
    if (['male', 'female'].contains(value)) {
      return value.tr();
    }
    
    // Default: return the value as is
    return value;
  }

  // Check if the form should be read-only
  // Returns true for: under_review, approved, accepted
  // Returns false for: pending, rejected (allows editing)
  bool get _isReadOnly {
    // Normalize status
    String normalizedStatus = _applicationStatus.toLowerCase();
    
    return widget.isReadOnly || 
           normalizedStatus == 'under_review' || 
           normalizedStatus == 'قيد المراجعة' ||
           normalizedStatus == 'قيد الدراسة' ||
           normalizedStatus == 'approved' ||
           normalizedStatus == 'accepted' ||
           normalizedStatus == 'مقبول' ||
           normalizedStatus == 'تم القبول';
    // Note: rejected status allows editing for re-submission
  }

  // Check if the form should show rejection status
  bool get _isRejected {
    // Normalize status
    String normalizedStatus = _applicationStatus.toLowerCase();
    
    return normalizedStatus == 'rejected' ||
           normalizedStatus == 'مرفوض' ||
           normalizedStatus == 'تم الرفض';
  }

  // Get status text in Arabic
  String _getStatusText(String status) {
    // Debug: Print status text decision
    print('=== Status Text Debug ===');
    print('Status: $status');
    
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        print('Status text: في الانتظار');
        return 'في الانتظار';
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        print('Status text: قيد المراجعة');
        return 'قيد المراجعة';
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        print('Status text: تم القبول');
        return 'تم القبول';
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        print('Status text: تم الرفض');
        return 'تم الرفض';
      default:
        print('Status text: في الانتظار (default)');
        return 'في الانتظار';
    }
  }

  // Get status color
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
                      'application_status'.tr(),
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
                      label: Text('refresh'.tr()),
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
                        'rejection_reason'.tr(),
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
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        return Icons.schedule;
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return Icons.hourglass_empty;
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
        return Icons.schedule;
    }
  }

  // Get status description
  String _getStatusDescription(String status) {
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        return 'طلبك في قائمة الانتظار. سيتم مراجعته قريباً من قبل اللجنة المختصة.';
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return 'طلبك قيد المراجعة من قبل اللجنة المختصة. لا يمكن تعديل البيانات في هذه المرحلة.';
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        return 'مبروك! تم قبول طلبك. سيتم التواصل معك قريباً لتأكيد التفاصيل.';
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
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
            'edit_enabled'.tr(),
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
      print('StudentRegistrationScreen: Loading programs from API...');
      final programs = await _studentService.getSupportPrograms();
      
      print('StudentRegistrationScreen: Raw programs received: $programs');
      print('StudentRegistrationScreen: Programs length: ${programs.length}');
      
      // Validate programs data
      final validPrograms = programs.where((program) {
        // Check for different possible field names
        final hasId = program['id'] != null;
        final hasName = program['name'] != null;
        
        print('StudentRegistrationScreen: Program validation: id=$hasId, name=$hasName, program=$program');
        print('StudentRegistrationScreen: Available keys: ${program.keys.toList()}');
        
        return hasId && hasName;
      }).map((program) {
        // Normalize the data structure
        return {
          'id': program['id'],
          'name': program['name'],
          'description': program['description'] ?? '',
        };
      }).toList();
      
      setState(() {
        _programs = validPrograms;
        _isLoadingPrograms = false;
      });
      
      print('StudentRegistrationScreen: Loaded ${validPrograms.length} valid programs out of ${programs.length} total');
      if (validPrograms.isNotEmpty) {
        print('StudentRegistrationScreen: Valid programs: ${validPrograms.map((p) => '${p['id']}: ${p['name']}').join(', ')}');
        
        // Auto-select first program if none selected
        if (_selectedProgramId == null && validPrograms.isNotEmpty) {
          setState(() {
            _selectedProgramId = validPrograms.first['id']?.toString();
            _programController.text = StudentRegistrationService.getLocalizedProgramName(validPrograms.first, context.locale.languageCode);
          });
          print('StudentRegistrationScreen: Auto-selected first program: ${validPrograms.first['name']}');
        }
      } else {
        print('StudentRegistrationScreen: No valid programs found. All programs: ${programs.map((p) => p.toString()).join(', ')}');
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لم يتم العثور على برامج دعم متاحة. يرجى التواصل مع الإدارة لإضافة برامج الدعم.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (error) {
      print('StudentRegistrationScreen: Error loading programs: $error');
      setState(() {
        _isLoadingPrograms = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في تحميل برامج الدعم: ${error.toString()}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () {
                _loadPrograms();
              },
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
          title: Text('select_file'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('camera'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('gallery'.tr()),
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
          SnackBar(
            content: Text('file_uploaded'.tr()),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('file_upload_failed'.tr()),
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
          SnackBar(
            content: Text('file_uploaded'.tr()),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('file_upload_failed'.tr()),
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
        SnackBar(
          content: Text('required_field'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedMaritalStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_choose_marital_status'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedIncomeLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_choose_income_level'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedFamilySize.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_choose_family_size'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_programs.isEmpty && !_isLoadingPrograms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('no_programs_available'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedProgramId == null || _selectedProgramId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_choose_program'.tr()),
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
        SnackBar(
          content: Text('invalid_program_selected'.tr()),
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
                  'submitting_application'.tr(),
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'please_wait'.tr(),
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
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close success dialog
                    
                    // Add delay to ensure backend has saved the registration
                    await Future.delayed(const Duration(milliseconds: 800));
                    
                    // Navigate back to home screen and clear navigation stack
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppConstants.homeRoute,
                      (route) => false,
                    ).then((_) {
                      // Force refresh after navigation completes
                      // This will be handled by initState, but we add extra delay
                      print('StudentRegistrationScreen: Navigation to home completed');
                    });
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
                actions: const [],

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
                                        child: Text(
                                          'student_registration'.tr(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.surface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'app_title'.tr(),
                                        style: const TextStyle(
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
                                  Expanded(
                                    child: Text(
                                      'fill_form_to_register'.tr(),
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
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.largePadding, vertical: AppConstants.defaultPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Application Status Indicator (if data exists)
                        if (widget.existingData != null) ...[
                          _buildStatusIndicator(),
                          const SizedBox(height: 32),
                        ],
                        // Personal Information Section
                        _buildSectionHeader(
                          title: 'personal_information'.tr(),
                          icon: Icons.person_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 20),
                        // Personal Information Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _fullNameController,
                                label: 'full_name'.tr(),
                                hint: 'please_enter_full_name'.tr(),
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please_enter_full_name'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _studentIdController,
                                label: 'student_id'.tr(),
                                hint: 'please_enter_student_id'.tr(),
                                icon: Icons.badge,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please_enter_student_id'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownField(
                                label: 'gender'.tr(),
                                value: _selectedGender,
                                items: ['male', 'female'],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'email'.tr(),
                                hint: 'please_enter_email'.tr(),
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please_enter_email'.tr();
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'please_enter_valid_email'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'phone_number'.tr(),
                                hint: 'please_enter_phone'.tr(),
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                readOnlyOverride: true,
                                enabledOverride: false,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please_enter_phone'.tr();
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Academic Information Section
                        _buildSectionHeader(
                          title: 'academic_information'.tr(),
                          icon: Icons.school_outlined,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 20),
                        // Academic Information Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _universityController,
                                label: 'university'.tr(),
                                hint: 'please_enter_university'.tr(),
                                icon: Icons.account_balance,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please_enter_university'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _collegeController,
                                label: 'college'.tr(),
                                hint: 'please_enter_college'.tr(),
                                icon: Icons.business,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please_enter_college'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _majorController,
                                label: 'major'.tr(),
                                hint: 'please_enter_major'.tr(),
                                icon: Icons.book,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please_enter_major'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildProgramDropdown(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _buildDropdownField(
                                      label: 'academic_year'.tr(),
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
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: _buildTextField(
                                      controller: _gpaController,
                                      label: 'gpa'.tr(),
                                      hint: 'please_enter_gpa'.tr(),
                                      icon: Icons.grade,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'please_enter_gpa'.tr();
                                        }
                                        final gpa = double.tryParse(value);
                                        if (gpa == null || gpa < 0 || gpa > 5) {
                                          return 'please_enter_valid_gpa'.tr();
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Financial Information Section
                        _buildSectionHeader(
                          title: 'financial_information'.tr(),
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 20),
                        // Financial Information Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildDropdownField(
                                  label: 'income_level'.tr(),
                                  value: _selectedIncomeLevel,
                                  items: _incomeLevels,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedIncomeLevel = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: _buildDropdownField(
                                  label: 'family_size'.tr(),
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
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Required Documents Section
                        _buildSectionHeader(
                          title: 'required_documents'.tr(),
                          icon: Icons.upload_file_outlined,
                          color: AppColors.info,
                        ),
                        const SizedBox(height: 20),
                        _buildDocumentUploadTile(
                          title: 'id_photo'.tr(),
                          subtitle: 'please_upload_documents'.tr(),
                          icon: Icons.credit_card,
                          onTap: () => _pickImage(),
                        ),
                        
                        const SizedBox(height: 32),
                        

                        
                        const SizedBox(height: 40),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isReadOnly ? null : _submitRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isReadOnly ? AppColors.surfaceVariant : AppColors.primary,
                              foregroundColor: AppColors.surface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isReadOnly 
                                      ? Icons.lock_outline 
                                      : (_isRejected ? Icons.refresh : Icons.send),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isReadOnly 
                                      ? 'cannot_edit'.tr() 
                                      : (_isRejected ? 'resubmit_application'.tr() : 'register'.tr()),
                                  style: AppTextStyles.buttonLarge.copyWith(
                                    fontWeight: FontWeight.w600,
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
                                  'privacy_notice'.tr(),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
    bool? readOnlyOverride,
    bool? enabledOverride,
  }) {
    final bool effectiveReadOnly = readOnlyOverride ?? _isReadOnly;
    final bool effectiveEnabled = enabledOverride ?? !effectiveReadOnly;
    return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: effectiveReadOnly ? null : validator,
        enabled: effectiveEnabled,
        readOnly: effectiveReadOnly,
        style: AppTextStyles.bodyLarge.copyWith(
          color: effectiveReadOnly ? AppColors.textSecondary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: effectiveReadOnly ? null : hint,
          prefixIcon: Icon(
            icon,
            color: effectiveReadOnly ? AppColors.textSecondary : AppColors.primary,
            size: 20,
          ),
          filled: true,
          fillColor: effectiveReadOnly ? AppColors.surfaceVariant : AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textTertiary.withOpacity(0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textTertiary.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.error,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: effectiveReadOnly ? AppColors.textSecondary : AppColors.textSecondary,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          suffixIcon: effectiveReadOnly 
              ? const Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                  size: 18,
                )
              : null,
        ),
      );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return _isReadOnly 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textTertiary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
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
                        value != null ? _getTranslatedValue(value) : '',
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
                  size: 18,
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
                  _getTranslatedValue(item),
                  style: AppTextStyles.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textTertiary.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textTertiary.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
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
              size: 20,
            ),
            isExpanded: true,
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
                        'program'.tr(),
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
                        label: Text('reload_programs'.tr()),
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
                      StudentRegistrationService.getLocalizedProgramName(program, context.locale.languageCode),
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
                    _programController.text = StudentRegistrationService.getLocalizedProgramName(selectedProgram, context.locale.languageCode);
                  } else {
                    _programController.text = '';
                  }
                });
              },
              decoration: InputDecoration(
                labelText: 'program'.tr(),
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
    if (_selectedProgramId == null) {
      print('StudentRegistrationScreen: No program selected');
      return 'لم يتم اختيار برنامج';
    }
    
    print('StudentRegistrationScreen: Looking for program with ID: $_selectedProgramId');
    print('StudentRegistrationScreen: Available programs: ${_programs.map((p) => '${p['id']}: ${p['name']}').join(', ')}');
    
    final selectedProgram = _programs.firstWhere(
      (program) => program['id']?.toString() == _selectedProgramId,
      orElse: () {
        print('StudentRegistrationScreen: Program not found with ID: $_selectedProgramId');
        return {};
      },
    );
    
    if (selectedProgram.isEmpty) {
      print('StudentRegistrationScreen: Selected program is empty');
      return 'برنامج غير محدد';
    }
    
    final programName = StudentRegistrationService.getLocalizedProgramName(selectedProgram, context.locale.languageCode);
    print('StudentRegistrationScreen: Selected program name: $programName');
    return programName;
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
              Text('updating_request_status'.tr()),
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
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isReadOnly ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.info,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _selectedImagePath != null
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
                                    return const Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                      size: 20,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                        ),
                      )
                    : const Icon(
                        Icons.upload,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}