import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../models/donation.dart';
import '../services/donation_service.dart';
import '../providers/auth_provider.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class MyDonationsScreen extends StatefulWidget {
  final bool forceRefresh;
  
  const MyDonationsScreen({super.key, this.forceRefresh = false});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'this_month', 'this_year', 'completed', 'pending', 'cancelled', 'failed'];
  
  final DonationService _donationService = DonationService();
  List<Donation> _donations = [];
  bool _isLoading = true; // Auto loading enabled
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Always load donations when opening the page
    _checkAuthAndLoadDonations();
  }

  @override
  void didUpdateWidget(MyDonationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if forceRefresh changed or widget was updated
    if (widget.forceRefresh != oldWidget.forceRefresh || widget.forceRefresh) {
      _checkAuthAndLoadDonations();
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
          _errorMessage = 'must_login_first_to_view_donations'.tr();
        });
        return;
      }
      
      await _loadDonations();
    } catch (e) {
      print('MyDonationsScreen: Auth check error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '${'error_checking_login'.tr()}: $e';
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
        message: 'test_donation_for_testing'.tr(),
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
        _errorMessage = '${'error_creating_test_donation'.tr()}: $e';
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
        _errorMessage = '${'error_checking_last_donation'.tr()}: $e';
      });
    }
  }

  List<Donation> get _filteredDonations {
    print('MyDonationsScreen: Filtering donations with filter: $_selectedFilter');
    print('MyDonationsScreen: Total donations: ${_donations.length}');
    
    if (_selectedFilter == 'all') {
      print('MyDonationsScreen: Returning all donations: ${_donations.length}');
      return _donations;
    } else if (_selectedFilter == 'this_month') {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final filtered = _donations.where((donation) => 
        donation.date.isAfter(startOfMonth)
      ).toList();
      print('MyDonationsScreen: This month donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'this_year') {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final filtered = _donations.where((donation) => 
        donation.date.isAfter(startOfYear)
      ).toList();
      print('MyDonationsScreen: This year donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'completed') {
      final filtered = _donations.where((donation) => 
        donation.isPaid || donation.isCompleted
      ).toList();
      print('MyDonationsScreen: Completed donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'pending') {
      final filtered = _donations.where((donation) => 
        donation.isPending
      ).toList();
      print('MyDonationsScreen: Pending donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'cancelled') {
      final filtered = _donations.where((donation) => 
        donation.isCancelled
      ).toList();
      print('MyDonationsScreen: Cancelled donations: ${filtered.length}');
      return filtered;
    } else if (_selectedFilter == 'failed') {
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
    // حساب إجمالي التبرعات الناجحة فقط
    return _filteredDonations
        .where((donation) => donation.isPaid || donation.isCompleted)
        .fold(0.0, (sum, donation) => sum + donation.amount);
  }

  int get _successfulDonationsCount {
    // حساب عدد التبرعات الناجحة فقط
    return _filteredDonations
        .where((donation) => donation.isPaid || donation.isCompleted)
        .length;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'today_date'.tr();
    } else if (difference == 1) {
      return 'yesterday_date'.tr();
    } else if (difference < 7) {
      return '$difference ${difference == 1 ? 'day_ago'.tr() : 'days_ago'.tr()}';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks ${weeks == 1 ? 'week_ago'.tr() : 'weeks_ago'.tr()}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _onBottomNavigationTap(int index, bool isAuthenticated) {
    if (index == 1) {
      // Already on My Donations page - refresh data
      _checkAuthAndLoadDonations();
      return;
    }

    if (index == 0) {
      // Navigate to Home - pop if possible, otherwise navigate
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == AppConstants.homeRoute);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
      return;
    }

    if (index == 2) {
      // Navigate to Settings
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
    }
  }

  String _getFilterTranslation(String filter) {
    switch (filter) {
      case 'all':
        return 'all'.tr();
      case 'this_month':
        return 'this_month'.tr();
      case 'this_year':
        return 'this_year'.tr();
      case 'completed':
        return 'completed'.tr();
      case 'pending':
        return 'pending'.tr();
      case 'cancelled':
        return 'cancelled'.tr();
      case 'failed':
        return 'failed'.tr();
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppColors.surface),
            title: Text(
              'my_donations'.tr(),
              style: AppTextStyles.appBarTitleDark,
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.modernGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
            actions: [
              // Only show refresh icon when there are donations
              if (_donations.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.surface,
                    size: 22,
                  ),
                  onPressed: _checkAuthAndLoadDonations,
                ),
            ],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.surface, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              // Simplified Header Section with Gradient
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.modernGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'total_donations'.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.surface.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_totalAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'number_of_donations'.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.surface.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _successfulDonationsCount.toString(),
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Simplified Filter Section
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getFilterTranslation(filter),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isSelected ? AppColors.surface : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Donations List
              Expanded(
                child: _buildDonationsContent(),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 1,
            onTap: (index) => _onBottomNavigationTap(index, isAuthenticated),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'home'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history),
                label: 'my_donations'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: 'settings'.tr(),
              ),
            ],
          ),
        );
      },
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
              'loading_donations'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Show welcome message when no donations are loaded yet
    if (_donations.isEmpty && !_isLoading && _errorMessage == null) {
      return _buildWelcomeState();
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      statusText = 'completed_status'.tr();
    } else if (donation.isPending) {
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
      statusText = 'pending_status'.tr();
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

  void _showDonationDetails(Donation donation) {
    final statusInfo = _getDonationStatusInfo(donation);
    final isGift = donation.message?.contains('هدية') == true || 
                   donation.message?.contains('إهداء') == true ||
                   donation.message?.contains('gift') == true;
    
    // Determine category
    String category = 'general'.tr();
    if (donation.programId != null) {
      category = 'program'.tr();
    } else if (donation.campaignId != null) {
      category = 'campaign'.tr();
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'donation_details_title'.tr(),
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.modernGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'donation_amount_label'.tr(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.surface.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${donation.amount.toStringAsFixed(0)} ${'omani_riyal'.tr()}',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (donation.paidAmount != null && donation.paidAmount != donation.amount) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${'paid_amount'.tr()}: ${donation.paidAmount!.toStringAsFixed(0)} ${'riyal'.tr()}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.surface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Status
                    _buildDetailRow(
                      icon: statusInfo['icon'],
                      iconColor: statusInfo['color'],
                      label: 'status_label'.tr(),
                      value: statusInfo['text'],
                      valueColor: statusInfo['color'],
                    ),
                    const SizedBox(height: 16),
                    // Date
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      iconColor: AppColors.textSecondary,
                      label: 'donation_date_label'.tr(),
                      value: '${donation.date.day}/${donation.date.month}/${donation.date.year}',
                    ),
                    const SizedBox(height: 16),
                    // Category
                    if (category != 'general'.tr())
                      _buildDetailRow(
                        icon: category == 'program'.tr() ? Icons.school : Icons.campaign,
                        iconColor: AppColors.primary,
                        label: 'type_label'.tr(),
                        value: category,
                      ),
                    if (category != 'general'.tr()) const SizedBox(height: 16),
                    // Program/Campaign Name
                    if (donation.programName != null || donation.campaignName != null || donation.campaignNameEn != null)
                      _buildDetailRow(
                        icon: Icons.info_outline,
                        iconColor: AppColors.primary,
                        label: donation.programName != null ? 'program'.tr() : 'campaign'.tr(),
                        value: donation.programName ?? donation.getLocalizedCampaignName(context.locale.languageCode) ?? '',
                      ),
                    if (donation.programName != null || donation.campaignName != null || donation.campaignNameEn != null) const SizedBox(height: 16),
                    // Gift Badge
                    if (isGift)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'gift_donation_badge'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isGift) const SizedBox(height: 16),
                    // Donor Name
                    if (donation.donorName != null && !donation.isAnonymous)
                      _buildDetailRow(
                        icon: Icons.person_outline,
                        iconColor: AppColors.textSecondary,
                        label: 'donor_name_required'.tr(),
                        value: donation.donorName!,
                      ),
                    if (donation.donorName != null && !donation.isAnonymous) const SizedBox(height: 16),
                    // Anonymous
                    if (donation.isAnonymous)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_off,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'anonymous_donation_badge'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (donation.isAnonymous) const SizedBox(height: 16),
                    // Donation ID
                    _buildDetailRow(
                      icon: Icons.tag,
                      iconColor: AppColors.textSecondary,
                      label: 'donation_id_label'.tr(),
                      value: donation.id,
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

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDonationCard(Donation donation) {
    // Get donation status info
    final statusInfo = _getDonationStatusInfo(donation);
    
    return InkWell(
      onTap: () => _showDonationDetails(donation),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Amount Section - Prominent
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${donation.amount.toStringAsFixed(0)}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'riyal'.tr(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - Campaign name first
                    Text(
                      donation.getLocalizedCampaignName(context.locale.languageCode) ?? donation.programName ?? 'charity_donation'.tr(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Date and Status in one line
                    Row(
                      children: [
                        Text(
                          _formatDate(donation.date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusInfo['text'],
                          style: AppTextStyles.bodySmall.copyWith(
                            color: statusInfo['color'],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Icon
              Icon(
                statusInfo['icon'],
                size: 20,
                color: statusInfo['color'],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced Empty State Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'no_donations_yet'.tr(),
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'when_you_donate_will_appear_here'.tr(),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced Empty State Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'no_donations_found_for_filter'.tr(),
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'try_different_filter_or_check_back_later'.tr(),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 