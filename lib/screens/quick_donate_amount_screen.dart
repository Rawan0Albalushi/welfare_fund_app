import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../services/campaign_service.dart';
import 'quick_donate_payment_screen.dart';

class QuickDonateAmountScreen extends StatefulWidget {
  const QuickDonateAmountScreen({super.key});

  @override
  State<QuickDonateAmountScreen> createState() => _QuickDonateAmountScreenState();
}

class _QuickDonateAmountScreenState extends State<QuickDonateAmountScreen> {
  double _selectedAmount = 50.0;
  final TextEditingController _customAmountController = TextEditingController();
  bool _isCustomAmount = false;
  String? _selectedCategory;

  List<double> _presetAmounts = [25.0, 50.0, 100.0, 200.0, 500.0, 1000.0];
  List<Map<String, dynamic>> _categories = [];
  final CampaignService _campaignService = CampaignService();

  // Fallback categories if API fails
  List<Map<String, dynamic>> get _fallbackCategories => [
    {
      'id': '1',
      'title': 'فرص تعليمية',
      'description': 'مساعدة الطلاب في التعليم',
      'icon': Icons.school,
      'color': AppColors.primary,
    },
    {
      'id': '2',
      'title': 'السكن والنقل',
      'description': 'مساعدة في السكن والنقل',
      'icon': Icons.home,
      'color': AppColors.secondary,
    },
    {
      'id': '3',
      'title': 'شراء الأجهزة',
      'description': 'مساعدة في شراء الأجهزة',
      'icon': Icons.computer,
      'color': AppColors.accent,
    },
    {
      'id': '4',
      'title': 'الامتحانات',
      'description': 'مساعدة في الامتحانات',
      'icon': Icons.assignment,
      'color': AppColors.success,
    },
  ];

  @override
  void initState() {
    super.initState();
    _customAmountController.text = _selectedAmount.toString();
    // Initialize with fallback categories first
    _categories = _fallbackCategories;
    print('QuickDonate: Initialized with ${_categories.length} fallback categories');
    _loadDataFromAPI();
  }

