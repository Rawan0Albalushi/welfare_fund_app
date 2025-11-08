class Campaign {
  final String id;
  final String title;
  final String titleAr;
  final String titleEn;
  final String description;
  final String descriptionAr;
  final String descriptionEn;
  final String imageUrl;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String category;
  final String? impactDescription;
  final String? impactDescriptionAr;
  final String? impactDescriptionEn;
  final int donorCount;
  final String? type; // 'student_program' or 'charity_campaign'
  final bool? isUrgentFlag; // For urgent campaigns (renamed to avoid conflict)
  final bool? isFeatured; // For featured campaigns

  Campaign({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.titleEn,
    required this.description,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.imageUrl,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.category,
    this.impactDescription,
    this.impactDescriptionAr,
    this.impactDescriptionEn,
    required this.donorCount,
    this.type,
    this.isUrgentFlag,
    this.isFeatured,
  });

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    final ratio = currentAmount / targetAmount;
    if (ratio.isNaN || ratio.isInfinite) return 0;
    return ratio.clamp(0.0, 1.0).toDouble();
  }

  int get remainingDays {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  bool get isUrgent {
    // If explicitly set as urgent, return true
    if (isUrgentFlag == true) return true;
    // Otherwise, check if remaining days <= 7
    return remainingDays <= 7;
  }

  bool get isCompleted {
    return progressPercentage >= 1;
  }

  // Helper methods to get localized content
  String getLocalizedTitle(String locale) {
    if (locale == 'ar') {
      return titleAr.isNotEmpty ? titleAr : title;
    } else {
      return titleEn.isNotEmpty ? titleEn : title;
    }
  }

  String getLocalizedDescription(String locale) {
    if (locale == 'ar') {
      return descriptionAr.isNotEmpty ? descriptionAr : description;
    } else {
      return descriptionEn.isNotEmpty ? descriptionEn : description;
    }
  }

  String? getLocalizedImpactDescription(String locale) {
    if (impactDescriptionAr == null && impactDescriptionEn == null) {
      return impactDescription;
    }
    
    if (locale == 'ar') {
      return impactDescriptionAr?.isNotEmpty == true ? impactDescriptionAr : impactDescriptionEn;
    } else {
      return impactDescriptionEn?.isNotEmpty == true ? impactDescriptionEn : impactDescriptionAr;
    }
  }

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? json['title_ar'] ?? json['title_en'] ?? '',
      titleAr: json['title_ar'] ?? json['title'] ?? '',
      titleEn: json['title_en'] ?? json['title'] ?? '',
      description: json['description'] ?? json['description_ar'] ?? json['description_en'] ?? '',
      descriptionAr: json['description_ar'] ?? json['description'] ?? '',
      descriptionEn: json['description_en'] ?? json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? json['image'] ?? '',
      targetAmount: (json['targetAmount'] ?? json['goal_amount'] ?? json['target_amount'] ?? 0).toDouble(),
      currentAmount: (json['currentAmount'] ?? json['raised_amount'] ?? json['current_amount'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? json['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
      isActive: json['isActive'] ?? json['status'] == 'active' ?? true,
      category: json['category']?['name'] ?? json['category_name'] ?? json['category'] ?? '',
      impactDescription: json['impact_description'] as String?,
      impactDescriptionAr: json['impact_description_ar'] as String?,
      impactDescriptionEn: json['impact_description_en'] as String?,
      donorCount: json['donorCount'] ?? json['donor_count'] ?? json['donors_count'] ?? 0,
      type: json['type'] as String?,
      isUrgentFlag: json['isUrgentFlag'] ?? json['is_urgent'] as bool?,
      isFeatured: json['isFeatured'] ?? json['is_featured'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_ar': titleAr,
      'title_en': titleEn,
      'description': description,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'imageUrl': imageUrl,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'category': category,
      'impact_description': impactDescription,
      'impact_description_ar': impactDescriptionAr,
      'impact_description_en': impactDescriptionEn,
      'donorCount': donorCount,
      'type': type,
      'isUrgentFlag': isUrgentFlag,
      'isFeatured': isFeatured,
    };
  }

  Campaign copyWith({
    String? id,
    String? title,
    String? titleAr,
    String? titleEn,
    String? description,
    String? descriptionAr,
    String? descriptionEn,
    String? imageUrl,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? category,
    String? impactDescription,
    String? impactDescriptionAr,
    String? impactDescriptionEn,
    int? donorCount,
    String? type,
    bool? isUrgentFlag,
    bool? isFeatured,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      imageUrl: imageUrl ?? this.imageUrl,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      impactDescription: impactDescription ?? this.impactDescription,
      impactDescriptionAr: impactDescriptionAr ?? this.impactDescriptionAr,
      impactDescriptionEn: impactDescriptionEn ?? this.impactDescriptionEn,
      donorCount: donorCount ?? this.donorCount,
      type: type ?? this.type,
      isUrgentFlag: isUrgentFlag ?? this.isUrgentFlag,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
} 