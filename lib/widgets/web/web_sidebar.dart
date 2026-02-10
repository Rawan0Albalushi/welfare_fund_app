import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// قائمة التنقل الجانبية للويب (Desktop)
class WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  
  const WebSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          _buildLogoSection(context),
          
          const SizedBox(height: 8),
          
          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.home_rounded,
                    label: 'home'.tr(),
                    index: 0,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.campaign_rounded,
                    label: 'campaigns'.tr(),
                    index: 1,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.favorite_rounded,
                    label: 'quick_donate'.tr(),
                    index: 2,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.newspaper_rounded,
                    label: 'fund_news'.tr(),
                    index: 3,
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  
                  _buildNavItem(
                    context: context,
                    icon: Icons.school_rounded,
                    label: 'student_registration'.tr(),
                    index: 4,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.settings_rounded,
                    label: 'settings'.tr(),
                    index: 5,
                  ),
                ],
              ),
            ),
          ),
          
          // User Section
          _buildUserSection(context),
        ],
      ),
    );
  }
  
  Widget _buildLogoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: AppColors.modernGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Logo Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.volunteer_activism,
                color: AppColors.surface,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            // App Name
            Text(
              'app_title'.tr(),
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'app_subtitle'.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.surface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isSelected ? LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ) : null,
              border: isSelected ? Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ) : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary.withOpacity(0.15) 
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: AppColors.modernGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userProfile = authProvider.userProfile;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            border: Border(
              top: BorderSide(
                color: AppColors.textTertiary.withOpacity(0.2),
              ),
            ),
          ),
          child: isAuthenticated ? _buildLoggedInUser(context, userProfile) 
                                : _buildLoginButton(context),
        );
      },
    );
  }
  
  Widget _buildLoggedInUser(BuildContext context, Map<String, dynamic>? userProfile) {
    final name = userProfile?['name'] ?? userProfile?['full_name'] ?? 'مستخدم';
    final email = userProfile?['email'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    return Row(
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.modernGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              initial,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // Logout
        IconButton(
          onPressed: () {
            context.read<AuthProvider>().logout();
          },
          icon: const Icon(Icons.logout_rounded),
          color: AppColors.textSecondary,
          tooltip: 'logout'.tr(),
        ),
      ],
    );
  }
  
  Widget _buildLoginButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(6), // Login index
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.modernGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.login_rounded,
                color: AppColors.surface,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'login'.tr(),
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

