import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import 'campaign_donation_screen.dart';

class AllCampaignsScreen extends StatefulWidget {
  final List<Campaign> initialCampaigns;

  const AllCampaignsScreen({
    super.key,
    required this.initialCampaigns,
  });

  @override
  State<AllCampaignsScreen> createState() => _AllCampaignsScreenState();
}

class _AllCampaignsScreenState extends State<AllCampaignsScreen> {
  final CampaignService _campaignService = CampaignService();
  final TextEditingController _searchController = TextEditingController();
  static const String _allCategoryKey = '__all__';

  List<Campaign> _campaigns = [];
  List<Campaign> _filteredCampaigns = [];
  List<String> _categories = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _selectedCategory = _allCategoryKey;

  @override
  void initState() {
    super.initState();
    _campaigns = List<Campaign>.from(widget.initialCampaigns);
    _updateCategories(_campaigns);
    _filteredCampaigns = _applyFilter(_searchController.text, _campaigns);
    if (_campaigns.isEmpty) {
      _isLoading = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllCampaigns();
    });
  }

  Future<void> _fetchAllCampaigns() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final campaigns = await _campaignService.getCharityCampaigns();
      if (!mounted) return;

      setState(() {
        _campaigns = campaigns;
        _filteredCampaigns = _applyFilter(_searchController.text, campaigns);
        _isLoading = false;
        _updateCategories(campaigns);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _onCampaignTap(Campaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CampaignDonationScreen(campaign: campaign),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.surface),
        title: Text(
          'all_campaigns'.tr(),
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w700,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.modernGradient,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchAllCampaigns,
            icon: const Icon(Icons.refresh),
            color: AppColors.surface,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.largePadding,
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.largePadding),
              ),
              SliverToBoxAdapter(
                child: _buildModernSearchField(),
              ),
              if (_categories.length > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildModernCategoryFilters(),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.largePadding),
              ),
              SliverToBoxAdapter(
                child: _buildCampaignListSection(),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.largePadding),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'swipe_to_explore'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.largePadding),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCategories(List<Campaign> campaigns) {
    final categorySet = <String>{};
    for (final campaign in campaigns) {
      final category = campaign.category.trim();
      if (category.isNotEmpty) {
        categorySet.add(category);
      }
    }
    final sortedCategories = categorySet.toList()..sort((a, b) => a.compareTo(b));

    _categories = [_allCategoryKey, ...sortedCategories];

    if (_selectedCategory != _allCategoryKey && !_categories.contains(_selectedCategory)) {
      _selectedCategory = _allCategoryKey;
    }
  }

  Widget _buildCampaignListSection() {
    if (_isLoading && _campaigns.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_hasError && _campaigns.isEmpty) {
      return _buildErrorState();
    }

    if (_campaigns.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredCampaigns.isEmpty) {
      return _buildEmptySearchState();
    }

    final List<Widget> cards = [];
    for (int i = 0; i < _filteredCampaigns.length; i++) {
      cards.add(_buildShowcaseCard(_filteredCampaigns[i]));
      if (i != _filteredCampaigns.length - 1) {
        cards.add(const SizedBox(height: 24));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cards,
    );
  }

  Widget _buildShowcaseCard(Campaign campaign) {
    final locale = context.locale.languageCode;

    return GestureDetector(
      onTap: () => _onCampaignTap(campaign),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 170,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: campaign.id,
                      child: campaign.imageUrl.isNotEmpty
                          ? Image.network(
                              campaign.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.surfaceVariant),
                            )
                          : Container(color: AppColors.surfaceVariant),
                    ),
                    Positioned(
                      top: 18,
                      left: 18,
                      right: 18,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildGlassChip(
                                icon: Icons.category_outlined,
                                label: campaign.category.isNotEmpty
                                    ? campaign.category
                                    : 'campaign'.tr(),
                                background: campaign.isCompleted
                                    ? AppColors.success.withOpacity(0.9)
                                    : AppColors.surface.withOpacity(0.9),
                                iconColor: campaign.isCompleted
                                    ? Colors.white
                                    : AppColors.primary,
                                textColor: campaign.isCompleted
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          if (campaign.isCompleted)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.success,
                                    AppColors.success.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'completed'.tr(),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Completed overlay
                    if (campaign.isCompleted)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.getLocalizedTitle(locale),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      campaign.getLocalizedDescription(locale),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'target_amount'.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${campaign.currentAmount.toStringAsFixed(0)} / ${campaign.targetAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (campaign.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.success.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'completed'.tr(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          FilledButton.icon(
                            onPressed: () => _onCampaignTap(campaign),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.volunteer_activism,
                              size: 18,
                            ),
                            label: Text(
                              'donate_now'.tr(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassChip({
    required IconData icon,
    required String label,
    required Color background,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 44,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'error_loading_campaigns'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchAllCampaigns,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text('retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'no_campaigns_available'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {});
          _onSearchChanged(value);
        },
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'search_campaigns_placeholder'.tr(),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: AppColors.surface,
          prefixIcon: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.modernGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.surface,
              size: 20,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                        _onSearchChanged('');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernCategoryFilters() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final bool isSelected = _selectedCategory == category;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onCategorySelected(category),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppColors.modernGradient
                            : null,
                        color: isSelected
                            ? null
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.textSecondary.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        category == _allCategoryKey ? 'all'.tr() : category,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.surface
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
  }

  void _onSearchChanged(String query) {
    final filtered = _applyFilter(query, _campaigns);
    setState(() {
      _filteredCampaigns = filtered;
    });
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _filteredCampaigns = _applyFilter(_searchController.text, _campaigns);
    });
  }

  List<Campaign> _applyFilter(String query, List<Campaign> source) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return source.where(_matchesSelectedCategory).toList();
    }

    return source.where((campaign) {
      final title = campaign.title.toLowerCase();
      final titleAr = campaign.titleAr.toLowerCase();
      final titleEn = campaign.titleEn.toLowerCase();
      final description = campaign.description.toLowerCase();
      final descriptionAr = campaign.descriptionAr.toLowerCase();
      final descriptionEn = campaign.descriptionEn.toLowerCase();
      final matchesQuery = title.contains(normalized) ||
          titleAr.contains(normalized) ||
          titleEn.contains(normalized) ||
          description.contains(normalized) ||
          descriptionAr.contains(normalized) ||
          descriptionEn.contains(normalized);
      return matchesQuery && _matchesSelectedCategory(campaign);
    }).toList();
  }

  bool _matchesSelectedCategory(Campaign campaign) {
    if (_selectedCategory == _allCategoryKey) return true;
    final campaignCategory = campaign.category.trim();
    return campaignCategory == _selectedCategory;
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'no_campaigns_match_search'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

