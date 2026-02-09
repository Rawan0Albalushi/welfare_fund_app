/// نموذج بيانات ولي الأمر
class GuardianInfo {
  final String? name;
  final String? job;
  final double? monthlyIncome;
  final int? familySize;
  final bool? isFatherAlive;
  final bool? isMotherAlive;
  final String? parentsMaritalStatus; // stable, separated

  GuardianInfo({
    this.name,
    this.job,
    this.monthlyIncome,
    this.familySize,
    this.isFatherAlive,
    this.isMotherAlive,
    this.parentsMaritalStatus,
  });

  factory GuardianInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return GuardianInfo();
    return GuardianInfo(
      name: json['name']?.toString(),
      job: json['job']?.toString(),
      monthlyIncome: double.tryParse(json['monthly_income']?.toString() ?? ''),
      familySize: int.tryParse(json['family_size']?.toString() ?? ''),
      isFatherAlive: json['is_father_alive'] == true || json['is_father_alive'] == 1 || json['is_father_alive'] == '1',
      isMotherAlive: json['is_mother_alive'] == true || json['is_mother_alive'] == 1 || json['is_mother_alive'] == '1',
      parentsMaritalStatus: json['parents_marital_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (job != null) 'job': job,
      if (monthlyIncome != null) 'monthly_income': monthlyIncome,
      if (familySize != null) 'family_size': familySize,
      if (isFatherAlive != null) 'is_father_alive': isFatherAlive,
      if (isMotherAlive != null) 'is_mother_alive': isMotherAlive,
      if (parentsMaritalStatus != null) 'parents_marital_status': parentsMaritalStatus,
    };
  }

  GuardianInfo copyWith({
    String? name,
    String? job,
    double? monthlyIncome,
    int? familySize,
    bool? isFatherAlive,
    bool? isMotherAlive,
    String? parentsMaritalStatus,
  }) {
    return GuardianInfo(
      name: name ?? this.name,
      job: job ?? this.job,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      familySize: familySize ?? this.familySize,
      isFatherAlive: isFatherAlive ?? this.isFatherAlive,
      isMotherAlive: isMotherAlive ?? this.isMotherAlive,
      parentsMaritalStatus: parentsMaritalStatus ?? this.parentsMaritalStatus,
    );
  }
}

/// نموذج المستندات/المرفقات
class DocumentsInfo {
  final String? applicationLetter;    // رسالة تقديم الطلب
  final String? idCard;               // صورة البطاقة الشخصية
  final String? enrollmentLetter;     // رسالة الانتظام
  final String? tuitionLetter;        // رسالة الرسوم الدراسية
  final String? incomeProof;          // إثبات الدخل
  final String? bankStatements;       // كشف حساب البنك
  final String? debtProof;            // إثبات المديونية
  final String? supportingDocuments;  // المستندات الداعمة
  final String? housingLetter;        // رسالة رسوم السكن

  DocumentsInfo({
    this.applicationLetter,
    this.idCard,
    this.enrollmentLetter,
    this.tuitionLetter,
    this.incomeProof,
    this.bankStatements,
    this.debtProof,
    this.supportingDocuments,
    this.housingLetter,
  });

  factory DocumentsInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DocumentsInfo();
    return DocumentsInfo(
      applicationLetter: json['application_letter']?.toString(),
      idCard: json['id_card']?.toString(),
      enrollmentLetter: json['enrollment_letter']?.toString(),
      tuitionLetter: json['tuition_letter']?.toString(),
      incomeProof: json['income_proof']?.toString(),
      bankStatements: json['bank_statements']?.toString(),
      debtProof: json['debt_proof']?.toString(),
      supportingDocuments: json['supporting_documents']?.toString(),
      housingLetter: json['housing_letter']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (applicationLetter != null) 'application_letter': applicationLetter,
      if (idCard != null) 'id_card': idCard,
      if (enrollmentLetter != null) 'enrollment_letter': enrollmentLetter,
      if (tuitionLetter != null) 'tuition_letter': tuitionLetter,
      if (incomeProof != null) 'income_proof': incomeProof,
      if (bankStatements != null) 'bank_statements': bankStatements,
      if (debtProof != null) 'debt_proof': debtProof,
      if (supportingDocuments != null) 'supporting_documents': supportingDocuments,
      if (housingLetter != null) 'housing_letter': housingLetter,
    };
  }

  DocumentsInfo copyWith({
    String? applicationLetter,
    String? idCard,
    String? enrollmentLetter,
    String? tuitionLetter,
    String? incomeProof,
    String? bankStatements,
    String? debtProof,
    String? supportingDocuments,
    String? housingLetter,
  }) {
    return DocumentsInfo(
      applicationLetter: applicationLetter ?? this.applicationLetter,
      idCard: idCard ?? this.idCard,
      enrollmentLetter: enrollmentLetter ?? this.enrollmentLetter,
      tuitionLetter: tuitionLetter ?? this.tuitionLetter,
      incomeProof: incomeProof ?? this.incomeProof,
      bankStatements: bankStatements ?? this.bankStatements,
      debtProof: debtProof ?? this.debtProof,
      supportingDocuments: supportingDocuments ?? this.supportingDocuments,
      housingLetter: housingLetter ?? this.housingLetter,
    );
  }

  bool get hasAnyDocument {
    return applicationLetter != null ||
        idCard != null ||
        enrollmentLetter != null ||
        tuitionLetter != null ||
        incomeProof != null ||
        bankStatements != null ||
        debtProof != null ||
        supportingDocuments != null ||
        housingLetter != null;
  }
}

