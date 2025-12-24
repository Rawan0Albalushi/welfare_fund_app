import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../widgets/common/campaign_card.dart';
import '../models/campaign.dart';
import '../models/app_banner.dart';
import '../models/donation.dart';
import '../models/student_registration_card.dart';
import '../services/banner_service.dart';
import '../services/campaign_service.dart';
import '../services/donation_service.dart';
import '../services/student_registration_card_service.dart';
import '../services/student_registration_service.dart';
import '../providers/auth_provider.dart';
import 'quick_donate_amount_screen.dart';
// import 'gift_donation_screen.dart'; // Unused for now
import 'my_donations_screen.dart';
import 'campaign_donation_screen.dart';
import 'student_registration_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'all_campaigns_screen.dart';
import '../utils/category_utils.dart';

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
  final BannerService _bannerService = BannerService();
  final PageController _bannerPageController = PageController(viewportFraction: 0.92);
  final StudentRegistrationCardService _registrationCardService = StudentRegistrationCardService();
  List<Campaign> _campaigns = [];
  List<Campaign> _allCampaigns = []; // جميع الحملات الأصلية
  List<Donation> _recentDonations = []; // التبرعات الأخيرة
  List<AppBanner> _banners = [];
  int _currentIndex = 0; // Home tab is active (الرئيسية في index 0)
  List<Map<String, dynamic>> _categories = [];
  Map<String, List<String>> _categoryMatchers = {};
  bool _isLoadingCategories = false;
  String _selectedCategoryId = 'all';
  
  // Application status variables
  Map<String, dynamic>? _applicationData;
  bool _isCheckingApplication = false;
  bool _isLoadingCampaigns = false;
  bool _isLoadingRecentDonations = false;
  bool _isLoadingBanners = false;
  int _activeHeroIndex = 0;
  static const String _defaultRegistrationCardImage =
      'https://images.pexels.com/photos/5905708/pexels-photo-5905708.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
  StudentRegistrationCardData? _registrationCardData;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCampaignsFromAPI(); // Load from API instead of sample data
    _loadRecentDonations(); // Load recent donations from API
    _loadBanners();
    _checkApplicationStatus();
    _loadRegistrationCard();
    
    // Check application status again after a delay to ensure fresh data
    // This is important after returning from registration screen
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        print('HomeScreen: Re-checking application status after delay...');
        _checkApplicationStatus();
      }
    });
    
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

  Future<void> _refreshHomeData() async {
    // Reload all data when returning to home screen
    print('HomeScreen: Refreshing home data...');
    _loadCampaignsFromAPI();
    _loadRecentDonations();
    _loadBanners();
    _checkApplicationStatus();
    _loadRegistrationCard();
  }

  String _getRegistrationCardText({
    required BuildContext context,
    required String fallbackKey,
    required String? arabicValue,
    required String? englishValue,
  }) {
    final localeCode = context.locale.languageCode.toLowerCase();
    final String? localizedValue;
    if (localeCode == 'ar') {
      localizedValue = arabicValue ?? englishValue;
    } else {
      localizedValue = englishValue ?? arabicValue;
    }

    if (localizedValue != null && localizedValue.trim().isNotEmpty) {
      return localizedValue.trim();
    }

    return fallbackKey.tr();
  }

  List<Color> _getRegistrationCardOverlayColors(StudentRegistrationCardData? cardData) {
    final background = cardData?.background;
    final List<Color> overlayColors = [];

    if (background != null) {
      if (background.colorFrom != null) {
        overlayColors.add(background.colorFrom!.withOpacity(0.7));
      }
      if (background.colorTo != null) {
        overlayColors.add(background.colorTo!.withOpacity(0.65));
      }
      if (overlayColors.isEmpty && background.colorFrom != null) {
        overlayColors.add(background.colorFrom!.withOpacity(0.65));
      }
    }

    if (overlayColors.isEmpty) {
      overlayColors.addAll([
        AppColors.primary.withOpacity(0.7),
        AppColors.secondary.withOpacity(0.6),
      ]);
    } else if (overlayColors.length == 1) {
      overlayColors.add(overlayColors.first);
    }

    overlayColors.add(Colors.black.withOpacity(0.35));
    return overlayColors;
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      print('HomeScreen: Loading categories from API...');
      final categoriesFromApi = await _campaignService.getCategories();

      if (!mounted) return;

      final bool hasApiCategories = categoriesFromApi.isNotEmpty;
      final normalizedCategories = hasApiCategories
          ? _normalizeCategories(categoriesFromApi)
          : _normalizeCategories(CategoryUtils.getLocalizedFallbackCategories());

      if (!hasApiCategories) {
        print('HomeScreen: Categories API returned empty list, using localized fallback categories.');
      } else {
        print('HomeScreen: Loaded ${normalizedCategories.length} categories from API.');
      }

      setState(() {
        _categories = normalizedCategories;
        _categoryMatchers = _createCategoryMatchers(normalizedCategories);
        _isLoadingCategories = false;
      });
    } catch (error) {
      print('HomeScreen: Error loading categories: $error');

      if (!mounted) return;

      final fallbackCategories = _normalizeCategories(
        CategoryUtils.getLocalizedFallbackCategories(),
      );

      setState(() {
        _categories = fallbackCategories;
        _categoryMatchers = _createCategoryMatchers(fallbackCategories);
        _isLoadingCategories = false;
      });
    }

    if (!mounted) return;

    _applyCategoryFilter(_selectedCategoryId);
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
          _allCampaigns = List.from(allCampaigns);
          _isLoadingCampaigns = false;
        });

        _applyCategoryFilter(_selectedCategoryId);
        
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
          _selectedCategoryId = 'all';
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
        _selectedCategoryId = 'all';
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

  Future<void> _loadBanners() async {
    setState(() {
      _isLoadingBanners = true;
    });

    try {
      final featured = await _bannerService.getFeaturedBanners();
      final active = await _bannerService.getActiveBanners();
      final combined = <AppBanner>[];
      final seenIds = <String>{};

      for (final banner in [...featured, ...active]) {
        if (banner.id.isEmpty || seenIds.contains(banner.id)) continue;
        seenIds.add(banner.id);
        combined.add(banner);
      }
      combined.sort((a, b) => a.priority.compareTo(b.priority));

      if (!mounted) return;
      setState(() {
        _banners = combined;
        _activeHeroIndex = 0;
      });
    } catch (error) {
      print('HomeScreen: Error loading banners: $error');
      if (!mounted) return;
      setState(() {
        _banners = [];
        _activeHeroIndex = 0;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingBanners = false;
      });
    }
  }

  Future<void> _loadRegistrationCard() async {
    if (!mounted) return;

    try {
      final cardData = await _registrationCardService.fetchCardData();
      if (!mounted) return;
      setState(() {
        _registrationCardData = cardData;
      });
    } catch (error) {
      print('HomeScreen: Error loading registration card data: $error');
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
    _bannerPageController.dispose();
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
                
                const SizedBox(height: 12),
                
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
    print('═══════════════════════════════════════════════════════════');
    print('🔄 [_checkApplicationStatus] Called');
    print('═══════════════════════════════════════════════════════════');
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      print('🔐 [_checkApplicationStatus] isAuthenticated: $isAuthenticated');
      
      if (!isAuthenticated) {
        print('❌ [_checkApplicationStatus] User not authenticated, clearing application data');
        setState(() {
          _applicationData = null;
          _isCheckingApplication = false;
        });
        print('📝 [_checkApplicationStatus] _applicationData set to null');
        return;
      }
      
      print('⏳ [_checkApplicationStatus] Setting _isCheckingApplication = true');
      setState(() {
        _isCheckingApplication = true;
      });
      
      print('🌐 [_checkApplicationStatus] Fetching latest application data from server...');
      print('📍 [_checkApplicationStatus] Using endpoint: GET /api/v1/students/registration/my-registration');
      
      // Add a small delay to ensure backend has processed the registration
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('📡 [_checkApplicationStatus] Calling getCurrentUserRegistration()...');
      final application = await _studentService.getCurrentUserRegistration();
      
      // Debug: Print application data
      print('═══════════════════════════════════════════════════════════');
      print('📦 [_checkApplicationStatus] API Response Received');
      print('═══════════════════════════════════════════════════════════');
      print('📋 [_checkApplicationStatus] Raw application data: $application');
      print('📋 [_checkApplicationStatus] Application is null: ${application == null}');
      
      Map<String, dynamic>? normalizedApplication;
      
      if (application != null) {
        print('✅ [_checkApplicationStatus] Application data is NOT null');
        // Create a copy to avoid modifying the original
        normalizedApplication = Map<String, dynamic>.from(application);
        
        print('📊 [_checkApplicationStatus] Application keys: ${normalizedApplication.keys.toList()}');
        print('📊 [_checkApplicationStatus] Status before normalization: ${normalizedApplication['status']}');
        print('📊 [_checkApplicationStatus] Status type: ${normalizedApplication['status'].runtimeType}');
        print('📊 [_checkApplicationStatus] Full application data:');
        normalizedApplication.forEach((key, value) {
          print('   - $key: $value (${value.runtimeType})');
        });
        
        // Normalize status format - ensure it matches expected values
        // Backend status values: under_review, accepted, rejected, completed
        String rawStatus = normalizedApplication['status']?.toString() ?? 'under_review';
        String normalizedStatus = rawStatus.toLowerCase().trim();
        
        print('🔄 [_checkApplicationStatus] Normalizing status...');
        print('   - Raw status: "$rawStatus"');
        print('   - Normalized status: "$normalizedStatus"');
        
        // Normalize status values to match backend response: under_review, accepted, rejected, completed
        String finalStatus;
        switch (normalizedStatus) {
          case 'under_review':
          case 'قيد المراجعة':
            finalStatus = 'under_review';
            print('   ✅ Matched: under_review');
            break;
          case 'accepted':
          case 'مقبول':
            finalStatus = 'accepted';
            print('   ✅ Matched: accepted');
            break;
          case 'rejected':
          case 'مرفوض':
            finalStatus = 'rejected';
            print('   ✅ Matched: rejected');
            break;
          case 'completed':
          case 'مكتمل':
            finalStatus = 'completed';
            print('   ✅ Matched: completed');
            break;
          default:
            print('   ⚠️ Warning: Unknown status: "$rawStatus", defaulting to under_review');
            finalStatus = 'under_review';
        }
        
        // Ensure the normalized status is set in the application data
        normalizedApplication['status'] = finalStatus;
        
        print('✅ [_checkApplicationStatus] Normalized status: "$finalStatus"');
        print('✅ [_checkApplicationStatus] Status after normalization: ${normalizedApplication['status']}');
      } else {
        print('❌ [_checkApplicationStatus] Application data is NULL');
        print('❌ [_checkApplicationStatus] This means user may not have registered yet OR API returned null');
      }
      
      print('═══════════════════════════════════════════════════════════');
      
      if (!mounted) {
        print('⚠️ [_checkApplicationStatus] Widget not mounted, skipping setState');
        return;
      }
      
      print('🔄 [_checkApplicationStatus] Updating state...');
      print('   - Old _applicationData: $_applicationData');
      print('   - New _applicationData: $normalizedApplication');
      
      setState(() {
        _applicationData = normalizedApplication;
        _isCheckingApplication = false;
      });
      
      print('✅ [_checkApplicationStatus] State updated successfully');
      print('📋 [_checkApplicationStatus] Current _applicationData: $_applicationData');
      if (normalizedApplication != null) {
        print('📋 [_checkApplicationStatus] Status in _applicationData: ${normalizedApplication['status']}');
      } else {
        print('📋 [_checkApplicationStatus] _applicationData is NULL (will show "سجل الآن")');
      }
      print('═══════════════════════════════════════════════════════════');
    } catch (error) {
      print('❌ [_checkApplicationStatus] Error occurred: $error');
      print('❌ [_checkApplicationStatus] Error type: ${error.runtimeType}');
      print('❌ [_checkApplicationStatus] This error will be caught - _applicationData will remain null');
      print('═══════════════════════════════════════════════════════════');
      
      // Even if there's an error, set _isCheckingApplication to false
      if (!mounted) return;
      setState(() {
        _isCheckingApplication = false;
        // Keep _applicationData as null on error
        // This means button will show "سجل الآن"
      });
      
      // Log the full error for debugging
      print('Full error details:');
      print(error.toString());
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
        ).then((_) {
          // Refresh application status when returning from registration screen
          print('HomeScreen: Returned from registration screen, refreshing application status...');
          _checkApplicationStatus();
        });
      } else {
        // No registration, navigate to registration screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentRegistrationScreen(),
          ),
        ).then((_) {
          // Refresh application status when returning from registration screen
          print('HomeScreen: Returned from registration screen, refreshing application status...');
          _checkApplicationStatus();
        });
      }
    } catch (error) {
      print('Error checking authentication: $error');
      _showLoginBottomSheet();
    }
  }

  String _getButtonText() {
    print('═══════════════════════════════════════════════════════════');
    print('🔘 [_getButtonText] Called');
    print('═══════════════════════════════════════════════════════════');
    print('📋 [_getButtonText] _isCheckingApplication: $_isCheckingApplication');
    print('📋 [_getButtonText] _applicationData: $_applicationData');
    print('📋 [_getButtonText] _applicationData is null: ${_applicationData == null}');
    
    if (_isCheckingApplication) {
      print('⏳ [_getButtonText] Currently checking, returning: checking');
      print('═══════════════════════════════════════════════════════════');
      return 'checking'.tr();
    }
    
    if (_applicationData == null) {
      print('❌ [_getButtonText] _applicationData is NULL, returning: register_now');
      print('❌ [_getButtonText] This is why you see "سجل الآن" button');
      print('═══════════════════════════════════════════════════════════');
      return 'register_now'.tr();
    }
    
    print('✅ [_getButtonText] _applicationData is NOT null');
    print('📋 [_getButtonText] _applicationData keys: ${_applicationData!.keys.toList()}');
    
    final status = _applicationData!['status'] ?? 'unknown';
    
    print('📊 [_getButtonText] Status from _applicationData: "$status"');
    print('📊 [_getButtonText] Status type: ${status.runtimeType}');
    
    // Normalize status
    String normalizedStatus = status.toString().toLowerCase().trim();
    print('📊 [_getButtonText] Normalized status: "$normalizedStatus"');
    
    String buttonText;
    switch (normalizedStatus) {
      // Backend status values: under_review, accepted, rejected, completed
      case 'under_review':
      case 'قيد المراجعة':
        buttonText = 'under_review'.tr();
        print('✅ [_getButtonText] Matched: under_review');
        break;
      case 'accepted':
      case 'مقبول':
        buttonText = 'approved'.tr();
        print('✅ [_getButtonText] Matched: accepted');
        break;
      case 'rejected':
      case 'مرفوض':
        buttonText = 'rejected'.tr();
        print('✅ [_getButtonText] Matched: rejected');
        break;
      case 'completed':
      case 'مكتمل':
        buttonText = 'completed'.tr();
        print('✅ [_getButtonText] Matched: completed');
        break;
      default:
        buttonText = 'view_application'.tr();
        print('⚠️ [_getButtonText] Unknown status, using default: view_application');
    }
    
    print('✅ [_getButtonText] Returning button text: "$buttonText"');
    print('═══════════════════════════════════════════════════════════');
    return buttonText;
  }

  // Backend status values: under_review, accepted, rejected, completed
  Color _getButtonColor() {
    if (_applicationData == null) {
      return AppColors.primary;
    }
    
    final status = _applicationData!['status'] ?? 'unknown';
    
    // Normalize status
    String normalizedStatus = status.toLowerCase();
    
    switch (normalizedStatus) {
      case 'under_review':
      case 'قيد المراجعة':
        return AppColors.warning;
      case 'accepted':
      case 'مقبول':
        return AppColors.success;
      case 'rejected':
      case 'مرفوض':
        return AppColors.error;
      case 'completed':
      case 'مكتمل':
        return AppColors.successDark;
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

  void _onViewAllCampaigns() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllCampaignsScreen(
          initialCampaigns: _allCampaigns,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userProfile = authProvider.userProfile;
        final List<Campaign> displayedCampaigns = _campaigns.take(5).toList();
        final bool shouldShowViewAllButton = _campaigns.isNotEmpty;
        
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
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
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
                        // Donation icon
                        const Icon(
                          Icons.volunteer_activism,
                          color: AppColors.surface,
                          size: 26,
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
                        onChanged: (value) {
                          _applyFilters();
                        },
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
                          suffixIcon: _buildSearchSuffixIcon(),
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
                          child: _buildModernCircleFeature(
                            icon: Icons.campaign,
                            label: 'view_campaigns'.tr(),
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, AppColors.accentLight],
                            ),
                            onTap: _onViewAllCampaigns,
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
                  
                  _buildStudentBannerCarousel(),
                  
                  const SizedBox(height: AppConstants.extraLargePadding),
                  
                  // Campaigns Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'be_hope'.tr(),
                          style: AppTextStyles.headlineMedium,
                        ),
                      ),
                      if (shouldShowViewAllButton)
                        _buildViewAllButton(),
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Modern Filters
                  _buildCategoryFilterSection(),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  if (_isLoadingCampaigns && displayedCampaigns.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.extraLargePadding,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (_campaigns.isEmpty)
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
                    ...[
                      ...displayedCampaigns.map(
                        (campaign) => CampaignCard(
                          campaign: campaign,
                          onTap: () => _onCampaignTap(campaign),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: AppConstants.extraLargePadding),
                    
                    // Recent Donations Section
                    Text(
                      'recent_donations'.tr(),
                      style: AppTextStyles.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
          if (index == 0) {
            // Already on Home page - refresh data
            _refreshHomeData();
            setState(() {
              _currentIndex = index;
            });
          } else if (index == 1) { // تبرعاتي
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

  Widget _buildStudentBannerCarousel() {
    final heroCards = <Widget>[
      _buildStudentRegistrationCard(),
    ];

    if (_isLoadingBanners) {
      heroCards.add(_buildBannerLoadingCard());
    } else if (_banners.isNotEmpty) {
      heroCards.addAll(_banners.map(_buildBannerCard));
    }

    final showIndicators = heroCards.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: heroCards.length,
            onPageChanged: (index) {
              setState(() {
                _activeHeroIndex = index;
              });
            },
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: heroCards[index],
            ),
          ),
        ),
        if (showIndicators) ...[
          const SizedBox(height: 12),
          _buildHeroIndicators(heroCards.length),
        ],
      ],
    );
  }

  Widget _buildStudentRegistrationCard() {
    print('═══════════════════════════════════════════════════════════');
    print('🎨 [_buildStudentRegistrationCard] Building registration card');
    print('═══════════════════════════════════════════════════════════');
    print('📋 [_buildStudentRegistrationCard] _applicationData: $_applicationData');
    print('📋 [_buildStudentRegistrationCard] _applicationData is null: ${_applicationData == null}');
    print('📋 [_buildStudentRegistrationCard] _isCheckingApplication: $_isCheckingApplication');
    
    if (_applicationData != null) {
      print('📋 [_buildStudentRegistrationCard] _applicationData keys: ${_applicationData!.keys.toList()}');
      print('📋 [_buildStudentRegistrationCard] _applicationData status: ${_applicationData!['status']}');
    }
    
    final cardData = _registrationCardData;
    final String imageUrl = (cardData?.backgroundImageUrl?.isNotEmpty ?? false)
        ? cardData!.backgroundImageUrl!
        : _defaultRegistrationCardImage;

    final String headlineText = _getRegistrationCardText(
      context: context,
      fallbackKey: 'start_journey',
      arabicValue: cardData?.headlineAr,
      englishValue: cardData?.headlineEn,
    );

    final String subtitleText = _getRegistrationCardText(
      context: context,
      fallbackKey: 'enable_education',
      arabicValue: cardData?.subtitleAr,
      englishValue: cardData?.subtitleEn,
    );

    final List<Color> overlayColors = _getRegistrationCardOverlayColors(cardData);

    return Container(
      height: 200,
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
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: overlayColors,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    headlineText,
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
                    subtitleText,
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
                                 Builder(
                                   builder: (context) {
                                     final buttonText = _getButtonText();
                                     final buttonColor = _getButtonColor();
                                     print('🎨 [_buildStudentRegistrationCard] Rendering button');
                                     print('   - Button text: "$buttonText"');
                                     print('   - Button color: $buttonColor');
                                     print('   - _applicationData: $_applicationData');
                                     return Text(
                                       buttonText,
                                       style: AppTextStyles.buttonMedium.copyWith(
                                         color: buttonColor,
                                         fontWeight: FontWeight.w600,
                                         fontSize: 15,
                                         shadows: [
                                           Shadow(
                                             color: Colors.black.withOpacity(0.08),
                                             blurRadius: 2,
                                           ),
                                         ],
                                       ),
                                     );
                                   },
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
    );
  }

  Widget _buildBannerLoadingCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppColors.surface.withOpacity(0.9),
            AppColors.surfaceVariant.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildBannerCard(AppBanner banner) {
    final title = _getBannerTitle(banner);
    final subtitle = _getBannerSubtitle(banner);
    final description = _getBannerDescription(banner);
    final imageUrl = banner.mobileImageUrl ?? banner.imageUrl;
    final hasAction = (banner.actionUrl ?? '').isNotEmpty;
    final actionLabel = banner.actionLabel ?? 'donate_now'.tr();

    return GestureDetector(
      onTap: hasAction ? () => _handleBannerTap(banner) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.modernGradient,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.modernGradient,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (subtitle.isNotEmpty) const SizedBox(height: 12),
                    Text(
                      title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.92),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    if (hasAction)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              actionLabel,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _activeHeroIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  String _getBannerTitle(AppBanner banner) {
    final locale = context.locale.languageCode;
    if (locale == 'ar') {
      return banner.titleAr?.isNotEmpty == true
          ? banner.titleAr!
          : (banner.title ?? banner.titleEn ?? '');
    }
    return banner.titleEn?.isNotEmpty == true
        ? banner.titleEn!
        : (banner.title ?? banner.titleAr ?? '');
  }

  String _getBannerSubtitle(AppBanner banner) {
    final locale = context.locale.languageCode;
    if (locale == 'ar') {
      return banner.subtitleAr?.isNotEmpty == true
          ? banner.subtitleAr!
          : (banner.subtitle ?? banner.subtitleEn ?? '');
    }
    return banner.subtitleEn?.isNotEmpty == true
        ? banner.subtitleEn!
        : (banner.subtitle ?? banner.subtitleAr ?? '');
  }

  String _getBannerDescription(AppBanner banner) {
    final locale = context.locale.languageCode;
    if (locale == 'ar') {
      return banner.descriptionAr?.isNotEmpty == true
          ? banner.descriptionAr!
          : (banner.description ?? banner.descriptionEn ?? '');
    }
    return banner.descriptionEn?.isNotEmpty == true
        ? banner.descriptionEn!
        : (banner.description ?? banner.descriptionAr ?? '');
  }

  Future<void> _handleBannerTap(AppBanner banner) async {
    final url = banner.actionUrl;
    if (url == null || url.isEmpty) {
      return;
    }
    try {
      final launched = await launchUrlString(
        url,
        webOnlyWindowName: '_self',
      );
      if (!launched) {
        print('HomeScreen: Could not launch banner URL: $url');
      }
    } catch (error) {
      print('HomeScreen: Error launching banner URL ($url): $error');
    }
  }

  Widget _buildCategoryFilterSection() {
    if (_isLoadingCategories && _categories.isEmpty) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    final chips = <Widget>[
      _buildFilterChip(id: 'all', label: 'all'.tr()),
    ];

    for (final category in _categories) {
      final label = _getLocalizedCategoryLabel(category);
      if (label.isEmpty) continue;
      final categoryKey = _deriveCategoryKey(category);
      chips.add(_buildFilterChip(id: categoryKey, label: label));
    }

    if (chips.isEmpty) {
      chips.add(_buildFilterChip(id: 'all', label: 'all'.tr()));
    }

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: chips,
      ),
    );
  }

  String _getLocalizedCategoryLabel(Map<String, dynamic> category) {
    final locale = context.locale.languageCode;
    if (locale == 'ar') {
      final label = category['name_ar']?.toString() ?? '';
      if (label.isNotEmpty) return label;
    } else {
      final label = category['name_en']?.toString() ?? '';
      if (label.isNotEmpty) return label;
    }

    final fallbackName = category['name']?.toString() ?? '';
    if (fallbackName.isNotEmpty) return fallbackName;

    return category['title']?.toString() ?? '';
  }

  String _deriveCategoryKey(Map<String, dynamic> category) {
    final id = (category['id'] ?? '').toString();
    if (id.isNotEmpty) return id;

    final candidates = [
      category['name'],
      category['name_ar'],
      category['name_en'],
      category['title'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    return 'all';
  }

  Map<String, List<String>> _createCategoryMatchers(List<Map<String, dynamic>> categories) {
    final matchers = <String, List<String>>{};

    for (final category in categories) {
      final key = _deriveCategoryKey(category);
      final names = <String>{};

      for (final candidate in [
        category['name'],
        category['name_ar'],
        category['name_en'],
        category['title'],
      ]) {
        if (candidate == null) continue;
        final value = candidate.toString().trim().toLowerCase();
        if (value.isNotEmpty) {
          names.add(value);
        }
      }

      if (key.isNotEmpty) {
        names.add(key.trim().toLowerCase());
      }

      if (names.isNotEmpty) {
        matchers[key] = names.toList();
      }
    }

    return matchers;
  }

  List<Map<String, dynamic>> _normalizeCategories(List<Map<String, dynamic>> categories) {
    return categories.map((category) {
      final normalized = Map<String, dynamic>.from(category);
      normalized['id'] = (normalized['id'] ?? '').toString();
      final fallbackName = (normalized['name'] ?? normalized['title'] ?? '').toString();
      normalized['name'] = fallbackName;
      normalized['name_ar'] = (normalized['name_ar'] ?? fallbackName).toString();
      normalized['name_en'] = (normalized['name_en'] ?? fallbackName).toString();
      normalized['status'] = (normalized['status'] ?? 'active').toString();
      return normalized;
    }).toList();
  }

  void _applyCategoryFilter(String categoryKey) {
    final normalizedKey = categoryKey.isEmpty ? 'all' : categoryKey;
    _selectedCategoryId = normalizedKey;
    _applyFilters();
  }

  void _applyFilters() {
    List<Campaign> filteredCampaigns;

    // Apply category filter
    if (_selectedCategoryId == 'all') {
      filteredCampaigns = List.from(_allCampaigns);
    } else {
      final matcherValues = _categoryMatchers[_selectedCategoryId] ??
          _categoryMatchers.values.firstWhere(
            (names) => names.contains(_selectedCategoryId.toLowerCase()),
            orElse: () => <String>[],
          );

      if (matcherValues.isEmpty) {
        filteredCampaigns = List.from(_allCampaigns);
      } else {
        filteredCampaigns = _allCampaigns.where((campaign) {
          final locale = context.locale.languageCode;
          final campaignCategory = campaign.getLocalizedCategory(locale).trim().toLowerCase();
          return matcherValues.contains(campaignCategory);
        }).toList();
      }
    }

    // Apply search filter
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      final locale = context.locale.languageCode;
      filteredCampaigns = filteredCampaigns.where((campaign) {
        final title = campaign.getLocalizedTitle(locale).toLowerCase();
        final description = campaign.getLocalizedDescription(locale).toLowerCase();
        final category = campaign.getLocalizedCategory(locale).toLowerCase();
        
        // Also search in all language versions for better search results
        final titleAr = campaign.titleAr.toLowerCase();
        final titleEn = campaign.titleEn.toLowerCase();
        final descriptionAr = campaign.descriptionAr.toLowerCase();
        final descriptionEn = campaign.descriptionEn.toLowerCase();
        final categoryAr = campaign.categoryAr.toLowerCase();
        final categoryEn = campaign.categoryEn.toLowerCase();
        
        return title.contains(searchQuery) ||
            titleAr.contains(searchQuery) ||
            titleEn.contains(searchQuery) ||
            description.contains(searchQuery) ||
            descriptionAr.contains(searchQuery) ||
            descriptionEn.contains(searchQuery) ||
            category.contains(searchQuery) ||
            categoryAr.contains(searchQuery) ||
            categoryEn.contains(searchQuery);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      _campaigns = filteredCampaigns;
    });
  }

  Widget? _buildSearchSuffixIcon() {
    if (_searchController.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(
          Icons.clear,
          color: AppColors.textSecondary,
          size: 16,
        ),
        onPressed: () {
          _searchController.clear();
          _applyFilters();
        },
      );
    }
    return null;
  }

  Widget _buildFilterChip({required String id, required String label}) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => _applyCategoryFilter(id),
        selectedColor: AppColors.surface,
        backgroundColor: AppColors.surface,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDonationCard({
    required String donorName,
    required double amount,
    String? campaignTitle,
    required String timeAgo,
    required bool isAnonymous,
  }) {
    final String donorInitial = donorName.trim().isNotEmpty ? donorName.trim()[0] : '?';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.06),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.18),
                      AppColors.secondary.withOpacity(0.08),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -28,
              bottom: -32,
              child: Icon(
                Icons.volunteer_activism,
                size: 120,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.35),
                              AppColors.secondary.withOpacity(0.25),
                            ],
                          ),
                        ),
                        child: Center(
                          child: isAnonymous
                              ? Icon(
                                  Icons.person_outline,
                                  size: 22,
                                  color: AppColors.primaryDark,
                                )
                              : Text(
                                  donorInitial,
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.primaryDark,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              donorName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: AppColors.textSecondary.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    timeAgo,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary.withOpacity(0.85),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  '${amount.toStringAsFixed(0)} ${'riyal'.tr()}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (campaignTitle != null && campaignTitle.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.campaign,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              campaignTitle,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.14),
                          AppColors.secondary.withOpacity(0.14),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'help_achieve_hope'.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: AppColors.softGradient,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAnonymous ? Icons.shield_outlined : Icons.verified,
                                size: 13,
                                color: AppColors.secondaryDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'donor'.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.secondaryDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDonationsList() {
    if (_isLoadingRecentDonations) {
      return SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_recentDonations.isEmpty) {
      return SizedBox(
        height: 150,
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
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 0, right: 0),
        itemCount: _recentDonations.length,
        itemBuilder: (context, index) {
          final donation = _recentDonations[index];
          final String? campaignName = donation.getLocalizedCampaignName(context.locale.languageCode)?.trim();
          final String? programName = donation.programName?.trim();
          final String? campaignTitle =
              (campaignName != null && campaignName.isNotEmpty) ? campaignName : (programName != null && programName.isNotEmpty) ? programName : null;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 280,
              child: _buildRecentDonationCard(
                donorName: 'donor'.tr(),
                amount: donation.amount,
                campaignTitle: campaignTitle,
                timeAgo: _formatTimeAgo(donation.date),
                isAnonymous: donation.isAnonymous,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewAllButton() {
    return GestureDetector(
      onTap: _onViewAllCampaigns,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'view_all'.tr(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.primary,
            size: 12,
          ),
        ],
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