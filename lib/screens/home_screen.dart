import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../widgets/common/campaign_card.dart';
import '../models/campaign.dart';
import '../services/student_registration_service.dart';
import '../services/campaign_service.dart';
import '../services/donation_service.dart';
import '../models/donation.dart';
import '../providers/auth_provider.dart';
import 'quick_donate_amount_screen.dart';
import 'gift_donation_screen.dart';
import 'my_donations_screen.dart';
import 'campaign_donation_screen.dart';
import 'student_registration_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final StudentRegistrationService _studentService = StudentRegistrationService();
  final CampaignService _campaignService = CampaignService();
  final DonationService _donationService = DonationService();
  List<Campaign> _campaigns = [];
  List<Campaign> _allCampaigns = []; // جميع الحملات الأصلية
  List<Donation> _recentDonations = []; // التبرعات الأخيرة
  int _currentIndex = 0; // Home tab is active (الرئيسية في index 0)
  String _selectedFilter = 'الكل'; // Track selected filter
  
  // Application status variables
  Map<String, dynamic>? _applicationData;
  bool _isCheckingApplication = false;
  bool _isLoadingCampaigns = false;
  bool _isLoadingRecentDonations = false;

  @override
  void initState() {
    super.initState();
    _loadCampaignsFromAPI(); // Load from API instead of sample data
    _loadRecentDonations(); // Load recent donations from API
    _checkApplicationStatus();
    
    // Listen to auth changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_onAuthStateChanged);
    });
  }

  void _onAuthStateChanged() {
    // Update application status when auth state changes
    print('HomeScreen: Auth state changed, updating application status...');
    _checkApplicationStatus();
  }

  Future<void> _loadCampaignsFromAPI() async {
    try {
      print('HomeScreen: Loading campaigns from API...');
      setState(() {
        _isLoadingCampaigns = true;
      });
      
      List<Campaign> allCampaigns = [];
      
      // Load only charity campaigns for the home page (for general users)
      try {
        final charityCampaigns = await _campaignService.getCharityCampaigns();
        allCampaigns.addAll(charityCampaigns);
        print('HomeScreen: Successfully loaded ${charityCampaigns.length} charity campaigns from API');
        print('HomeScreen: Charity campaigns are for general users to donate directly');
      } catch (error) {
        print('HomeScreen: Failed to load charity campaigns: $error');
      }
      
      // Note: Student programs are loaded separately in student registration screens
      // They are for students who want to register for support, not for general donation
      
      // Only use data from API - no fallback
      if (allCampaigns.isNotEmpty) {
        setState(() {
          _campaigns = allCampaigns;
          _allCampaigns = List.from(allCampaigns);
          _isLoadingCampaigns = false;
        });
        
        print('HomeScreen: Successfully loaded ${allCampaigns.length} total campaigns from API');
        print('HomeScreen: Campaign IDs: ${allCampaigns.map((c) => c.id).toList()}');
        print('HomeScreen: Campaign titles: ${allCampaigns.map((c) => c.title).toList()}');
      } else {
        // No data from API - show empty state
        print('HomeScreen: No data from API, showing empty state');
        setState(() {
          _campaigns = [];
          _allCampaigns = [];
          _isLoadingCampaigns = false;
        });
        
        // Show message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'no_campaigns_available'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (error) {
      print('HomeScreen: Error loading campaigns from API: $error');
      setState(() {
        _campaigns = [];
        _allCampaigns = [];
        _isLoadingCampaigns = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'error_loading_programs'.tr(),
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

  Future<void> _loadRecentDonations() async {
    try {
      print('HomeScreen: Loading recent donations from API...');
      setState(() {
        _isLoadingRecentDonations = true;
      });
      
      final recentDonations = await _donationService.getRecentDonations(limit: 5);
      print('HomeScreen: Successfully loaded ${recentDonations.length} recent donations from API');
      
      setState(() {
        _recentDonations = recentDonations;
        _isLoadingRecentDonations = false;
      });
    } catch (error) {
      print('HomeScreen: Error loading recent donations: $error');
      setState(() {
        _recentDonations = [];
        _isLoadingRecentDonations = false;
      });
    }
  }

  @override
  void dispose() {
    // Remove auth listener
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_onAuthStateChanged);
    } catch (e) {
      // Ignore if provider is not available
    }
    
    _searchController.dispose();
    super.dispose();
  }

  void _onQuickDonate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuickDonateAmountScreen(),
      ),
    );
  }

  void _onGiftDonation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GiftDonationScreen(),
      ),
    );
  }

  void _onMyDonations() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      
      if (!mounted) return; // تحقق من أن الـ widget لا يزال موجوداً
      
      if (isAuthenticated) {
        // إذا كان المستخدم مسجل دخول، افتح شاشة تبرعاتي
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyDonationsScreen(),
          ),
        );
      } else {
        // إذا لم يكن مسجل دخول، اعرض bottom sheet
        _showLoginBottomSheet();
      }
    } catch (error) {
      // في حالة حدوث خطأ، اعرض bottom sheet كإجراء احترازي
      if (mounted) {
        _showLoginBottomSheet();
      }
    }
  }

  void _showLoginBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Enhanced Icon with animation
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.secondary.withOpacity(0.15),
                        AppColors.accent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Main icon
                      const Icon(
                        Icons.lock_outline,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Enhanced Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'login_required'.tr(),
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Enhanced Description with better styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.surfaceVariant,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'login_to_view_donations'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Enhanced Login Button with better effects
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.login,
                                  color: AppColors.surface,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'login'.tr(),
                                style: AppTextStyles.buttonLarge.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Enhanced Register Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_add,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'create_new_account'.tr(),
                                style: AppTextStyles.buttonLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Enhanced Skip button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'skip'.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkApplicationStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      print('HomeScreen: Checking application status, isAuthenticated: $isAuthenticated');
      if (!isAuthenticated) {
        print('HomeScreen: User not authenticated, clearing application data');
        setState(() {
          _applicationData = null;
          _isCheckingApplication = false;
        });
        return;
      }
      
      setState(() {
        _isCheckingApplication = true;
      });
      
      print('HomeScreen: Fetching latest application data from server...');
      final application = await _studentService.getCurrentUserRegistration();
      
      // Debug: Print application data
      print('=== Application Status Debug ===');
      print('Application data: $application');
      if (application != null) {
        print('Status: ${application['status']}');
        print('Status type: ${application['status'].runtimeType}');
        print('Rejection reason: ${application['rejection_reason']}');
        print('Rejection reason type: ${application['rejection_reason']?.runtimeType}');
        
        // Validate status format
        String status = application['status']?.toString().toLowerCase() ?? 'pending';
        print('Normalized status: $status');
        
        // Ensure status is one of the expected values
        switch (status) {
          case 'pending':
          case 'under_review':
          case 'approved':
          case 'rejected':
            print('Status is valid: $status');
            break;
          default:
            print('Warning: Unknown status: $status, defaulting to pending');
            application['status'] = 'pending';
        }
      }
      print('===============================');
      
      setState(() {
        _applicationData = application;
        _isCheckingApplication = false;
      });
      
      print('HomeScreen: Application status updated successfully');
    } catch (error) {
      print('Error checking application status: $error');
      setState(() {
        _isCheckingApplication = false;
      });
    }
  }

  void _onRegister() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      print('Auth check result for student registration: $isAuthenticated');
      
      if (!isAuthenticated) {
        print('User not authenticated, showing bottom sheet');
        _showLoginBottomSheet();
        return;
      }
      
      // If user has a registration, show it in read-only mode
      if (_applicationData != null) {
        // Debug: Print data being passed to registration screen
        print('=== Navigation Debug ===');
        print('Passing data to registration screen: $_applicationData');
        print('Status: ${_applicationData!['status']}');
        print('========================');
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentRegistrationScreen(
              existingData: _applicationData,
              isReadOnly: false, // Allow editing for re-submission
            ),
          ),
        );
      } else {
        // No registration, navigate to registration screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentRegistrationScreen(),
          ),
        );
      }
    } catch (error) {
      print('Error checking authentication: $error');
      _showLoginBottomSheet();
    }
  }

  void _showApplicationStatus(Map<String, dynamic> application) {
    final status = application['status'] ?? 'unknown';
    final rejectionReason = application['rejection_reason'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Application Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'application_status'.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusText(status),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusDescription(status),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Rejection reason if applicable
                    if (status.toLowerCase() == 'rejected' && rejectionReason != null) ...[
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
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'rejection_reason'.tr(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rejectionReason,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.textTertiary.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        'close'.tr(),
                        style: AppTextStyles.buttonMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (status.toLowerCase() == 'rejected')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentRegistrationScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'resubmit_application'.tr(),
                          style: AppTextStyles.buttonMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        return 'pending'.tr();
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return 'under_review'.tr();
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        return 'approved'.tr();
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        return 'rejected'.tr();
      default:
        print('Warning: Unknown status in _getStatusText: $status, defaulting to pending');
        return 'pending'.tr();
    }
  }

  Color _getStatusColor(String status) {
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        return AppColors.info;
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return AppColors.warning;
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
        print('Warning: Unknown status in _getStatusColor: $status, defaulting to info color');
        return AppColors.info;
    }
  }

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
        print('Warning: Unknown status in _getStatusIcon: $status, defaulting to schedule icon');
        return Icons.schedule;
    }
  }

  String _getStatusDescription(String status) {
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        return 'application_pending_description'.tr();
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return 'application_under_review_description'.tr();
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        return 'application_approved_description'.tr();
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        return 'application_rejected_description'.tr();
      default:
        print('Warning: Unknown status in _getStatusDescription: $status, defaulting to pending description');
        return 'application_pending_description'.tr();
    }
  }

  String _getButtonText() {
    if (_isCheckingApplication) {
      return 'checking'.tr();
    }
    
    if (_applicationData == null) {
      return 'register_now'.tr();
    }
    
    final status = _applicationData!['status'] ?? 'unknown';
    
    // Debug: Print button text decision
    print('=== Button Text Debug ===');
    print('Status: $status');
    print('Status lowercase: ${status.toLowerCase()}');
    
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        print('Button text: pending');
        return 'pending'.tr();
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        print('Button text: under_review');
        return 'under_review'.tr();
      case 'approved':
      case 'accepted':
      case 'مقبول':
      case 'تم القبول':
        print('Button text: approved');
        return 'approved'.tr();
      case 'rejected':
      case 'مرفوض':
      case 'تم الرفض':
        print('Button text: resubmit_application');
        return 'resubmit_application'.tr();
      default:
        print('Button text: view_application (default)');
        return 'view_application'.tr();
    }
  }

  Color _getButtonColor() {
    if (_applicationData == null) {
      return AppColors.primary;
    }
    
    final status = _applicationData!['status'] ?? 'unknown';
    
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'pending':
      case 'في الانتظار':
        return AppColors.info;
      case 'under_review':
      case 'قيد المراجعة':
      case 'قيد الدراسة':
        return AppColors.warning;
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
        return AppColors.primary;
    }
  }

  void _onCampaignTap(Campaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CampaignDonationScreen(campaign: campaign),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userProfile = authProvider.userProfile;
        
        print('HomeScreen: Building with isAuthenticated: $isAuthenticated');
        print('HomeScreen: User profile: ${userProfile?.keys}');
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
        children: [
          // Modern Compact Header Section
          Container(
            width: double.infinity,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding,
                  vertical: AppConstants.smallPadding,
                ),
                child: Column(
                  children: [
                    // Compact Header Row
                    Row(
                      children: [
                        // Profile icon with notification badge
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.surface,
                                size: 18,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Welcome text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'welcome'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.surface.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                'app_title'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.smallPadding),
                    
                    // Modern Search Bar with glassmorphism effect
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'search'.tr(),
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.filter_list,
                              color: AppColors.secondary,
                              size: 16,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.smallPadding,
                            vertical: AppConstants.smallPadding,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature Icons Row - Modern, outside any card
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Row(
                      children: [
                        Expanded(
                          child:                         _buildModernCircleFeature(
                          icon: Icons.favorite,
                          label: 'quick_donate'.tr(),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          onTap: _onQuickDonate,
                        ),
                        ),
                        Expanded(
                          child:                         _buildModernCircleFeature(
                          icon: Icons.card_giftcard,
                          label: 'gift_donation'.tr(),
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.accentLight],
                          ),
                          onTap: _onGiftDonation,
                        ),
                        ),
                        Expanded(
                          child:                         _buildModernCircleFeature(
                          icon: Icons.history,
                          label: 'my_donations'.tr(),
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.secondaryLight],
                          ),
                          onTap: _onMyDonations,
                        ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                                     // Modern Student Help Banner - Image Background with Gradient Overlay
                   Container(
                     width: double.infinity,
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: AppColors.primary.withOpacity(0.25),
                           blurRadius: 15,
                           offset: const Offset(0, 8),
                         ),
                       ],
                     ),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(20),
                       child: Stack(
                         children: [
                           // Background Image
                           Container(
                             width: double.infinity,
                             height: 200,
                             decoration: const BoxDecoration(
                               image: DecorationImage(
                                 image: NetworkImage(
                                   'https://images.pexels.com/photos/5905708/pexels-photo-5905708.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                                 ),
                                 fit: BoxFit.cover,
                               ),
                             ),
                           ),
                           // Gradient Overlay for better text readability
                           Container(
                             width: double.infinity,
                             height: 200,
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 begin: Alignment.topLeft,
                                 end: Alignment.bottomRight,
                                 colors: [
                                   AppColors.primary.withOpacity(0.7),
                                   AppColors.secondary.withOpacity(0.6),
                                   Colors.black.withOpacity(0.4),
                                 ],
                               ),
                             ),
                           ),
                           // Centered Content
                           SizedBox(
                             width: double.infinity,
                             height: 200,
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               crossAxisAlignment: CrossAxisAlignment.center,
                               children: [
                                 Text(
                                   'start_journey'.tr(),
                                   style: AppTextStyles.titleLarge.copyWith(
                                     fontWeight: FontWeight.bold,
                                     color: Colors.white,
                                     height: 1.2,
                                     shadows: [
                                       Shadow(
                                         color: Colors.black.withOpacity(0.3),
                                         blurRadius: 8,
                                         offset: const Offset(0, 2),
                                       ),
                                     ],
                                   ),
                                   textAlign: TextAlign.center,
                                 ),
                                 const SizedBox(height: 8),
                                 Text(
                                   'enable_education'.tr(),
                                   style: AppTextStyles.bodyMedium.copyWith(
                                     color: Colors.white.withOpacity(0.95),
                                     shadows: [
                                       Shadow(
                                         color: Colors.black.withOpacity(0.2),
                                         blurRadius: 6,
                                         offset: const Offset(0, 1),
                                       ),
                                     ],
                                   ),
                                   textAlign: TextAlign.center,
                                 ),
                                 const SizedBox(height: 18),
                                 Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 32),
                                   child: Container(
                                     width: double.infinity,
                                     height: 48,
                                     decoration: BoxDecoration(
                                       color: Colors.white,
                                       borderRadius: BorderRadius.circular(12),
                                       boxShadow: [
                                         BoxShadow(
                                           color: Colors.black.withOpacity(0.15),
                                           blurRadius: 8,
                                           offset: const Offset(0, 4),
                                         ),
                                       ],
                                     ),
                                     child: Material(
                                       color: Colors.transparent,
                                       child: InkWell(
                                         onTap: _onRegister,
                                         borderRadius: BorderRadius.circular(12),
                                         child: Center(
                                           child: Row(
                                             mainAxisAlignment: MainAxisAlignment.center,
                                             mainAxisSize: MainAxisSize.min,
                                             children: [
                                               const Icon(
                                                 Icons.edit_note,
                                                 color: AppColors.primary,
                                                 size: 20,
                                               ),
                                               const SizedBox(width: 8),
                                               Text(
                                                 _getButtonText(),
                                                 style: AppTextStyles.buttonMedium.copyWith(
                                                   color: _getButtonColor(),
                                                   fontWeight: FontWeight.w600,
                                                   fontSize: 15,
                                                   shadows: [
                                                     Shadow(
                                                       color: Colors.black.withOpacity(0.08),
                                                       blurRadius: 2,
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
                               ],
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                  
                  const SizedBox(height: AppConstants.extraLargePadding),
                  
                  // Campaigns Section
                  Text(
                    'be_hope'.tr(),
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Modern Filters
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      children: [
                        _buildFilterChip('all'.tr(), _selectedFilter == 'الكل'),
                        const SizedBox(width: 12),
                        _buildFilterChip('education_opportunities'.tr(), _selectedFilter == 'فرص التعليم'),
                        const SizedBox(width: 12),
                        _buildFilterChip('housing_transport'.tr(), _selectedFilter == 'السكن والنقل'),
                        const SizedBox(width: 12),
                        _buildFilterChip('monthly_allowance'.tr(), _selectedFilter == 'الإعانة الشهرية'),
                        const SizedBox(width: 12),
                        _buildFilterChip('device_purchase'.tr(), _selectedFilter == 'شراء أجهزة'),
                        const SizedBox(width: 12),
                        _buildFilterChip('test_fees'.tr(), _selectedFilter == 'رسوم الاختبارات'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  if (_campaigns.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.extraLargePadding),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.campaign,
                              size: AppConstants.extraLargeIconSize,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Text(
                              'no_active_campaigns'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._campaigns.map((campaign) => CampaignCard(
                      campaign: campaign,
                      onTap: () => _onCampaignTap(campaign),
                    )),
                    
                    const SizedBox(height: AppConstants.extraLargePadding),
                    
                    // Recent Donations Section
                    Text(
                      'recent_donations'.tr(),
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    
                    // Recent Donations List
                    _buildRecentDonationsList(),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 1) { // تبرعاتي
            _onMyDonations();
          } else if (index == 2) { // الإعدادات
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'my_donations'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'settings'.tr(),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildModernCircleFeature({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    bool isCurrentlySelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: false, // Remove checkmark
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = label;
          if (label == 'all'.tr()) {
            _campaigns = _allCampaigns;
          } else {
            _campaigns = _allCampaigns.where((campaign) => campaign.category == label).toList();
          }
        });
      },
      selectedColor: AppColors.surface, // Keep background white
      backgroundColor: AppColors.surface,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: isCurrentlySelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isCurrentlySelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isCurrentlySelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.2),
          width: isCurrentlySelected ? 2 : 1, // Thicker border for selected
        ),
      ),
    );
  }

  Widget _buildRecentDonationCard({
    required String donorName,
    required double amount,
    required String campaignTitle,
    required String timeAgo,
    required bool isAnonymous,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textPrimary.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Donor name and time
          Row(
            children: [
              Expanded(
                child: Text(
                  donorName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 10,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    timeAgo,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Campaign title
          Text(
            campaignTitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Amount with icon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${amount.toStringAsFixed(0)} ${'riyal'.tr()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          
          // Motivational message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volunteer_activism,
                  size: 10,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'help_achieve_hope'.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary.withOpacity(0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDonationsList() {
    if (_isLoadingRecentDonations) {
      return SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_recentDonations.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'no_donations_found'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _recentDonations.length,
        itemBuilder: (context, index) {
          final donation = _recentDonations[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 280,
              child: _buildRecentDonationCard(
                donorName: donation.isAnonymous ? 'donor'.tr() : (donation.donorName ?? 'donor'.tr()),
                amount: donation.amount,
                campaignTitle: donation.campaignName ?? donation.programName ?? 'general'.tr(),
                timeAgo: _formatTimeAgo(donation.date),
                isAnonymous: donation.isAnonymous,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'recently'.tr();
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day_ago'.tr() : 'days_ago'.tr()}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour_ago'.tr() : 'hours_ago'.tr()}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute_ago'.tr() : 'minutes_ago'.tr()}';
    } else {
      return 'recently'.tr();
    }
  }
}