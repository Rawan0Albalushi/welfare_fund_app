import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';
import '../models/fund_partner.dart';
import '../services/fund_partner_service.dart';

class FundPartnersScreen extends StatefulWidget {
  const FundPartnersScreen({super.key});

  @override
  State<FundPartnersScreen> createState() => _FundPartnersScreenState();
}

class _FundPartnersScreenState extends State<FundPartnersScreen>
    with TickerProviderStateMixin {
  final FundPartnerService _service = FundPartnerService();
  List<FundPartner> _partners = [];
  List<FundPartner> _featured = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _service.getActivePartners(),
        _service.getFeaturedPartners(),
      ]);
      if (!mounted) return;
      setState(() {
        _partners = results[0];
        _featured = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'fund_partners_error_load'.tr();
      });
    }
  }

  /// حل رابط الشعار حسب مواصفات الباكند:
  /// - إذا ورد logo_url (رابط كامل) نستخدمه كما هو، مع استبدال localhost/127.0.0.1
  ///   بعنوان الخادم في التطبيق حتى يصل الجوال/المحاكي للصورة.
  /// - إذا ورد logo فقط (مسار نسبي مثل fund-partners/abc123.jpg) نركّب:
  ///   {APP_URL}/storage/{path}
  String _resolveLogoUrl(String? path) {
    if (path == null || path.isEmpty) {
      if (kDebugMode) debugPrint('[FundPartners] resolveLogo: input is null or empty');
      return '';
    }
    final p = path.replaceAll(RegExp(r'\\'), '/').trim();
    if (p.isEmpty) {
      if (kDebugMode) debugPrint('[FundPartners] resolveLogo: input trimmed empty');
      return '';
    }
    final base = AppConfig.serverBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final baseUri = Uri.tryParse(base);
    String url;
    if (p.startsWith('http://') || p.startsWith('https://')) {
      if (kDebugMode) debugPrint('[FundPartners] resolveLogo: using full URL from API');
      url = p;
      if (baseUri != null) {
        final imgUri = Uri.tryParse(p);
        if (imgUri != null &&
            (imgUri.host == 'localhost' ||
                imgUri.host == '127.0.0.1' ||
                imgUri.host.isEmpty)) {
          url = '${baseUri.scheme}://${baseUri.host}${baseUri.port != 80 && baseUri.port != 443 ? ':${baseUri.port}' : ''}${imgUri.path}${imgUri.query.isNotEmpty ? '?${imgUri.query}' : ''}';
          if (kDebugMode) debugPrint('[FundPartners] resolveLogo: replaced localhost → $url');
        }
      }
    } else if (p.startsWith('//')) {
      url = 'https:$p';
      if (kDebugMode) debugPrint('[FundPartners] resolveLogo: protocol-relative → $url');
    } else {
      if (kDebugMode) debugPrint('[FundPartners] resolveLogo: building from path (logo only): "$p"');
      final withSlash = p.startsWith('/') ? p : '/$p';
      final pathForStorage = withSlash.toLowerCase().contains('storage') ? withSlash : '/storage$withSlash';
      url = '$base$pathForStorage';
    }
    if (kDebugMode) debugPrint('[FundPartners] resolveLogo: final url = $url');
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final isRTL = locale == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.surface),
          leading: IconButton(
            icon: Icon(
              isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: AppColors.surface,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'fund_partners'.tr(),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.surface, size: 22),
              onPressed: _isLoading ? null : _load,
            ),
          ],
        ),
        body: SafeArea(
          child: _buildBody(locale, textDirection, isRTL),
        ),
      ),
    );
  }

  Widget _buildBody(String locale, TextDirection textDirection, bool isRTL) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'loading'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              FilledButton.icon(
                onPressed: _load,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text('retry'.tr(), style: AppTextStyles.buttonMedium),
              ),
            ],
          ),
        ),
      );
    }

    if (_partners.isEmpty && _featured.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.handshake_rounded,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppConstants.largePadding),
              Text(
                'fund_partners_empty'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.largePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(locale),
                    if (_featured.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.largePadding),
                      Text(
                        'fund_partners_featured'.tr(),
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      _buildFeaturedRow(locale),
                      const SizedBox(height: AppConstants.largePadding),
                    ],
                    Text(
                      'fund_partners_all'.tr(),
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final list = _partners
                        .where((p) => !_featured.any((f) => f.id == p.id))
                        .toList();
                    if (index >= list.length) return null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
                      child: _PartnerCard(
                        partner: list[index],
                        locale: locale,
                        resolveLogo: _resolveLogoUrl,
                        onTap: () => _onPartnerTap(list[index]),
                        isRTL: isRTL,
                      ),
                    );
                  },
                  childCount: _partners
                      .where((p) => !_featured.any((f) => f.id == p.id))
                      .length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppConstants.extraLargePadding)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String locale) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.06),
            AppColors.secondary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.modernGradient,
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.handshake_rounded,
              color: AppColors.surface,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'fund_partners_subtitle'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRow(String locale) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _featured.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: 12,
            ),
            child: _FeaturedPartnerCard(
              partner: _featured[index],
              locale: locale,
              resolveLogo: _resolveLogoUrl,
              onTap: () => _onPartnerTap(_featured[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onPartnerTap(FundPartner partner) async {
    final link = partner.link?.trim();
    if (link == null || link.isEmpty) return;
    HapticFeedback.lightImpact();
    try {
      final uri = link.startsWith('http') ? link : 'https://$link';
      if (await canLaunchUrlString(uri)) {
        await launchUrlString(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'cannot_open_link'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'error_opening_link'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          ),
        ),
      );
    }
  }
}

class _FeaturedPartnerCard extends StatelessWidget {
  final FundPartner partner;
  final String locale;
  final String Function(String?) resolveLogo;
  final VoidCallback onTap;

  const _FeaturedPartnerCard({
    required this.partner,
    required this.locale,
    required this.resolveLogo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = partner.getLocalizedName(locale);
    final logoUrl = resolveLogo(partner.logo);
    final hasLink = partner.link != null && partner.link!.trim().isNotEmpty;

    return GestureDetector(
      onTap: hasLink ? onTap : null,
      child: Container(
        width: 180,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              child: logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                      child: CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => _buildLogoPlaceholder(name, 80),
                        errorWidget: (_, url, error) {
                          if (kDebugMode) {
                            debugPrint('[FundPartners] image load FAILED (featured) url=$url error=$error');
                          }
                          return _buildLogoPlaceholder(name, 80);
                        },
                      ),
                    )
                  : _buildLogoPlaceholder(name, 80),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                name,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (hasLink) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final FundPartner partner;
  final String locale;
  final String Function(String?) resolveLogo;
  final VoidCallback onTap;
  final bool isRTL;

  const _PartnerCard({
    required this.partner,
    required this.locale,
    required this.resolveLogo,
    required this.onTap,
    required this.isRTL,
  });

  @override
  Widget build(BuildContext context) {
    final name = partner.getLocalizedName(locale);
    final desc = partner.getLocalizedDescription(locale);
    final logoUrl = resolveLogo(partner.logo);
    final hasLink = partner.link != null && partner.link!.trim().isNotEmpty;

    return GestureDetector(
      onTap: hasLink ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.surfaceVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              child: logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                      child: CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => _buildLogoPlaceholder(name, 64),
                        errorWidget: (_, url, error) {
                          if (kDebugMode) {
                            debugPrint('[FundPartners] image load FAILED (card) url=$url error=$error');
                          }
                          return _buildLogoPlaceholder(name, 64);
                        },
                      ),
                    )
                  : _buildLogoPlaceholder(name, 64),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (desc != null && desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc.length > 80 ? '${desc.substring(0, 80)}...' : desc,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (hasLink)
              Icon(
                isRTL ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// عرض الحرف الأول من اسم الشريك عندما لا يوجد شعار أو فشل تحميله
Widget _buildLogoPlaceholder(String name, double size) {
  final letter = name.trim().isNotEmpty
      ? name.trim().substring(0, 1).toUpperCase()
      : '?';
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withOpacity(0.85),
          AppColors.secondary.withOpacity(0.85),
        ],
      ),
      borderRadius: BorderRadius.circular(size * 0.2),
    ),
    child: Text(
      letter,
      style: TextStyle(
        color: AppColors.surface,
        fontSize: size * 0.45,
        fontWeight: FontWeight.bold,
        fontFamily: 'IBMPlexSansArabic',
      ),
    ),
  );
}
