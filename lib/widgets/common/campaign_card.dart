import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../models/campaign.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.1),
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
              _buildCampaignImage(campaign),
              // Completed Overlay (if campaign is completed)
              if (campaign.isCompleted)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                  ),
                ),
              // Gradient Overlay
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(campaign.isCompleted ? 0.8 : 0.7),
                    ],
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.smallPadding,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: campaign.isCompleted 
                              ? AppColors.success 
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          campaign.getLocalizedCategory(context.locale.languageCode).isNotEmpty
                              ? campaign.getLocalizedCategory(context.locale.languageCode)
                              : 'campaign'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        campaign.getLocalizedTitle(context.locale.languageCode),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: campaign.progressPercentage.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: campaign.isCompleted
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.success,
                                        AppColors.success.withOpacity(0.8),
                                      ],
                                    )
                                  : AppColors.modernGradient,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Amount and Donors
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${campaign.currentAmount.toStringAsFixed(0)} ريال',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  campaign.isCompleted
                                      ? 'campaign_goal_achieved'.tr()
                                      : 'من ${campaign.targetAmount.toStringAsFixed(0)} ريال',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Donate Button or Completed Status
                          if (campaign.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.smallPadding,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'completed'.tr(),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.smallPadding,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'donate_now'.tr(),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
  }

  // Build campaign image widget - use imageUrl directly from backend
  Widget _buildCampaignImage(Campaign campaign) {
    print('═══════════════════════════════════════════════════════════');
    print('🔍 CampaignCard: Building image for campaign: "${campaign.title}"');
    print('📋 Campaign ID: ${campaign.id}');
    print('📋 Campaign imageUrl from model: "${campaign.imageUrl}"');
    print('📋 Campaign imageUrl length: ${campaign.imageUrl.length}');
    print('📋 Campaign imageUrl isEmpty: ${campaign.imageUrl.isEmpty}');
    
    final imageUrl = campaign.imageUrl.trim();
    
    print('✅ Final imageUrl to use: "$imageUrl"');
    print('═══════════════════════════════════════════════════════════');
    
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          print('⏳ CampaignCard: Loading image from: $imageUrl');
          return Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight.withOpacity(0.3),
                  AppColors.secondaryLight.withOpacity(0.3),
                ],
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ CampaignCard: ERROR loading image from: $imageUrl');
          print('❌ CampaignCard: Error details: $error');
          print('❌ CampaignCard: Error type: ${error.runtimeType}');
          return Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight.withOpacity(0.3),
                  AppColors.secondaryLight.withOpacity(0.3),
                ],
              ),
            ),
          );
        },
      );
    }
    
    // Fallback if no image URL - show light gradient
    print('⚠️ CampaignCard: No image URL, showing gradient placeholder');
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.3),
            AppColors.secondaryLight.withOpacity(0.3),
          ],
        ),
      ),
    );
  }

}