/// نموذج البرنامج
class ProgramInfo {
  final int? id;
  final String? titleAr;
  final String? titleEn;

  ProgramInfo({
    this.id,
    this.titleAr,
    this.titleEn,
  });

  factory ProgramInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ProgramInfo();
    return ProgramInfo(
      id: int.tryParse(json['id']?.toString() ?? ''),
      titleAr: json['title_ar']?.toString(),
      titleEn: json['title_en']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (titleAr != null) 'title_ar': titleAr,
      if (titleEn != null) 'title_en': titleEn,
    };
  }

  String getLocalizedTitle(String locale) {
    if (locale == 'ar') {
      return titleAr ?? titleEn ?? '';
    }
    return titleEn ?? titleAr ?? '';
  }
}

/// نموذج تسجيل الطالب المحدث ليتوافق مع API الجديد
class StudentRegistration {
  final String? id;
  final String? registrationId;
  final int? programId;
  
  // البيانات الشخصية (personal)
  final String fullName;
  final String? civilId;          // الرقم المدني - جديد
  final DateTime? dateOfBirth;    // تاريخ الميلاد - جديد
  final String phone;
  final String? address;          // العنوان - جديد
  final String maritalStatus;     // single, married, divorced, widowed
  final String? email;
  final String? gender;
  
  // البيانات الأكاديمية (academic)
  final String institution;       // المؤسسة التعليمية (مطلوب)
  final String studentId;         // الرقم الجامعي (مطلوب)
  final String? college;          // الكلية (اختياري)
  final String? major;            // التخصص (اختياري)
  final String? program;          // البرنامج الدراسي
  final int? academicYear;        // السنة الدراسية
  final double? gpa;              // المعدل التراكمي
  
  // بيانات ولي الأمر (guardian) - جديد
  final GuardianInfo? guardian;
  
  // المرفقات (documents) - جديد
  final DocumentsInfo? documents;
  
  // معلومات البرنامج
  final ProgramInfo? programInfo;
  
  // حالة الطلب
  final String status;            // under_review, accepted, rejected, completed
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // للتوافق مع الكود القديم
  String get university => institution;
  String get incomeLevel => guardian?.monthlyIncome != null 
      ? (guardian!.monthlyIncome! < 300 ? 'low' : (guardian!.monthlyIncome! < 700 ? 'medium' : 'high'))
      : 'medium';
  String get familySize => guardian?.familySize?.toString() ?? '1-3';

