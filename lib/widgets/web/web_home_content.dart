import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/campaign.dart';
import '../../models/donation.dart';
import '../../models/app_banner.dart';
import '../responsive/responsive_layout.dart';
import 'web_campaign_grid.dart';

/// محتوى الصفحة الرئيسية للويب - تصميم عصري وجذاب
class WebHomeContent extends StatelessWidget {
  final List<Campaign> campaigns;
  final List<Donation> recentDonations;
  final List<AppBanner> banners;
  final bool isLoadingCampaigns;
  final bool isLoadingDonations;
  final Function(Campaign) onCampaignTap;
  final VoidCallback onQuickDonate;
  final VoidCallback onViewAllCampaigns;
  final VoidCallback onStudentRegistration;
  final VoidCallback onMyDonations;
  
  const WebHomeContent({
    super.key,
    required this.campaigns,
    required this.recentDonations,
    required this.banners,
    required this.isLoadingCampaigns,
    required this.isLoadingDonations,
    required this.onCampaignTap,
    required this.onQuickDonate,
    required this.onViewAllCampaigns,
    required this.onStudentRegistration,
    required this.onMyDonations,
  });
  
  @override
  Widget build(BuildContext context) {
    final info = ResponsiveLayout.getResponsiveInfo(context);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Section - Full Width
          _buildHeroSection(context, info),
          
          // Main Content with padding
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: info.horizontalPadding,
              vertical: 48,
            ),
            child: CenteredContent(
              maxWidth: 1400,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campaigns Section
                  _buildCampaignsSection(context, info),
                  
                  const SizedBox(height: 64),
                  
                  // Recent Donations
                  _buildRecentDonationsSection(context, info),
                  
                  const SizedBox(height: 64),
                  
                  // Student Registration CTA
                  _buildStudentCTA(context, info),
                ],
              ),
            ),
          ),
          
          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }
  
  Widget _buildHeroSection(BuildContext context, ResponsiveInfo info) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: info.isDesktop ? 24 : 16,
        vertical: info.isDesktop ? 24 : 16,
      ),
      constraints: BoxConstraints(
        minHeight: info.isDesktop ? 520 : 420,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.9),
            AppColors.secondary.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(info.isDesktop ? 32 : 24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.2),
            blurRadius: 60,
            offset: const Offset(0, 30),
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(info.isDesktop ? 32 : 24),
        child: Stack(
          children: [
            // Background Pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _HeroPatternPainter(),
              ),
            ),
            
            // Content
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: info.horizontalPadding,
                    vertical: info.isDesktop ? 70 : 50,
                  ),
                  child: info.isDesktop
                      ? _buildDesktopHero(context)
                      : _buildMobileHero(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDesktopHero(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge - Enhanced
              _AnimatedFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.volunteer_activism,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'app_title'.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              // Title - Enhanced
              _AnimatedFadeSlide(
                delay: const Duration(milliseconds: 400),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.95),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'hero_title'.tr(),
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 52,
                      height: 1.15,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Subtitle - Enhanced
              _AnimatedFadeSlide(
                delay: const Duration(milliseconds: 600),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    'hero_subtitle'.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      height: 1.75,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 44),
              
              // Buttons - Enhanced
              _AnimatedFadeSlide(
                delay: const Duration(milliseconds: 800),
                child: Row(
                  children: [
                    _HeroButton(
                      label: 'donate_now'.tr(),
                      icon: Icons.favorite_rounded,
                      isPrimary: true,
                      onTap: onQuickDonate,
                    ),
                    const SizedBox(width: 18),
                    _HeroButton(
                      label: 'view_campaigns'.tr(),
                      icon: Icons.campaign_rounded,
                      isPrimary: false,
                      onTap: onViewAllCampaigns,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 70),
        Expanded(
          flex: 2,
          child: _AnimatedFadeSlide(
            delay: const Duration(milliseconds: 600),
            slideOffset: const Offset(50, 0),
            child: _buildHeroIllustration(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileHero(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Badge for mobile
        _AnimatedFadeSlide(
          delay: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volunteer_activism,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'app_title'.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _AnimatedFadeSlide(
          delay: const Duration(milliseconds: 200),
          child: Text(
            'hero_title'.tr(),
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.15,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        _AnimatedFadeSlide(
          delay: const Duration(milliseconds: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'hero_subtitle'.tr(),
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.65,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 36),
        _AnimatedFadeSlide(
          delay: const Duration(milliseconds: 600),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              _HeroButton(
                label: 'donate_now'.tr(),
                icon: Icons.favorite_rounded,
                isPrimary: true,
                onTap: onQuickDonate,
              ),
              _HeroButton(
                label: 'view_campaigns'.tr(),
                icon: Icons.campaign_rounded,
                isPrimary: false,
                onTap: onViewAllCampaigns,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeroIllustration() {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background pattern for illustration
            Positioned.fill(
              child: CustomPaint(
                painter: _IllustrationPatternPainter(),
              ),
            ),
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main icon with glow effect
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 25,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'every_donation_matters'.tr(),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCampaignsSection(BuildContext context, ResponsiveInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              title: 'featured_campaigns'.tr(),
              icon: Icons.star_rounded,
            ),
            _ViewAllButton(onTap: onViewAllCampaigns),
          ],
        ),
        const SizedBox(height: 24),
        WebCampaignGrid(
          campaigns: campaigns,
          onCampaignTap: onCampaignTap,
          isLoading: isLoadingCampaigns,
          maxItems: info.isDesktop ? 6 : 4,
        ),
      ],
    );
  }
  
  Widget _buildRecentDonationsSection(BuildContext context, ResponsiveInfo info) {
    if (recentDonations.isEmpty && !isLoadingDonations) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'recent_donations'.tr(),
          icon: Icons.access_time_rounded,
        ),
        const SizedBox(height: 24),
        if (isLoadingDonations)
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        else
          _AnimatedFadeSlide(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.surfaceVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: recentDonations.take(5).toList().asMap().entries.map((entry) {
                  return _DonationItem(
                    donation: entry.value,
                    isLast: entry.key == recentDonations.length - 1,
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildStudentCTA(BuildContext context, ResponsiveInfo info) {
    return _AnimatedFadeSlide(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(info.isDesktop ? 56 : 36),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary,
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Pattern
            Positioned(
              right: -50,
              top: -50,
              child: Icon(
                Icons.school_rounded,
                size: 200,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            // Content
            info.isDesktop
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'student_cta_title'.tr(),
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'student_cta_subtitle'.tr(),
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      _HeroButton(
                        label: 'register_now'.tr(),
                        icon: Icons.school_rounded,
                        isPrimary: true,
                        onTap: onStudentRegistration,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Text(
                        'student_cta_title'.tr(),
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'student_cta_subtitle'.tr(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      _HeroButton(
                        label: 'register_now'.tr(),
                        icon: Icons.school_rounded,
                        isPrimary: true,
                        onTap: onStudentRegistration,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
      ),
      child: Center(
        child: Text(
          '© 2024 ${'app_title'.tr()} - ${'app_subtitle'.tr()}',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

// ========== Hero Pattern Painter ==========
class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Draw grid pattern
    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw decorative dots at intersections
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    for (double x = 0; x < size.width; x += spacing * 2) {
      for (double y = 0; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========== Illustration Pattern Painter ==========
class _IllustrationPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Draw diagonal lines
    const spacing = 25.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ========== Animated Fade Slide ==========
class _AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset slideOffset;
  
  const _AnimatedFadeSlide({
    required this.child,
    this.delay = Duration.zero,
    this.slideOffset = const Offset(0, 30),
  });

  @override
  State<_AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<_AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ========== Section Header ==========
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  
  const _SectionHeader({
    required this.title,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppColors.modernGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ========== View All Button ==========
class _ViewAllButton extends StatefulWidget {
  final VoidCallback onTap;
  
  const _ViewAllButton({required this.onTap});

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'view_all'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(_isHovered ? 4 : 0, 0, 0),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== Hero Button ==========
class _HeroButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;
  
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
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
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -3.0 : 0.0)
            ..scale(_isHovered ? 1.02 : 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
          decoration: BoxDecoration(
            gradient: widget.isPrimary 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.95),
                    ],
                  )
                : null,
            color: widget.isPrimary 
                ? null 
                : (_isHovered ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
            border: widget.isPrimary 
                ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
                : Border.all(
                    color: Colors.white.withOpacity(_isHovered ? 0.5 : 0.35),
                    width: 1.5,
                  ),
            boxShadow: widget.isPrimary ? [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.25 : 0.15),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 15 : 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 1,
                spreadRadius: 0,
              ),
            ] : [
              BoxShadow(
                color: Colors.white.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 20 : 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.isPrimary 
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isPrimary ? AppColors.primary : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: AppTextStyles.buttonLarge.copyWith(
                  color: widget.isPrimary ? AppColors.primary : Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== Donation Item ==========
class _DonationItem extends StatefulWidget {
  final Donation donation;
  final bool isLast;
  
  const _DonationItem({
    required this.donation,
    required this.isLast,
  });

  @override
  State<_DonationItem> createState() => _DonationItemState();
}

class _DonationItemState extends State<_DonationItem> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surfaceVariant.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: widget.isLast ? null : Border(
            bottom: BorderSide(
              color: AppColors.surfaceVariant,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.softGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  widget.donation.isAnonymous ? Icons.person_outline : Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'donor'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.donation.getLocalizedCampaignName(context.locale.languageCode) != null)
                    Text(
                      widget.donation.getLocalizedCampaignName(context.locale.languageCode)!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                '${widget.donation.amount.toStringAsFixed(0)} ${'riyal'.tr()}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
