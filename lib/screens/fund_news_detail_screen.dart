import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../constants/app_config.dart';
import '../models/fund_news.dart';

class FundNewsDetailScreen extends StatelessWidget {
  final FundNews news;

  const FundNewsDetailScreen({super.key, required this.news});

  static String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.serverBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path.replaceFirst('/', '') : path;
    return '$base/image/$p';
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final title = news.getLocalizedTitle(locale);
    final content = news.getLocalizedContent(locale);
    final imageUrl = _resolveImageUrl(news.image);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderBackground(),
                      )
                    : _placeholderBackground(),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.extraLargeRadius),
                    topRight: Radius.circular(AppConstants.extraLargeRadius),
                  ),
                ),
                transform: Matrix4.translationValues(0, -20, 0),
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.largePadding,
                  AppConstants.largePadding,
                  AppConstants.largePadding,
                  AppConstants.extraLargePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (news.isFeatured)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'fund_news_featured_badge'.tr(),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      title,
                      style: AppTextStyles.headlineMedium,
                    ),
                    if (news.publishedAt != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(news.publishedAt!),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppConstants.largePadding),
                    Container(
                      height: 1,
                      color: AppColors.surfaceVariant,
                    ),
                    const SizedBox(height: AppConstants.largePadding),
                    if (content.isNotEmpty)
                      SelectableText(
                        content,
                        style: AppTextStyles.bodyLarge.copyWith(
                          height: 1.7,
                          color: AppColors.textPrimary,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'fund_news_no_content'.tr(),
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _placeholderBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Center(
        child: Icon(Icons.article_rounded, size: 80, color: Colors.white.withOpacity(0.5)),
      ),
    );
  }
}
