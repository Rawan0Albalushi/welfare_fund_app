import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/donation.dart';
import '../services/donation_service.dart';

class MyDonationsScreen extends StatefulWidget {
  final bool forceRefresh;
  
  const MyDonationsScreen({super.key, this.forceRefresh = false});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> with WidgetsBindingObserver {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'this_month', 'this_year', 'gift', 'completed', 'pending', 'cancelled', 'failed'];
  
  final DonationService _donationService = DonationService();
  List<Donation> _donations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.forceRefresh) {
      // Force refresh if coming from donation success screen
      _loadDonations();
    } else {
      _checkAuthAndLoadDonations();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _loadDonations();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible again
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadDonations();
    }
  }

  Future<void> _checkAuthAndLoadDonations() async {
    try {
      // Check if user is authenticated first
      final isAuthenticated = await _donationService.apiClient.isAuthenticated();
      print('MyDonationsScreen: User authenticated: $isAuthenticated');
      
      if (!isAuthenticated) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'يجب تسجيل الدخول أولاً لعرض التبرعات';
        });
        return;
      }
      
      await _loadDonations();
    } catch (e) {
      print('MyDonationsScreen: Auth check error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في التحقق من تسجيل الدخول: $e';
      });
    }
  }

  Future<void> _loadDonations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('MyDonationsScreen: Starting to load all donations...');
      final donations = await _donationService.getAllUserDonations();
      print('MyDonationsScreen: Loaded ${donations.length} total donations');
      
      setState(() {
        _donations = donations;
        _isLoading = false;
      });
      
      // Show success message if donations were loaded successfully
      if (donations.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'all_donations_loaded'.tr()} (${donations.length} ${'donation'.tr()})'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (donations.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('no_donations_found'.tr()),
            backgroundColor: AppColors.info,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('MyDonationsScreen: Error loading donations: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _createTestDonation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('MyDonationsScreen: Creating test donation...');
      
      // Create a test donation using the existing API
      final origin = Uri.base.origin;
      final result = await _donationService.createDonationWithPayment(
        itemId: '1', // Use campaign ID 1
        itemType: 'campaign',
        amount: 10.0, // 10 OMR
        donorName: 'Test User',
        message: 'تبرع تجريبي للاختبار',
        isAnonymous: false,
        returnOrigin: origin,
      );
      
      print('MyDonationsScreen: Test donation created: $result');
      
      // Reload donations after creating test donation
      await _loadDonations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('test_donation_created'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('MyDonationsScreen: Error creating test donation: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في إنشاء التبرع التجريبي: $e';
      });
    }
  }

  Future<void> _testAllEndpoints() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('MyDonationsScreen: Testing all donation endpoints...');
      
      // Test all endpoints
      await _donationService.testAllEndpoints();
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('all_apis_tested'.tr()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      print('MyDonationsScreen: Error testing endpoints: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'error_occurred'.tr();
      });
    }
  }

  Future<void> _checkLastDonation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('MyDonationsScreen: Checking last donation...');
      
      // Get all donations first
      final donations = await _donationService.getUserDonations();
      
      if (donations.isNotEmpty) {
        final lastDonation = donations.first;
        print('MyDonationsScreen: Last donation ID: ${lastDonation.id}');
        print('MyDonationsScreen: Last donation status: ${lastDonation.status}');
        
        // Check donation status in detail
        final status = await _donationService.checkDonationStatus(lastDonation.id);
        print('MyDonationsScreen: Detailed donation status: $status');
        
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('last_donation'.tr() + ': ${lastDonation.status}'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('no_data'.tr()),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      print('MyDonationsScreen: Error checking last donation: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في فحص آخر تبرع: $e';
      });
    }
  }

  List<Donation> get _filteredDonations {
    print('MyDonationsScreen: Filtering donations with filter: $_selectedFilter');
    print('MyDonationsScreen: Total donations: ${_donations.length}');
    
    if (_selectedFilter == 'الكل') {
      print('MyDonationsScreen: Returning all donations: ${_donations.length}');
      return _donations;
    } else if (_selectedFilter == 'هذا الشهر') {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final filtered = _donations.where((donation) => 
        donation.date.isAfter(startOfMonth)
      ).toList();
      print('MyDonationsScreen: This month donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'هذا العام') {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final filtered = _donations.where((donation) => 
        donation.date.isAfter(startOfYear)
      ).toList();
      print('MyDonationsScreen: This year donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'مهداة') {
      final filtered = _donations.where((donation) => 
        donation.message?.contains('هدية') == true || 
        donation.message?.contains('إهداء') == true ||
        donation.message?.contains('gift') == true
      ).toList();
      print('MyDonationsScreen: Gift donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'مكتمل') {
      final filtered = _donations.where((donation) => 
        donation.isPaid || donation.isCompleted
      ).toList();
      print('MyDonationsScreen: Completed donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'في الانتظار') {
      final filtered = _donations.where((donation) => 
        donation.isPending
      ).toList();
      print('MyDonationsScreen: Pending donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'ملغي') {
      final filtered = _donations.where((donation) => 
        donation.isCancelled
      ).toList();
      print('MyDonationsScreen: Cancelled donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'فشل') {
      final filtered = _donations.where((donation) => 
        donation.isFailed
      ).toList();
      print('MyDonationsScreen: Failed donations: ${filtered.length}');
      return filtered;
    }
    print('MyDonationsScreen: Default return all donations: ${_donations.length}');
    return _donations;
  }

  double get _totalAmount {
    return _filteredDonations.fold(0.0, (sum, donation) => sum + donation.amount);
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
      case 'برنامج':
        return Colors.blue;
      case 'حملة':
        return Colors.green;
      case 'عام':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'برنامج':
        return Icons.school;
      case 'حملة':
        return Icons.campaign;
      case 'عام':
        return Icons.favorite;
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
          'my_donations'.tr(),
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [],
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
                  'total_donated'.tr(),
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
                      'total_donated'.tr(),
                      _filteredDonations.length.toString(),
                      Icons.favorite,
                    ),
                    _buildStatCard(
                      'gift_donation'.tr(),
                      _filteredDonations.where((d) => 
                        d.message?.contains('هدية') == true || 
                        d.message?.contains('إهداء') == true ||
                        d.message?.contains('gift') == true
                      ).length.toString(),
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
                              filter.tr(),
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
            child: _buildDonationsContent(),
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

  Widget _buildDonationsContent() {
    print('MyDonationsScreen: Building donations content...');
    print('MyDonationsScreen: _isLoading: $_isLoading');
    print('MyDonationsScreen: _errorMessage: $_errorMessage');
    print('MyDonationsScreen: _donations.length: ${_donations.length}');
    print('MyDonationsScreen: _filteredDonations.length: ${_filteredDonations.length}');
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل جميع التبرعات...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى الانتظار، قد يستغرق هذا بعض الوقت',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              'error_occurred'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _checkAuthAndLoadDonations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                  child: Text('retry'.tr()),
                ),
                ElevatedButton(
                  onPressed: _createTestDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.surface,
                  ),
                  child: Text('create_test_donation'.tr()),
                ),
                ElevatedButton(
                  onPressed: _testAllEndpoints,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.surface,
                  ),
                  child: Text('test_apis'.tr()),
                ),
                ElevatedButton(
                  onPressed: _checkLastDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: AppColors.surface,
                  ),
                  child: Text('check_last_donation'.tr()),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_filteredDonations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _checkAuthAndLoadDonations,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredDonations.length,
        itemBuilder: (context, index) {
          final donation = _filteredDonations[index];
          return _buildDonationCard(donation);
        },
      ),
    );
  }

  // Get donation status information with color and icon
  Map<String, dynamic> _getDonationStatusInfo(Donation donation) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (donation.isPaid || donation.isCompleted) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
      statusText = 'مكتمل';
    } else if (donation.isPending) {
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
      statusText = 'في الانتظار';
    } else if (donation.isCancelled) {
      statusColor = AppColors.textSecondary;
      statusIcon = Icons.cancel;
      statusText = 'cancelled'.tr();
    } else if (donation.isFailed) {
      statusColor = AppColors.error;
      statusIcon = Icons.error;
      statusText = 'failed'.tr();
    } else if (donation.isExpired) {
      statusColor = AppColors.textTertiary;
      statusIcon = Icons.timer_off;
      statusText = 'expired'.tr();
    } else {
      statusColor = AppColors.info;
      statusIcon = Icons.help_outline;
      statusText = donation.status;
    }
    
    return {
      'color': statusColor,
      'icon': statusIcon,
      'text': statusText,
    };
  }

  Widget _buildDonationCard(Donation donation) {
    // Determine category based on program/campaign or message
    String category = 'general';
    if (donation.programId != null) {
      category = 'program';
    } else if (donation.campaignId != null) {
      category = 'campaign';
    }
    
    final categoryColor = _getCategoryColor(category);
    final categoryIcon = _getCategoryIcon(category);
    
    // Determine if it's a gift donation
    final isGift = donation.message?.contains('هدية') == true || 
                   donation.message?.contains('إهداء') == true ||
                   donation.message?.contains('gift') == true;
    
    // Get donation status info
    final statusInfo = _getDonationStatusInfo(donation);
    
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
                        donation.message ?? 'تبرع',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (donation.programName != null || donation.campaignName != null)
                        Text(
                          donation.programName ?? donation.campaignName ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        category,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Donation Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGift 
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isGift ? 'إهداء' : 'عادي',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isGift 
                              ? AppColors.primary
                              : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusInfo['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusInfo['icon'],
                            size: 12,
                            color: statusInfo['color'],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusInfo['text'],
                            style: AppTextStyles.bodySmall.copyWith(
                              color: statusInfo['color'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${donation.amount.toStringAsFixed(0)} ريال',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (donation.paidAmount != null && donation.paidAmount != donation.amount)
                      Text(
                        'مدفوع: ${donation.paidAmount!.toStringAsFixed(0)} ريال',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (isGift)
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
                      _formatDate(donation.date),
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
        ],
      ),
    );
  }
} 