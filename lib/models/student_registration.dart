class StudentRegistration {
  final String? id;
  final String fullName;
  final String studentId;
  final String phone;
  final String university;
  final String college;
  final String major;
  final String academicYear;
  final double gpa;
  final String gender;
  final String maritalStatus;
  final String incomeLevel;
  final String familySize;
  final String? email;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? financialNeed;
  final String? previousSupport;
  final String? idCardImagePath;
  final String? transcriptPath;
  final String? incomeCertificatePath;
  final String? familyCardPath;
  final String? otherDocumentsPath;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentRegistration({
    this.id,
    required this.fullName,
    required this.studentId,
    required this.phone,
    required this.university,
    required this.college,
    required this.major,
    required this.academicYear,
    required this.gpa,
    required this.gender,
    required this.maritalStatus,
    required this.incomeLevel,
    required this.familySize,
    this.email,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    this.financialNeed,
    this.previousSupport,
    this.idCardImagePath,
    this.transcriptPath,
    this.incomeCertificatePath,
    this.familyCardPath,
    this.otherDocumentsPath,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory StudentRegistration.fromJson(Map<String, dynamic> json) {
    // Normalize status
    String rawStatus = json['status']?.toString() ?? 'pending';
    String normalizedStatus = rawStatus.toLowerCase();
    
    // Normalize status values
    String finalStatus;
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        finalStatus = 'pending';
        break;
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        finalStatus = 'under_review';
        break;
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        finalStatus = 'approved';
        break;
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        finalStatus = 'rejected';
        break;
      default:
        print('Warning: Unknown status in StudentRegistration.fromJson: $rawStatus, defaulting to pending');
        finalStatus = 'pending';
    }
    
    return StudentRegistration(
      id: json['id']?.toString(),
      fullName: json['full_name'] ?? '',
      studentId: json['student_id'] ?? '',
      phone: json['phone'] ?? '',
      university: json['university'] ?? '',
      college: json['college'] ?? '',
      major: json['major'] ?? '',
      academicYear: json['academic_year'] ?? '',
      gpa: double.tryParse(json['gpa']?.toString() ?? '0') ?? 0.0,
      gender: json['gender'] ?? '',
      maritalStatus: json['marital_status'] ?? '',
      incomeLevel: json['income_level'] ?? '',
      familySize: json['family_size'] ?? '',
      email: json['email'],
      address: json['address'],
      emergencyContact: json['emergency_contact'],
      emergencyPhone: json['emergency_phone'],
      financialNeed: json['financial_need'],
      previousSupport: json['previous_support'],
      idCardImagePath: json['id_card_image_path'],
      transcriptPath: json['transcript_path'],
      incomeCertificatePath: json['income_certificate_path'],
      familyCardPath: json['family_card_path'],
      otherDocumentsPath: json['other_documents_path'],
      status: finalStatus,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'student_id': studentId,
      'phone': phone,
      'university': university,
      'college': college,
      'major': major,
      'academic_year': academicYear,
      'gpa': gpa.toString(),
      'gender': gender,
      'marital_status': maritalStatus,
      'income_level': incomeLevel,
      'family_size': familySize,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
      if (emergencyPhone != null) 'emergency_phone': emergencyPhone,
      if (financialNeed != null) 'financial_need': financialNeed,
      if (previousSupport != null) 'previous_support': previousSupport,
      if (idCardImagePath != null) 'id_card_image_path': idCardImagePath,
      if (transcriptPath != null) 'transcript_path': transcriptPath,
      if (incomeCertificatePath != null) 'income_certificate_path': incomeCertificatePath,
      if (familyCardPath != null) 'family_card_path': familyCardPath,
      if (otherDocumentsPath != null) 'other_documents_path': otherDocumentsPath,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  StudentRegistration copyWith({
    String? id,
    String? fullName,
    String? studentId,
    String? phone,
    String? university,
    String? college,
    String? major,
    String? academicYear,
    double? gpa,
    String? gender,
    String? maritalStatus,
    String? incomeLevel,
    String? familySize,
    String? email,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    String? financialNeed,
    String? previousSupport,
    String? idCardImagePath,
    String? transcriptPath,
    String? incomeCertificatePath,
    String? familyCardPath,
    String? otherDocumentsPath,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentRegistration(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      phone: phone ?? this.phone,
      university: university ?? this.university,
      college: college ?? this.college,
      major: major ?? this.major,
      academicYear: academicYear ?? this.academicYear,
      gpa: gpa ?? this.gpa,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      incomeLevel: incomeLevel ?? this.incomeLevel,
      familySize: familySize ?? this.familySize,
      email: email ?? this.email,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      financialNeed: financialNeed ?? this.financialNeed,
      previousSupport: previousSupport ?? this.previousSupport,
      idCardImagePath: idCardImagePath ?? this.idCardImagePath,
      transcriptPath: transcriptPath ?? this.transcriptPath,
      incomeCertificatePath: incomeCertificatePath ?? this.incomeCertificatePath,
      familyCardPath: familyCardPath ?? this.familyCardPath,
      otherDocumentsPath: otherDocumentsPath ?? this.otherDocumentsPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'StudentRegistration(id: $id, fullName: $fullName, studentId: $studentId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentRegistration && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