  StudentRegistration({
    this.id,
    this.registrationId,
    this.programId,
    required this.fullName,
    this.civilId,
    this.dateOfBirth,
    required this.phone,
    this.address,
    required this.maritalStatus,
    this.email,
    this.gender,
    required this.institution,
    required this.studentId,
    this.college,
    this.major,
    this.program,
    this.academicYear,
    this.gpa,
    this.guardian,
    this.documents,
    this.programInfo,
    this.status = 'under_review',
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentRegistration.fromJson(Map<String, dynamic> json) {
    // Normalize status
    String rawStatus = json['status']?.toString() ?? 'under_review';
    String normalizedStatus = rawStatus.toLowerCase();
    
    String finalStatus;
    switch (normalizedStatus) {
      case 'under_review':
      case 'قيد المراجعة':
        finalStatus = 'under_review';
        break;
      case 'accepted':
      case 'مقبول':
        finalStatus = 'accepted';
        break;
      case 'rejected':
      case 'مرفوض':
        finalStatus = 'rejected';
        break;
      case 'completed':
      case 'مكتمل':
        finalStatus = 'completed';
        break;
      default:
        print('Warning: Unknown status in StudentRegistration.fromJson: $rawStatus, defaulting to under_review');
        finalStatus = 'under_review';
    }
    
    // Parse personal data
    final personal = json['personal'] as Map<String, dynamic>? ?? {};
    
    // Parse academic data
    final academic = json['academic'] as Map<String, dynamic>? ?? {};
    
    // Parse guardian data
    final guardianData = json['guardian'] as Map<String, dynamic>?;
    
    // Parse documents data
    final documentsData = json['documents'] as Map<String, dynamic>?;
    
    // Parse program data
    final programData = json['program'] as Map<String, dynamic>?;
    
    // Parse date of birth
    DateTime? dateOfBirth;
    final dobString = personal['date_of_birth'] ?? json['date_of_birth'];
    if (dobString != null) {
      dateOfBirth = DateTime.tryParse(dobString.toString());
    }
    
    return StudentRegistration(
      id: json['id']?.toString(),
      registrationId: json['registration_id']?.toString(),
      programId: int.tryParse(json['program_id']?.toString() ?? ''),
      // Personal data
      fullName: personal['full_name'] ?? json['full_name'] ?? '',
      civilId: personal['civil_id'] ?? json['civil_id'],
      dateOfBirth: dateOfBirth,
      phone: personal['phone'] ?? json['phone'] ?? '',
      address: personal['address'] ?? json['address'],
      maritalStatus: personal['marital_status'] ?? json['marital_status'] ?? 'single',
      email: personal['email'] ?? json['email'],
      gender: personal['gender'] ?? json['gender'],
      // Academic data
      institution: academic['institution'] ?? json['university'] ?? json['institution'] ?? '',
      studentId: academic['student_id'] ?? json['student_id'] ?? '',
      college: academic['college'] ?? json['college'],
      major: academic['major'] ?? json['major'],
      program: academic['program'] ?? json['program'],
      academicYear: int.tryParse((academic['academic_year'] ?? json['academic_year'])?.toString() ?? ''),
      gpa: double.tryParse((academic['gpa'] ?? json['gpa'])?.toString() ?? ''),
      // Guardian data
      guardian: guardianData != null ? GuardianInfo.fromJson(guardianData) : null,
      // Documents data
      documents: documentsData != null ? DocumentsInfo.fromJson(documentsData) : null,
      // Program info
      programInfo: programData != null ? ProgramInfo.fromJson(programData) : null,
      // Status
      status: finalStatus,
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (registrationId != null) 'registration_id': registrationId,
      if (programId != null) 'program_id': programId,
      'personal': {
        'full_name': fullName,
        if (civilId != null) 'civil_id': civilId,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        'phone': phone,
        if (address != null) 'address': address,
        'marital_status': maritalStatus,
        if (email != null) 'email': email,
        if (gender != null) 'gender': gender,
      },
      'academic': {
        'institution': institution,
        'student_id': studentId,
        if (college != null) 'college': college,
        if (major != null) 'major': major,
        if (program != null) 'program': program,
        if (academicYear != null) 'academic_year': academicYear,
        if (gpa != null) 'gpa': gpa,
      },
      if (guardian != null) 'guardian': guardian!.toJson(),
      if (documents != null) 'documents': documents!.toJson(),
      if (programInfo != null) 'program': programInfo!.toJson(),
      'status': status,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// تحويل للصيغة المطلوبة لـ API
  Map<String, dynamic> toApiFormat() {
    return {
      if (programId != null) 'program_id': programId,
      'personal': {
        'full_name': fullName,
        if (civilId != null) 'civil_id': civilId,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        'phone': phone,
        if (address != null) 'address': address,
        'marital_status': maritalStatus,
        if (email != null && email!.isNotEmpty) 'email': email,
      },
      'academic': {
        'institution': institution,
        'student_id': studentId,
        if (college != null) 'college': college,
        if (major != null) 'major': major,
        if (program != null) 'program': program,
        if (academicYear != null) 'academic_year': academicYear,
        if (gpa != null) 'gpa': gpa,
      },
      if (guardian != null) 'guardian': guardian!.toJson(),
    };
  }

  StudentRegistration copyWith({
    String? id,
    String? registrationId,
    int? programId,
    String? fullName,
    String? civilId,
    DateTime? dateOfBirth,
    String? phone,
    String? address,
    String? maritalStatus,
    String? email,
    String? gender,
    String? institution,
    String? studentId,
    String? college,
    String? major,
    String? program,
    int? academicYear,
    double? gpa,
    GuardianInfo? guardian,
    DocumentsInfo? documents,
    ProgramInfo? programInfo,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentRegistration(
      id: id ?? this.id,
      registrationId: registrationId ?? this.registrationId,
      programId: programId ?? this.programId,
      fullName: fullName ?? this.fullName,
      civilId: civilId ?? this.civilId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      institution: institution ?? this.institution,
      studentId: studentId ?? this.studentId,
      college: college ?? this.college,
      major: major ?? this.major,
      program: program ?? this.program,
      academicYear: academicYear ?? this.academicYear,
      gpa: gpa ?? this.gpa,
      guardian: guardian ?? this.guardian,
      documents: documents ?? this.documents,
      programInfo: programInfo ?? this.programInfo,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'StudentRegistration(id: $id, registrationId: $registrationId, fullName: $fullName, studentId: $studentId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentRegistration && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
