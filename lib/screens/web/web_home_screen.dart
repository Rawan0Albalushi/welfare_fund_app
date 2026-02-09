import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../models/campaign.dart';
import '../../models/donation.dart';
import '../../models/app_banner.dart';
import '../../services/campaign_service.dart';
import '../../services/donation_service.dart';
import '../../services/banner_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/web/web_scaffold.dart';
import '../../widgets/web/web_home_content.dart';
import '../quick_donate_amount_screen.dart';
import '../all_campaigns_screen.dart';
import '../campaign_donation_screen.dart';
import '../student_registration_screen.dart';
import '../my_donations_screen.dart';
import '../settings_screen.dart';
import '../login_screen.dart';
import '../register_screen.dart';

/// الشاشة الرئيسية للويب
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final CampaignService _campaignService = CampaignService();
  final DonationService _donationService = DonationService();
  final BannerService _bannerService = BannerService();

  List<Campaign> _campaigns = [];
  List<Donation> _recentDonations = [];
  List<AppBanner> _banners = [];
  bool _isLoadingCampaigns = false;
  bool _isLoadingDonations = false;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCampaigns(),
      _loadRecentDonations(),
      _loadBanners(),
    ]);
  }

  Future<void> _loadCampaigns() async {
    if (!mounted) return;
    setState(() => _isLoadingCampaigns = true);

    try {
      final campaigns = await _campaignService.getCharityCampaigns();
      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _isLoadingCampaigns = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCampaigns = false);
      print('Error loading campaigns: $e');
    }
  }

  Future<void> _loadRecentDonations() async {
    if (!mounted) return;
    setState(() => _isLoadingDonations = true);

    try {
      final donations = await _donationService.getRecentDonations(limit: 5);
      if (!mounted) return;
      setState(() {
        _recentDonations = donations;
        _isLoadingDonations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDonations = false);
      print('Error loading donations: $e');
    }
  }

  Future<void> _loadBanners() async {
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

      if (!mounted) return;
      setState(() => _banners = combined);
    } catch (e) {
      print('Error loading banners: $e');
    }
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Home
        setState(() => _selectedNavIndex = 0);
        _loadData();
        break;
      case 1: // Campaigns
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllCampaignsScreen(initialCampaigns: _campaigns),
          ),
        );
        break;
      case 2: // Quick Donate
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QuickDonateAmountScreen(),
          ),
        );
        break;
      case 3: // My Donations
        _handleMyDonations();
        break;
      case 4: // Student Registration
        _handleStudentRegistration();
        break;
      case 5: // Settings
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
        break;
      case 6: // Login
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
        break;
      case 7: // Register
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterScreen(),
          ),
        );
        break;
    }
  }

  void _handleMyDonations() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MyDonationsScreen(),
        ),
      );
    } else {
      _showLoginDialog();
    }
  }

  void _handleStudentRegistration() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StudentRegistrationScreen(),
        ),
      );
    } else {
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'login_required'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'login_to_view_donations'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            child: Text('login'.tr()),
          ),
        ],
      ),
    );
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
    return WebScaffold(
      selectedIndex: _selectedNavIndex,
      onNavigationChanged: _handleNavigation,
      body: WebHomeContent(
        campaigns: _campaigns,
        recentDonations: _recentDonations,
        banners: _banners,
        isLoadingCampaigns: _isLoadingCampaigns,
        isLoadingDonations: _isLoadingDonations,
        onCampaignTap: _onCampaignTap,
        onQuickDonate: () => _handleNavigation(2),
        onViewAllCampaigns: () => _handleNavigation(1),
        onStudentRegistration: () => _handleNavigation(4),
        onMyDonations: () => _handleNavigation(3),
      ),
    );
  }
}

