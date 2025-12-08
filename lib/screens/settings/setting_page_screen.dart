import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter_html/flutter_html.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/setting_page_provider.dart';
import '../../models/setting_page_model.dart';

class SettingPageScreen extends StatefulWidget {
  final String pageKey;

  const SettingPageScreen({
    super.key,
    required this.pageKey,
  });

  @override
  State<SettingPageScreen> createState() => _SettingPageScreenState();
}

class _SettingPageScreenState extends State<SettingPageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Fetch page data when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SettingPageProvider>(context, listen: false);
      provider.fetchPage(widget.pageKey);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final isRTL = locale == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<SettingPageProvider>(
          builder: (context, provider, child) {
            final title = provider.page?.getLocalizedTitle(locale) ?? '';
            return Text(
              title,
              style: AppTextStyles.appBarTitleLight,
            );
          },
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: textDirection,
        child: SafeArea(
          child: Consumer<SettingPageProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return _buildLoadingState();
              }

              if (provider.errorMessage != null) {
                return _buildErrorState(provider.errorMessage!, provider);
              }

              if (provider.page == null) {
                return _buildEmptyState();
              }

              return FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(provider.page!, locale, isRTL),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'loading'.tr(),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, SettingPageProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'error_occurred'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                provider.fetchPage(widget.pageKey);
              },
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_content'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'content_not_available'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SettingPageModel page, String locale, bool isRTL) {
    final content = page.getLocalizedContent(locale);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Html(
            data: content,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.6),
                color: AppColors.textPrimary,
                fontFamily: 'Calibri',
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),
              "p": Style(
                margin: Margins.only(bottom: 12),
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.6),
                color: AppColors.textPrimary,
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),
              "h1": Style(
                margin: Margins.only(bottom: 16, top: 8),
                fontSize: FontSize(24),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),
              "h2": Style(
                margin: Margins.only(bottom: 14, top: 8),
                fontSize: FontSize(22),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),
              "h3": Style(
                margin: Margins.only(bottom: 12, top: 8),
                fontSize: FontSize(20),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),
              "h4": Style(
                margin: Margins.only(bottom: 10, top: 8),
                fontSize: FontSize(18),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),
              "ul": Style(
                margin: Margins.only(bottom: 12),
                padding: HtmlPaddings.only(left: 20),
              ),
              "ol": Style(
                margin: Margins.only(bottom: 12),
                padding: HtmlPaddings.only(left: 20),
              ),
              "li": Style(
                margin: Margins.only(bottom: 8),
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.6),
                color: AppColors.textPrimary,
              ),
              "a": Style(
                color: AppColors.primary,
                textDecoration: TextDecoration.underline,
              ),
              "strong": Style(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              "em": Style(
                fontStyle: FontStyle.italic,
              ),
              "blockquote": Style(
                margin: Margins.symmetric(vertical: 12, horizontal: 16),
                padding: HtmlPaddings.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 12,
                ),
                border: Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 4,
                  ),
                ),
                backgroundColor: AppColors.surfaceVariant,
              ),
            },
          ),
        ),
      ),
    );
  }
}

