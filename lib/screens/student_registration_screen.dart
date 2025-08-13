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


  // Form Values
  String _selectedGender = 'ذكر';
  final String _selectedMaritalStatus = 'أعزب';
  String _selectedIncomeLevel = 'منخفض';
  String _selectedFamilySize = '1-3';
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  
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
  }

  void _loadExistingData() {
    final data = widget.existingData!;
    
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
    _academicYearController.text = _convertAcademicYearToString(data['academic']?['academic_year'] ?? 1);
    _gpaController.text = (data['academic']?['gpa'] ?? 0.0).toString();
    
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
    
    if (_programController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم البرنامج'),
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
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _programController,
                                label: 'البرنامج',
                                hint: 'أدخل اسم البرنامج',
                                icon: Icons.school,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال اسم البرنامج';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
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
                            onPressed: _submitRegistration,
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
                                const Icon(
                                  Icons.send,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'سجل الآن',
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: validator,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
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