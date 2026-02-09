import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// شريط التطبيق للويب (Tablet & smaller desktop)
class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;
  
  const WebAppBar({
    super.key,
    this.onMenuPressed,
    this.actions,
  });
  
  @override
  Size get preferredSize => const Size.fromHeight(70);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Menu Button
              if (onMenuPressed != null)
                IconButton(
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu_rounded),
                  color: AppColors.textPrimary,
                  iconSize: 28,
                ),
              
              const SizedBox(width: 16),
              
              // Logo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.modernGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Title
              Expanded(
                child: Text(
                  'app_title'.tr(),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              
              // Actions
              if (actions != null) ...actions!,
              
              // Auth Button
              _buildAuthButton(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAuthButton(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userProfile = authProvider.userProfile;
        
        if (isAuthenticated) {
          return _buildUserMenu(context, userProfile);
        }
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                // Navigate to login
                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                'login'.tr(),
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Navigate to register
                Navigator.pushNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'register'.tr(),
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildUserMenu(BuildContext context, Map<String, dynamic>? userProfile) {
    final name = userProfile?['name'] ?? userProfile?['full_name'] ?? 'مستخدم';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.modernGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 20),
              const SizedBox(width: 12),
              Text('profile'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'donations',
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 20),
              const SizedBox(width: 12),
              Text('my_donations'.tr()),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
              const SizedBox(width: 12),
              Text(
                'logout'.tr(),
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          context.read<AuthProvider>().logout();
        }
        // Handle other menu items
      },
    );
  }
}

