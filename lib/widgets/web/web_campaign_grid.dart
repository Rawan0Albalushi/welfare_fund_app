import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/campaign.dart';
import '../responsive/responsive_layout.dart';

/// شبكة الحملات للويب - تصميم عصري وجذاب
class WebCampaignGrid extends StatelessWidget {
  final List<Campaign> campaigns;
  final Function(Campaign) onCampaignTap;
  final bool isLoading;
  final int? maxItems;
  
  const WebCampaignGrid({
    super.key,
    required this.campaigns,
    required this.onCampaignTap,
    this.isLoading = false,
    this.maxItems,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingGrid(context);
    }
    
    if (campaigns.isEmpty) {
      return _buildEmptyState(context);
    }
    
    final info = ResponsiveLayout.getResponsiveInfo(context);
    final displayCampaigns = maxItems != null 
        ? campaigns.take(maxItems!).toList() 
        : campaigns;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: info.gridColumns,
        childAspectRatio: 0.85,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: displayCampaigns.length,
      itemBuilder: (context, index) {
        return _WebCampaignCard(
          campaign: displayCampaigns[index],
          onTap: () => onCampaignTap(displayCampaigns[index]),
          index: index,
        );
      },
    );
  }
  
  Widget _buildLoadingGrid(BuildContext context) {
    final info = ResponsiveLayout.getResponsiveInfo(context);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: info.gridColumns,
        childAspectRatio: 0.85,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _SkeletonCard(index: index);
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(64),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.surfaceVariant,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'no_active_campaigns'.tr(),
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'check_back_later'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة حملة للويب - تصميم عصري مع تأثيرات
class _WebCampaignCard extends StatefulWidget {
  final Campaign campaign;
  final VoidCallback onTap;
  final int index;
  
  const _WebCampaignCard({
    required this.campaign,
    required this.onTap,
    required this.index,
  });

  @override
  State<_WebCampaignCard> createState() => _WebCampaignCardState();
}

class _WebCampaignCardState extends State<_WebCampaignCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _onHover(bool hover) {
    setState(() => _isHovered = hover);
    if (hover) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isHovered 
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.surfaceVariant,
                      width: _isHovered ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isHovered 
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.textPrimary.withOpacity(0.08),
                        blurRadius: _isHovered ? 30 : 20,
                        offset: Offset(0, _isHovered ? 15 : 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Section
                        Expanded(
                          flex: 5,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Image
                              _buildCampaignImage(),
                              
                              // Gradient Overlay
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      stops: const [0.0, 0.4, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Category Badge
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: campaign.isCompleted 
                                        ? AppColors.success 
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (campaign.isCompleted 
                                            ? AppColors.success 
                                            : AppColors.primary).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    campaign.getLocalizedCategory(context.locale.languageCode).isNotEmpty
                                        ? campaign.getLocalizedCategory(context.locale.languageCode)
                                        : 'campaign'.tr(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Completed Badge
                              if (campaign.isCompleted)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.success.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              
                              // Title on image
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Text(
                                  campaign.getLocalizedTitle(context.locale.languageCode),
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Content Section
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Progress Bar
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Stack(
                                    children: [
                                      FractionallySizedBox(
                                        alignment: AlignmentDirectional.centerStart,
                                        widthFactor: campaign.progressPercentage.clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: campaign.isCompleted
                                                ? LinearGradient(
                                                    colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                                                  )
                                                : AppColors.modernGradient,
                                            borderRadius: BorderRadius.circular(5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (campaign.isCompleted 
                                                    ? AppColors.success 
                                                    : AppColors.primary).withOpacity(0.4),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Amount Info
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${campaign.currentAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                                            style: AppTextStyles.titleMedium.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            campaign.isCompleted
                                                ? 'campaign_goal_achieved'.tr()
                                                : '${'of'.tr()} ${campaign.targetAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Percentage Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: campaign.isCompleted
                                            ? AppColors.success.withOpacity(0.1)
                                            : AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: campaign.isCompleted
                                              ? AppColors.success.withOpacity(0.3)
                                              : AppColors.primary.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        '${(campaign.progressPercentage * 100).toStringAsFixed(0)}%',
                                        style: AppTextStyles.labelMedium.copyWith(
                                          color: campaign.isCompleted
                                              ? AppColors.success
                                              : AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const Spacer(),
                                
                                // Action Button
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: campaign.isCompleted
                                        ? null
                                        : (_isHovered ? AppColors.modernGradient : null),
                                    color: campaign.isCompleted
                                        ? AppColors.success.withOpacity(0.1)
                                        : (_isHovered ? null : AppColors.surfaceVariant),
                                    borderRadius: BorderRadius.circular(14),
                                    border: campaign.isCompleted
                                        ? Border.all(color: AppColors.success.withOpacity(0.3))
                                        : (_isHovered ? null : Border.all(color: AppColors.primary.withOpacity(0.2))),
                                    boxShadow: _isHovered && !campaign.isCompleted ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          campaign.isCompleted 
                                              ? Icons.check_circle_outline 
                                              : Icons.favorite_rounded,
                                          size: 20,
                                          color: campaign.isCompleted
                                              ? AppColors.success
                                              : (_isHovered ? Colors.white : AppColors.primary),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          campaign.isCompleted ? 'completed'.tr() : 'donate_now'.tr(),
                                          style: AppTextStyles.buttonMedium.copyWith(
                                            color: campaign.isCompleted
                                                ? AppColors.success
                                                : (_isHovered ? Colors.white : AppColors.primary),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildCampaignImage() {
    final imageUrl = widget.campaign.imageUrl.trim();
    
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    
    return _buildPlaceholder();
  }
  
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.secondary.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.campaign_rounded,
          size: 56,
          color: AppColors.primary.withOpacity(0.4),
        ),
      ),
    );
  }
}

/// Skeleton Card for loading state
class _SkeletonCard extends StatefulWidget {
  final int index;
  
  const _SkeletonCard({required this.index});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.surfaceVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image skeleton
                Expanded(
                  flex: 5,
                  child: AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.surfaceVariant,
                              AppColors.surfaceVariant.withOpacity(0.5),
                              AppColors.surfaceVariant,
                            ],
                            stops: [
                              _shimmerAnimation.value - 0.3,
                              _shimmerAnimation.value,
                              _shimmerAnimation.value + 0.3,
                            ].map((e) => e.clamp(0.0, 1.0)).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Content skeleton
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkeletonBar(width: double.infinity, height: 10),
                        const SizedBox(height: 16),
                        _buildSkeletonBar(width: 120, height: 16),
                        const SizedBox(height: 8),
                        _buildSkeletonBar(width: 80, height: 12),
                        const Spacer(),
                        _buildSkeletonBar(width: double.infinity, height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSkeletonBar({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surfaceVariant,
                AppColors.surfaceVariant.withOpacity(0.5),
                AppColors.surfaceVariant,
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}