  Future<void> _loadDataFromAPI() async {
    try {
      // Load campaigns from API and group by category
      try {
        final campaigns = await _campaignService.getCharityCampaigns();
        if (campaigns.isNotEmpty) {
          // Group campaigns by category
          final Map<String, List<Map<String, dynamic>>> groupedCampaigns = {};
          
          for (var campaign in campaigns) {
            final categoryName = campaign.category;
            if (!groupedCampaigns.containsKey(categoryName)) {
              groupedCampaigns[categoryName] = [];
            }
            groupedCampaigns[categoryName]!.add({
              'id': campaign.id,
              'title': campaign.title,
              'description': campaign.description,
              'category': campaign.category,
            });
          }
          
          // Create categories from grouped campaigns
          final categoriesWithCampaigns = <Map<String, dynamic>>[];
          groupedCampaigns.forEach((categoryName, campaignList) {
            categoriesWithCampaigns.add({
              'id': categoryName,
              'title': categoryName,
              'description': '${campaignList.length} حملة متاحة',
              'icon': _getCategoryIcon(categoryName),
              'color': _getCategoryColor(categoryName),
              'campaigns': campaignList,
              'campaign_count': campaignList.length,
            });
          });
          
          setState(() {
            _categories = categoriesWithCampaigns;
          });
          
          print('QuickDonate: Successfully loaded ${campaigns.length} campaigns grouped into ${categoriesWithCampaigns.length} categories');
        } else {
          print('QuickDonate: No campaigns from API, keeping fallback categories');
        }
      } catch (error) {
        print('QuickDonate: Error loading campaigns, keeping fallback: $error');
        // Keep the fallback categories that were already set in initState
      }

      // Load quick amounts from API
      try {
        final amounts = await _campaignService.getQuickDonationAmounts();
        setState(() {
          _presetAmounts = amounts;
          // Amounts loaded
        });
        print('QuickDonate: Successfully loaded ${amounts.length} quick amounts from API');
      } catch (error) {
        print('QuickDonate: Error loading quick amounts, using fallback: $error');
        setState(() {
          // Amounts loaded
        });
      }
    } catch (error) {
      print('QuickDonate: Error loading data from API: $error');
      setState(() {
        _categories = _fallbackCategories;
        // Error handling completed
      });
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _onAmountSelected(double amount) {
    setState(() {
      _selectedAmount = amount;
      _isCustomAmount = false;
      _customAmountController.text = amount.toString();
    });
  }

  void _onCustomAmountChanged(String value) {
    if (value.isNotEmpty) {
      setState(() {
        _selectedAmount = double.tryParse(value) ?? 0.0;
        _isCustomAmount = true;
      });
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
  }

  void _onContinue() {
    if (_selectedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_enter_valid_amount'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_choose_donation_category'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickDonatePaymentScreen(
          amount: _selectedAmount,
          selectedCategory: _selectedCategory,
          categories: _categories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'quick_donation'.tr(),
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.largePadding),
              decoration: BoxDecoration(
                gradient: AppColors.modernGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.surface,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'choose_donation_amount'.tr(),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'every_riyal_helps'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Preset Amounts Section
            Text(
              'suggested_amounts'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Preset Amounts Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _presetAmounts.length,
              itemBuilder: (context, index) {
                final amount = _presetAmounts[index];
                final isSelected = _selectedAmount == amount && !_isCustomAmount;
                
                return GestureDetector(
                  onTap: () => _onAmountSelected(amount),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : AppColors.textPrimary.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.textPrimary.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          amount.toStringAsFixed(0),
                          style: AppTextStyles.titleLarge.copyWith(
                            color: isSelected ? AppColors.surface : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'riyal'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected 
                                ? AppColors.surface.withOpacity(0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Custom Amount Section
            Text(
              'or_enter_custom_amount'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isCustomAmount 
                      ? AppColors.primary 
                      : AppColors.textPrimary.withOpacity(0.1),
                  width: _isCustomAmount ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _customAmountController,
                onChanged: _onCustomAmountChanged,
                keyboardType: TextInputType.number,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'enter_amount'.tr(),
                  hintStyle: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  suffixText: 'riyal'.tr(),
                  suffixStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppConstants.largePadding),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Selected Amount Display
            if (_selectedAmount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.largePadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'selected_amount'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.extraLargePadding),
            ],

            // Categories Section
            Text(
              'choose_donation_category'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Categories Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: _categories.map((category) => _buildCategoryCard(
                category: category,
                isSelected: _selectedCategory == category['id'],
                onTap: () => _onCategorySelected(category['id']),
              )).toList(),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Note about automatic allocation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.largePadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'important_note'.tr(),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'donation_redirect_note'.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_selectedAmount > 0 && _selectedCategory != null) 
                    ? _onContinue 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedAmount > 0 && _selectedCategory != null)
                      ? AppColors.primary
                      : AppColors.textSecondary.withOpacity(0.3),
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_forward_ios, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      (_selectedAmount > 0 && _selectedCategory != null)
                          ? 'proceed_to_payment'.tr()
                          : 'choose_amount_category'.tr(),
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required Map<String, dynamic> category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = category['color'] as Color;
    final icon = category['icon'] as IconData;
    final title = category['title'] as String;
    final description = category['description'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? color.withOpacity(0.2)
                  : color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
                 child: Padding(
           padding: const EdgeInsets.all(10),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Container(
                 padding: const EdgeInsets.all(6),
                 decoration: BoxDecoration(
                   color: isSelected 
                       ? color.withOpacity(0.2)
                       : color.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Icon(
                   icon,
                   color: color,
                   size: 18,
                 ),
               ),
               const SizedBox(height: 6),
               Text(
                 title,
                 style: AppTextStyles.titleSmall.copyWith(
                   color: AppColors.textPrimary,
                   fontWeight: FontWeight.w600,
                   fontSize: 12,
                 ),
                 textAlign: TextAlign.center,
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
               const SizedBox(height: 2),
               Text(
                 description,
                 style: AppTextStyles.bodySmall.copyWith(
                   color: AppColors.textSecondary,
                   height: 1.0,
                   fontSize: 9,
                 ),
                 textAlign: TextAlign.center,
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
               ),
               
             ],
           ),
         ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'تعليم':
      case 'education':
        return Icons.school;
      case 'سكن':
      case 'housing':
        return Icons.home;
      case 'أجهزة':
      case 'devices':
        return Icons.computer;
      case 'امتحانات':
      case 'exams':
        return Icons.assignment;
      case 'صحة':
      case 'health':
        return Icons.health_and_safety;
      case 'طعام':
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'تعليم':
      case 'education':
        return AppColors.primary;
      case 'سكن':
      case 'housing':
        return AppColors.secondary;
      case 'أجهزة':
      case 'devices':
        return AppColors.accent;
      case 'امتحانات':
      case 'exams':
        return AppColors.success;
      case 'صحة':
      case 'health':
        return Colors.red;
      case 'طعام':
      case 'food':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
} 