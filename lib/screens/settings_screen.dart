import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/language_switcher.dart';
import 'login_screen.dart' as login;
import 'edit_profile_screen.dart';
import 'my_donations_screen.dart';
import 'settings/setting_page_screen.dart';
import 'fund_partners_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    // Auth status is now managed by AuthProvider
    // No need to check here as it's handled globally
  }

  void _onBottomNavigationTap(int index, bool isAuthenticated) {
    if (index == 2) {
      // Already on Settings page - refresh by rebuilding (AuthProvider will handle updates)
      setState(() {});
      return;
    }

    if (index == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (index == 1) {
      if (isAuthenticated) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyDonationsScreen(),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const login.LoginScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userProfile = authProvider.userProfile;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppColors.surface),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.surface),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'settings'.tr(),
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
            actions: const [
              LanguageSwitcher(),
            ],
          ),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Conditional content based on authentication status
                      if (isAuthenticated) ...[
                        _buildAuthenticatedUserContent(userProfile),
                      ] else ...[
                        _buildGuestUserContent(),
                      ],
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 2,
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

  Widget _buildGuestUserContent() {
    return Column(
      children: [
        // Welcome Card for Guest Users
        _buildGuestWelcomeCard(),
        const SizedBox(height: 30),
        
        // Login Button
        _buildLoginButton(),
        const SizedBox(height: 20),
        
        // Language Settings
        _buildSectionTitle('language_settings'.tr()),
        const SizedBox(height: 15),
        _buildLanguageSettingsCard(),
        const SizedBox(height: 25),
        
        // Support Section
        _buildSectionTitle('support_help'.tr()),
        const SizedBox(height: 15),
        _buildSupportCard(),
        const SizedBox(height: 25),
        
        // Follow Us Section
        _buildFollowUsSection(),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildAuthenticatedUserContent(Map<String, dynamic>? userProfile) {
    return Column(
      children: [
        // Profile Section for Authenticated Users
        _buildAuthenticatedProfileSection(userProfile),
        const SizedBox(height: 30),
        
        // Account Settings
        _buildSectionTitle('account_settings'.tr()),
        const SizedBox(height: 15),
        _buildAccountSettingsCard(userProfile),
        const SizedBox(height: 25),
        
        // Language Settings
        _buildSectionTitle('language_settings'.tr()),
        const SizedBox(height: 15),
        _buildLanguageSettingsCard(),
        const SizedBox(height: 25),
        
        // Support Section
        _buildSectionTitle('support_help'.tr()),
        const SizedBox(height: 15),
        _buildSupportCard(),
        const SizedBox(height: 25),
        
        // Follow Us Section
        _buildFollowUsSection(),
        const SizedBox(height: 25),
        
        // Logout Button
        _buildLogoutButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGuestWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon and Welcome Text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite_outline,
              size: 40,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'welcome'.tr(),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            'make_difference'.tr(),
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.surface.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          Text(
            'login_to_view_donations'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.surface.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedProfileSection(Map<String, dynamic>? userProfile) {
    final userName = userProfile?['name'] ?? userProfile?['user']?['name'] ?? 'user'.tr();
    final userEmail = userProfile?['email'] ?? userProfile?['user']?['email'] ?? '';
    final userPhone = userProfile?['phone'] ?? userProfile?['user']?['phone'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: AppColors.surface.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(width: 20),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (userEmail.isNotEmpty) ...[
                  Text(
                    userEmail,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  userPhone,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.surface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'active_user'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: AppColors.modernGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsCard(Map<String, dynamic>? userProfile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'edit_profile'.tr(),
            subtitle: 'edit_profile'.tr(),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    userProfile: userProfile,
                  ),
                ),
              );
              
              // Refresh user profile if updated
              if (result == true) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.refreshProfile();
              }
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'security_privacy'.tr(),
            subtitle: 'security_privacy'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingPageScreen(
                    pageKey: 'security',
                  ),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.history,
            title: 'my_donations'.tr(),
            subtitle: 'my_donations'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyDonationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }



  Widget _buildSupportCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.contact_support_outlined,
            title: 'contact_us'.tr(),
            subtitle: 'message_support_team'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingPageScreen(
                    pageKey: 'contact_us',
                  ),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.handshake_rounded,
            title: 'fund_partners'.tr(),
            subtitle: 'fund_partners_tile_subtitle'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FundPartnersScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'about_app'.tr(),
            subtitle: 'app_info_version'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingPageScreen(
                    pageKey: 'about_app',
                  ),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'privacy_policy'.tr(),
            subtitle: 'read_privacy_policy'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingPageScreen(
                    pageKey: 'privacy_policy',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 26,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textTertiary,
          size: 16,
        ),
      ),
      onTap: onTap,
    );
  }



  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 90,
      endIndent: 20,
      color: AppColors.surfaceVariant,
    );
  }

  Widget _buildFollowUsSection() {
    return Column(
      children: [
        _buildSectionTitle('follow_us'.tr()),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceVariant,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'follow_us'.tr(),
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'stay_connected'.tr(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSimpleSocialButton(
                  icon: FontAwesomeIcons.instagram,
                  isFontAwesome: true,
                  color: const Color(0xFFE4405F),
                  onTap: () {
                    _openInstagramLink();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleSocialButton({
    required dynamic icon,
    required Color color,
    required VoidCallback onTap,
    bool isFontAwesome = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: isFontAwesome
            ? FaIcon(
                icon,
                color: color,
                size: 22,
              )
            : Icon(
                icon,
                color: color,
                size: 22,
              ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.modernGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const login.LoginScreen(),
              ),
            ).then((_) => _checkAuthStatus());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.login,
                  color: AppColors.surface,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Text(
                  'login'.tr(),
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            _showLogoutDialog();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout,
                  color: AppColors.error,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Text(
                  'logout'.tr(),
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'logout'.tr(),
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'logout_confirmation'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr(),
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              child: Text(
                'confirm'.tr(),
                style: AppTextStyles.buttonMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    NavigatorState? dialogNavigator;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogBuilderContext) {
          dialogNavigator ??= Navigator.of(dialogBuilderContext);
          return AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'logging_out'.tr(),
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Get auth provider and logout
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      // Close loading dialog
      dialogNavigator?.pop();
      dialogNavigator = null;

      if (!mounted) return;

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'logout_successful'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.surface,
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

      // Navigate back to home screen and clear navigation stack
      navigator.pushNamedAndRemoveUntil(
        AppConstants.homeRoute,
        (route) => false,
      );
    } catch (error) {
      // Close loading dialog
      dialogNavigator?.pop();
      dialogNavigator = null;

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            '${'logout_error'.tr()}: ${error.toString()}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.surface,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  Widget _buildLanguageSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLanguageTile(
            icon: Icons.language,
            title: 'choose_language'.tr(),
            subtitle: 'current_language'.tr(),
            currentLocale: context.locale,
            onTap: () {
              _showLanguageDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Locale currentLocale,
    required VoidCallback onTap,
  }) {
    String currentLanguage = currentLocale.languageCode == 'ar' 
        ? 'arabic'.tr() 
        : 'english'.tr();
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$subtitle: $currentLanguage',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'choose_language'.tr(),
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context: context,
                locale: const Locale('ar'),
                languageName: 'arabic'.tr(),
                flag: '🇴🇲',
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context: context,
                locale: const Locale('en'),
                languageName: 'english'.tr(),
                flag: '🇺🇸',
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required Locale locale,
    required String languageName,
    required String flag,
  }) {
    bool isSelected = context.locale.languageCode == locale.languageCode;
    
    return InkWell(
      onTap: () {
        context.setLocale(locale);
        Navigator.of(context).pop();
        
        // Force rebuild of the entire app
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // This will trigger a rebuild of the entire app
          if (context.mounted) {
            // Navigate to home to refresh the entire app
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary
                : AppColors.textTertiary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageName,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isSelected 
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: isSelected 
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInstagramLink() async {
    const instagramUrl = 'https://www.instagram.com/welfarefund4stu?igsh=M212OGhhejB5azFs';
    
    try {
      HapticFeedback.lightImpact();
      
      if (await canLaunchUrlString(instagramUrl)) {
        await launchUrlString(
          instagramUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'cannot_open_link'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.surface,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'error_opening_link'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.surface,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }
}
