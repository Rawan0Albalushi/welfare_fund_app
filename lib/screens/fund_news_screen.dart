import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../constants/app_config.dart';
import '../models/fund_news.dart';
import '../services/fund_news_service.dart';
import 'fund_news_detail_screen.dart';

class FundNewsScreen extends StatefulWidget {
  const FundNewsScreen({super.key});

  @override
  State<FundNewsScreen> createState() => _FundNewsScreenState();
}

class _FundNewsScreenState extends State<FundNewsScreen> {
  final FundNewsService _service = FundNewsService();
  List<FundNews> _news = [];
  List<FundNews> _featured = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _service.getActiveNews(),
        _service.getFeaturedNews(),
      ]);
      if (!mounted) return;
      setState(() {
        _news = results[0];
        _featured = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'fund_news_error_load'.tr();
      });
    }
  }

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.serverBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path.replaceFirst('/', '') : path;
    return '$base/image/$p';
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.surface),
        title: Text(
          'fund_news'.tr(),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.surface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surface, size: 22),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.largePadding,
                ),
                child: _buildBody(locale),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppConstants.extraLargePadding)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String locale) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.extraLargePadding),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'loading'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.extraLargePadding),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                label: Text('retry'.tr(), style: const TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    if (_news.isEmpty && _featured.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.extraLargePadding),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.newspaper_rounded, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'fund_news_empty'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.defaultPadding),
        if (_featured.isNotEmpty) ...[
          Text(
            'fund_news_featured'.tr(),
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          SizedBox(
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _featured.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 14,
                    right: 14,
                  ),
                  child: _NewsCard(
                    news: _featured[index],
                    locale: locale,
                    resolveImage: _resolveImageUrl,
                    onTap: () => _openDetail(_featured[index]),
                    isFeatured: true,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
        ],
        Text(
          'fund_news_all'.tr(),
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ..._news.where((item) => !_featured.any((f) => f.id == item.id)).map((item) => Padding(
              padding: const EdgeInsets.only(
                top: AppConstants.smallPadding,
                bottom: AppConstants.defaultPadding,
              ),
              child: _NewsCard(
                news: item,
                locale: locale,
                resolveImage: _resolveImageUrl,
                onTap: () => _openDetail(item),
                isFeatured: item.isFeatured,
              ),
            )),
      ],
    );
  }

  void _openDetail(FundNews item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FundNewsDetailScreen(news: item),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final FundNews news;
  final String locale;
  final String Function(String?) resolveImage;
  final VoidCallback onTap;
  final bool isFeatured;

  const _NewsCard({
    required this.news,
    required this.locale,
    required this.resolveImage,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImage(news.image);
    final title = news.getLocalizedTitle(locale);
    final content = news.getLocalizedContent(locale);
    final excerpt = content.length > 100 ? '${content.substring(0, 100)}...' : content;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFeatured ? 280 : double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isFeatured
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageUrl.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceVariant,
                          child: Icon(Icons.image_not_supported_rounded, color: AppColors.textTertiary, size: 40),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 140,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.article_rounded, size: 48, color: AppColors.textTertiary),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'fund_news_featured_badge'.tr(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.accentDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (news.publishedAt != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(news.publishedAt!),
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageUrl.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 2.2,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceVariant,
                          child: Icon(Icons.image_not_supported_rounded, color: AppColors.textTertiary, size: 40),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 140,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.article_rounded, size: 48, color: AppColors.textTertiary),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (excerpt.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            excerpt,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (news.publishedAt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(news.publishedAt!),
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
