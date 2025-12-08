import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../utils/category_utils.dart';
import 'gift_donation_details_screen.dart';

class GiftDonationScreen extends StatefulWidget {
  final String? campaignId;
  final String? campaignTitle;
  final double? amount;

  const GiftDonationScreen({
    super.key,
    this.campaignId,
    this.campaignTitle,
    this.amount,
  });

  @override
  State<GiftDonationScreen> createState() => _GiftDonationScreenState();
}

class _GiftDonationScreenState extends State<GiftDonationScreen> {
  String? _selectedCategory;
  String? _selectedProgram;

  List<Map<String, dynamic>> get _categories {
    final currentLocale = context.locale.languageCode;
    final fallbackCategories = CategoryUtils.getLocalizedFallbackCategories();
    
    return fallbackCategories.map((category) => {
      'id': category['id'],
      'title': CategoryUtils.getCategoryName(
        nameAr: category['name_ar'],
        nameEn: category['name_en'],
        currentLocale: currentLocale,
      ),
      'icon': _getIconFromString(category['icon']),
      'color': _getColorFromString(category['color']),
    }).toList();
  }

  final List<Map<String, dynamic>> _programs = [
    {'id': '1', 'title': 'برنامج المنح الدراسية', 'category': '1'},
    {'id': '2', 'title': 'برنامج الكتب المدرسية', 'category': '1'},
    {'id': '3', 'title': 'برنامج العلاج الطبي', 'category': '2'},
    {'id': '4', 'title': 'برنامج الأدوية', 'category': '2'},
    {'id': '5', 'title': 'برنامج الإغاثة العاجلة', 'category': '3'},
    {'id': '6', 'title': 'برنامج الغذاء', 'category': '3'},
    {'id': '7', 'title': 'برنامج بناء المساجد', 'category': '4'},
    {'id': '8', 'title': 'برنامج صيانة المساجد', 'category': '4'},
    {'id': '9', 'title': 'برنامج كفالة الأيتام', 'category': '5'},
    {'id': '10', 'title': 'برنامج رعاية الأيتام', 'category': '5'},
    {'id': '11', 'title': 'برنامج المشاريع الصغيرة', 'category': '6'},
    {'id': '12', 'title': 'برنامج التدريب المهني', 'category': '6'},
  ];

  // Helper functions for icon and color conversion
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'computer':
        return Icons.computer;
      case 'assignment':
        return Icons.assignment;
      default:
        return Icons.category;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'primary':
        return AppColors.primary;
      case 'secondary':
        return AppColors.secondary;
      case 'accent':
        return AppColors.accent;
      case 'success':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  List<Map<String, dynamic>> get _filteredPrograms {
    if (_selectedCategory == null) return [];
    return _programs.where((program) => program['category'] == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
  }

  void _onContinue() {
    if (_selectedCategory == null || _selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_choose_category_program'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiftDonationDetailsScreen(
          categoryId: _selectedCategory!,
          categoryTitle: _categories.firstWhere((cat) => cat['id'] == _selectedCategory)['title'],
          programId: _selectedProgram,
          programTitle: _programs.firstWhere((prog) => prog['id'] == _selectedProgram)['title'],
          amount: widget.amount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'gift_donation'.tr(),
          style: AppTextStyles.appBarTitleLight,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.softGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'إهداء التبرع',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر الفئة والبرنامج المراد التبرع له',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category Selection
            _buildSectionTitle('اختر الفئة'),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['id'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['id'];
                      _selectedProgram = null;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? category['color'].withOpacity(0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? category['color'] : AppColors.surfaceVariant,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? category['color'].withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? category['color'] : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            category['icon'],
                            size: 24,
                            color: isSelected ? Colors.white : category['color'],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['title'],
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isSelected ? category['color'] : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Program Selection
            if (_selectedCategory != null) ...[
              _buildSectionTitle('اختر البرنامج'),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredPrograms.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: AppColors.surfaceVariant,
                  ),
                  itemBuilder: (context, index) {
                    final program = _filteredPrograms[index];
                    final isSelected = _selectedProgram == program['id'];
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.work_outline,
                          size: 20,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      title: Text(
                        program['title'],
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 24,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedProgram = program['id'];
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward_ios, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'التالي',
                      style: AppTextStyles.buttonLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }
} 