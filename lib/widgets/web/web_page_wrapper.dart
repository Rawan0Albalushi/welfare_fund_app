import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../responsive/responsive_layout.dart';
import 'web_header.dart';

/// غلاف للصفحات يضيف الهيدر والتصميم المتجاوب للويب
class WebPageWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool centerContent;
  final double? maxWidth;
  
  const WebPageWrapper({
    super.key,
    required this.child,
    this.title,
    this.showBackButton = true,
    this.actions,
    this.backgroundColor,
    this.centerContent = true,
    this.maxWidth,
  });
  
  @override
  Widget build(BuildContext context) {
    // إذا لم يكن ويب، أرجع الطفل مباشرة
    if (!kIsWeb) {
      return child;
    }
    
    final info = ResponsiveLayout.getResponsiveInfo(context);
    
    // للشاشات الصغيرة، أرجع الطفل مباشرة
    if (!info.isDesktop && !info.isTablet) {
      return child;
    }
    
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      body: Column(
        children: [
          // Header
          WebHeader(
            selectedIndex: -1, // No selection for inner pages
            onItemSelected: (index) => _handleNavigation(context, index),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Page Header
                  if (title != null)
                    _buildPageHeader(context, info),
                  
                  // Main Content
                  if (centerContent)
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth ?? info.maxContentWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: info.horizontalPadding,
                            vertical: 32,
                          ),
                          child: child,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: info.horizontalPadding,
                        vertical: 32,
                      ),
                      child: child,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPageHeader(BuildContext context, ResponsiveInfo info) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: info.horizontalPadding,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.modernGradient,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? info.maxContentWidth),
          child: Row(
            children: [
              if (showBackButton)
                _BackButton(onTap: () => Navigator.pop(context)),
              if (showBackButton) const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title!,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1: // Campaigns
        Navigator.pushNamed(context, '/campaigns');
        break;
      case 2: // Quick Donate
        Navigator.pushNamed(context, '/quick-donate');
        break;
      case 3: // My Donations
        Navigator.pushNamed(context, '/my-donations');
        break;
      case 4: // Student Registration
        Navigator.pushNamed(context, '/student-registration');
        break;
      case 5: // Settings
        Navigator.pushNamed(context, '/settings');
        break;
      case 6: // Login
        Navigator.pushNamed(context, '/login');
        break;
      case 7: // Register
        Navigator.pushNamed(context, '/register');
        break;
    }
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered 
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(_isHovered ? 0.4 : 0.2),
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// غلاف بسيط للمحتوى في الويب بدون header
class WebContentWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  
  const WebContentWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    
    final info = ResponsiveLayout.getResponsiveInfo(context);
    
    if (!info.isDesktop && !info.isTablet) {
      return child;
    }
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? info.maxContentWidth,
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: info.horizontalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

