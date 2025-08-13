import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  String _selectedFilter = 'الكل';
  final List<String> _filters = ['الكل', 'هذا الشهر', 'هذا العام', 'مهداة'];
  
  // Sample donation data
  final List<Map<String, dynamic>> _donations = [
    {
      'id': '1',
      'title': 'برنامج المنح الدراسية',
      'category': 'التعليم',
      'amount': 500.0,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'مكتمل',
      'type': 'عادي',
      'isAnonymous': false,
    },
    {
      'id': '2',
      'title': 'برنامج العلاج الطبي',
      'category': 'الصحة',
      'amount': 1000.0,
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'مكتمل',
      'type': 'إهداء',
      'isAnonymous': true,
    },
    {
      'id': '3',
      'title': 'برنامج كفالة الأيتام',
      'category': 'الأيتام',
      'amount': 750.0,
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'status': 'مكتمل',
      'type': 'عادي',
      'isAnonymous': false,
    },
    {
      'id': '4',
      'title': 'برنامج الإغاثة العاجلة',
      'category': 'الإغاثة',
      'amount': 300.0,
      'date': DateTime.now().subtract(const Duration(days: 15)),
      'status': 'مكتمل',
      'type': 'إهداء',
      'isAnonymous': false,
    },
    {
      'id': '5',
      'title': 'برنامج بناء المساجد',
      'category': 'المساجد',
      'amount': 2000.0,
      'date': DateTime.now().subtract(const Duration(days: 20)),
      'status': 'مكتمل',
      'type': 'عادي',
      'isAnonymous': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredDonations {
    if (_selectedFilter == 'الكل') {
      return _donations;
    } else if (_selectedFilter == 'هذا الشهر') {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      return _donations.where((donation) => 
        donation['date'].isAfter(startOfMonth)
      ).toList();
    } else if (_selectedFilter == 'هذا العام') {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      return _donations.where((donation) => 
        donation['date'].isAfter(startOfYear)
      ).toList();
    } else if (_selectedFilter == 'مهداة') {
      return _donations.where((donation) => 
        donation['type'] == 'إهداء'
      ).toList();
    }
    return _donations;
  }

  double get _totalAmount {
    return _filteredDonations.fold(0.0, (sum, donation) => sum + donation['amount']);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'اليوم';
    } else if (difference == 1) {
      return 'أمس';
    } else if (difference < 7) {
      return 'منذ $difference أيام';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return 'منذ $weeks أسابيع';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'التعليم':
        return Colors.blue;
      case 'الصحة':
        return Colors.green;
      case 'الإغاثة':
        return Colors.orange;
      case 'المساجد':
        return Colors.purple;
      case 'الأيتام':
        return Colors.pink;
      case 'المشاريع':
        return Colors.brown;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'التعليم':
        return Icons.school;
      case 'الصحة':
        return Icons.medical_services;
      case 'الإغاثة':
        return Icons.volunteer_activism;
      case 'المساجد':
        return Icons.mosque;
      case 'الأيتام':
        return Icons.family_restroom;
      case 'المشاريع':
        return Icons.construction;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تبرعاتي',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Header Section with Statistics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.softGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
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
                    Icons.history,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'إجمالي تبرعاتك',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_totalAmount.toStringAsFixed(0)} ريال',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'إجمالي التبرعات',
                      _filteredDonations.length.toString(),
                      Icons.favorite,
                    ),
                    _buildStatCard(
                      'التبرعات المهداة',
                      _filteredDonations.where((d) => d['type'] == 'إهداء').length.toString(),
                      Icons.card_giftcard,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تصفية التبرعات',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isSelected ? AppColors.surface : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Donations List
          Expanded(
            child: _filteredDonations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredDonations.length,
                    itemBuilder: (context, index) {
                      final donation = _filteredDonations[index];
                      return _buildDonationCard(donation);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.surface,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.surface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final categoryColor = _getCategoryColor(donation['category']);
    final categoryIcon = _getCategoryIcon(donation['category']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 20,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation['title'],
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        donation['category'],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: donation['type'] == 'إهداء' 
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    donation['type'],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: donation['type'] == 'إهداء' 
                          ? AppColors.primary
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${donation['amount'].toStringAsFixed(0)} ريال',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (donation['type'] == 'إهداء')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'مهداة',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(donation['date']),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تبرعات',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على تبرعات تطابق المعايير المحددة',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 