import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// هيدر التنقل للويب - تصميم عصري وأنيق
class WebHeader extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  
  const WebHeader({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<WebHeader> createState() => _WebHeaderState();
}

class _WebHeaderState extends State<WebHeader> {
  bool _isScrolled = false;
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        // تأثير Glass morphism
        color: _isScrolled 
            ? AppColors.surface.withOpacity(0.95)
            : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(_isScrolled ? 0.1 : 0.05),
            blurRadius: _isScrolled ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              // Logo Section
              _buildLogo(context),
              
              const SizedBox(width: 60),
              
              // Navigation Items
              Expanded(
                child: _buildNavItems(context),
              ),
              
              const SizedBox(width: 32),
              
              // Auth Section
              _buildAuthSection(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onItemSelected(0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Logo
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            // App Name with Gradient
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ).createShader(bounds),
                  child: Text(
                    'app_title'.tr(),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'app_subtitle'.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavItems(BuildContext context) {
    final navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'home'.tr(), index: 0),
      _NavItem(icon: Icons.campaign_rounded, label: 'campaigns'.tr(), index: 1),
      _NavItem(icon: Icons.favorite_rounded, label: 'quick_donate'.tr(), index: 2),
      _NavItem(icon: Icons.newspaper_rounded, label: 'fund_news'.tr(), index: 3),
      _NavItem(icon: Icons.school_rounded, label: 'student_registration'.tr(), index: 4),
    ];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: navItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: _NavItemWidget(
                  item: item,
                  isSelected: widget.selectedIndex == item.index,
                  onTap: () => widget.onItemSelected(item.index),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildAuthSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userProfile = authProvider.userProfile;
        
        if (isAuthenticated) {
          return _buildUserMenu(context, userProfile);
        }
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Settings
                  _buildIconButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'settings'.tr(),
                    onTap: () => widget.onItemSelected(5),
                  ),
                  const SizedBox(width: 12),
                  // Login Button
                  _buildOutlinedButton(
                    label: 'login'.tr(),
                    onTap: () => widget.onItemSelected(6),
                  ),
                  const SizedBox(width: 10),
                  // Register Button
                  _buildGradientButton(
                    label: 'register'.tr(),
                    icon: Icons.person_add_rounded,
                    onTap: () => widget.onItemSelected(7),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return _HoverIconButton(
      icon: icon,
      tooltip: tooltip,
      onTap: onTap,
    );
  }
  
  Widget _buildOutlinedButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return _HoverOutlinedButton(
      label: label,
      onTap: onTap,
    );
  }
  
  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _HoverGradientButton(
      label: label,
      icon: icon,
      onTap: onTap,
    );
  }
  
  Widget _buildUserMenu(BuildContext context, Map<String, dynamic>? userProfile) {
    final name = userProfile?['name'] ?? userProfile?['full_name'] ?? 'مستخدم';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'settings'.tr(),
          onTap: () => widget.onItemSelected(5),
        ),
        const SizedBox(width: 16),
        _UserMenuButton(
          name: name,
          initial: initial,
          onDonations: () => widget.onItemSelected(3),
          onSettings: () => widget.onItemSelected(5),
          onLogout: () => context.read<AuthProvider>().logout(),
        ),
      ],
    );
  }
}

// ========== Navigation Item Widget ==========
class _NavItemWidget extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: widget.isSelected ? LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ) : (_isHovered ? LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ) : null),
              border: widget.isSelected ? Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.item.icon,
                    color: widget.isSelected 
                        ? AppColors.primary 
                        : (_isHovered ? AppColors.primary.withOpacity(0.8) : AppColors.textSecondary),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: widget.isSelected 
                        ? AppColors.primary 
                        : (_isHovered ? AppColors.primary.withOpacity(0.8) : AppColors.textSecondary),
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (widget.isSelected) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: AppColors.modernGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== Hover Icon Button ==========
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  
  const _HoverIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isHovered 
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered 
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

// ========== Hover Outlined Button ==========
class _HoverOutlinedButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  
  const _HoverOutlinedButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_HoverOutlinedButton> createState() => _HoverOutlinedButtonState();
}

class _HoverOutlinedButtonState extends State<_HoverOutlinedButton> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.primary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ========== Hover Gradient Button ==========
class _HoverGradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  
  const _HoverGradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HoverGradientButton> createState() => _HoverGradientButtonState();
}

class _HoverGradientButtonState extends State<_HoverGradientButton> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered 
                  ? [AppColors.primaryDark, AppColors.primary]
                  : [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(_isHovered ? 0.5 : 0.3),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== User Menu Button ==========
class _UserMenuButton extends StatefulWidget {
  final String name;
  final String initial;
  final VoidCallback onDonations;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  
  const _UserMenuButton({
    required this.name,
    required this.initial,
    required this.onDonations,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  State<_UserMenuButton> createState() => _UserMenuButtonState();
}

class _UserMenuButtonState extends State<_UserMenuButton> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: _isHovered ? LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.08),
                AppColors.secondary.withOpacity(0.05),
              ],
            ) : null,
            color: _isHovered ? null : AppColors.surfaceVariant.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered 
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.surfaceVariant,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.modernGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.initial,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'active_user'.tr(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 10),
              AnimatedRotation(
                turns: _isHovered ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _isHovered ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          _buildPopupItem(
            icon: Icons.person_outline_rounded,
            label: 'profile'.tr(),
            color: AppColors.primary,
            value: 'profile',
          ),
          _buildPopupItem(
            icon: Icons.history_rounded,
            label: 'my_donations'.tr(),
            color: AppColors.secondary,
            value: 'donations',
          ),
          _buildPopupItem(
            icon: Icons.settings_outlined,
            label: 'settings'.tr(),
            color: AppColors.accent,
            value: 'settings',
          ),
          const PopupMenuDivider(),
          _buildPopupItem(
            icon: Icons.logout_rounded,
            label: 'logout'.tr(),
            color: AppColors.error,
            value: 'logout',
            isDestructive: true,
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'donations':
              widget.onDonations();
              break;
            case 'settings':
              widget.onSettings();
              break;
            case 'logout':
              widget.onLogout();
              break;
          }
        },
      ),
    );
  }
  
  PopupMenuItem<String> _buildPopupItem({
    required IconData icon,
    required String label,
    required Color color,
    required String value,
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDestructive ? color : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  
  _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
