import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../services/campaign_service.dart';
import '../utils/category_utils.dart';
import 'checkout_webview.dart';
import 'donation_success_screen.dart';

class QuickDonateAmountScreen extends StatefulWidget {
  const QuickDonateAmountScreen({super.key});

  @override
  State<QuickDonateAmountScreen> createState() => _QuickDonateAmountScreenState();
}

class _QuickDonateAmountScreenState extends State<QuickDonateAmountScreen> {
  double _selectedAmount = 50.0;
  final TextEditingController _customAmountController = TextEditingController();
  bool _isCustomAmount = false;
  String? _selectedCategory;
  bool _isLoading = false;

  List<double> _presetAmounts = [25.0, 50.0, 100.0, 200.0, 500.0, 1000.0];
  List<Map<String, dynamic>> _categories = [];
  final CampaignService _campaignService = CampaignService();

  // Fallback categories if API fails
  List<Map<String, dynamic>> get _fallbackCategories {
    final currentLocale = context.locale.languageCode;
    final fallbackCategories = CategoryUtils.getLocalizedFallbackCategories();
    
    return fallbackCategories.map((category) => {
      'id': category['id'],
      'title': CategoryUtils.getCategoryName(
        nameAr: category['name_ar'],
        nameEn: category['name_en'],
        currentLocale: currentLocale,
      ),
      'name_ar': category['name_ar'],
      'name_en': category['name_en'],
      'description': category['description'],
      'icon': _getIconFromString(category['icon']),
      'color': _getColorFromString(category['color']),
    }).toList();
  }

  // Helper functions for icon and color conversion
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'computer':
        return Icons.computer;
      case 'assignment':
        return Icons.assignment;
      default:
        return Icons.category;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'primary':
        return AppColors.primary;
      case 'secondary':
        return AppColors.secondary;
      case 'accent':
        return AppColors.accent;
      case 'success':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _customAmountController.text = _selectedAmount.toString();
    // Initialize with fallback categories first
    _categories = _fallbackCategories;
    print('QuickDonate: Initialized with ${_categories.length} fallback categories');
    _loadDataFromAPI();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh categories when locale changes
    _refreshCategoriesForCurrentLocale();
  }

  void _refreshCategoriesForCurrentLocale() {
    if (_categories.isNotEmpty) {
      final currentLocale = context.locale.languageCode;
      setState(() {
        _categories = _categories.map((category) {
          // If category has bilingual names, update the title
          if (category.containsKey('name_ar') && category.containsKey('name_en')) {
            return {
              ...category,
              'title': CategoryUtils.getCategoryName(
                nameAr: category['name_ar'],
                nameEn: category['name_en'],
                currentLocale: currentLocale,
              ),
            };
          }
          return category;
        }).toList();
      });
    }
  }

  Future<void> _loadDataFromAPI() async {
    try {
      // Load categories from API first
      try {
        final categories = await _campaignService.getCategories();
        if (categories.isNotEmpty) {
          final currentLocale = context.locale.languageCode;
          setState(() {
            _categories = categories.map((category) => {
              'id': category['id'].toString(),
              'title': CategoryUtils.getCategoryName(
                nameAr: category['name_ar'] ?? category['name'] ?? '',
                nameEn: category['name_en'] ?? category['name'] ?? '',
                fallbackName: category['name'],
                currentLocale: currentLocale,
              ),
              'name_ar': category['name_ar'] ?? category['name'] ?? '',
              'name_en': category['name_en'] ?? category['name'] ?? '',
              'description': category['description'] ?? '',
              'icon': Icons.category,
              'color': AppColors.primary,
            }).toList();
          });
          print('QuickDonate: Successfully loaded ${categories.length} categories from API');
        } else {
          print('QuickDonate: No categories from API, trying campaigns fallback');
          // If no categories, try loading from campaigns as fallback
          _loadCategoriesFromCampaigns();
        }
      } catch (error) {
        print('QuickDonate: Error loading categories, trying campaigns fallback: $error');
        // If categories API fails, try loading from campaigns as fallback
        _loadCategoriesFromCampaigns();
      }

      // Load quick amounts from API
      try {
        final amounts = await _campaignService.getQuickDonationAmounts();
        setState(() {
          _presetAmounts = amounts;
          // Amounts loaded
        });
        print('QuickDonate: Successfully loaded ${amounts.length} quick amounts from API');
      } catch (error) {
        print('QuickDonate: Error loading quick amounts, using fallback: $error');
        setState(() {
          // Amounts loaded
        });
      }
    } catch (error) {
      print('QuickDonate: Error loading data from API: $error');
      setState(() {
        _categories = _fallbackCategories;
        // Error handling completed
      });
    }
  }

  // Load categories from campaigns as fallback
  Future<void> _loadCategoriesFromCampaigns() async {
    try {
      final campaigns = await _campaignService.getCharityCampaigns();
      if (campaigns.isNotEmpty) {
        // Group campaigns by category
        final Map<String, List<Map<String, dynamic>>> groupedCampaigns = {};
        
        for (var campaign in campaigns) {
          final categoryName = campaign.category;
          if (!groupedCampaigns.containsKey(categoryName)) {
            groupedCampaigns[categoryName] = [];
          }
          groupedCampaigns[categoryName]!.add({
            'id': campaign.id,
            'title': campaign.title,
            'description': campaign.description,
            'category': campaign.category,
          });
        }
        
        // Create categories from grouped campaigns
        final categoriesWithCampaigns = <Map<String, dynamic>>[];
        groupedCampaigns.forEach((categoryName, campaignList) {
          categoriesWithCampaigns.add({
            'id': categoryName,
            'title': categoryName,
            'description': '${campaignList.length} حملة متاحة',
            'icon': _getCategoryIcon(categoryName),
            'color': _getCategoryColor(categoryName),
            'campaigns': campaignList,
            'campaign_count': campaignList.length,
          });
        });
        
        setState(() {
          _categories = categoriesWithCampaigns;
        });
        
        print('QuickDonate: Successfully loaded ${campaigns.length} campaigns grouped into ${categoriesWithCampaigns.length} categories');
      } else {
        print('QuickDonate: No campaigns from API, keeping fallback categories');
      }
    } catch (error) {
      print('QuickDonate: Error loading campaigns, keeping fallback: $error');
      // Keep the fallback categories that were already set in initState
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _onAmountSelected(double amount) {
    setState(() {
      _selectedAmount = amount;
      _isCustomAmount = false;
      _customAmountController.text = amount.toString();
    });
  }

  void _onCustomAmountChanged(String value) {
    if (value.isNotEmpty) {
      setState(() {
        _selectedAmount = double.tryParse(value) ?? 0.0;
        _isCustomAmount = true;
      });
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
  }

  void _onContinue() {
    if (_selectedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_enter_valid_amount'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_choose_donation_category'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _processPayment();
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ احصل على التوكن (اختياري)
      final token = await _getAuthToken();
      
      // الحصول على origin للمنصة الويب
      final origin = kIsWeb ? Uri.base.origin : AppConfig.serverBaseUrl;
      
      // الحصول على campaign_id من الفئة المختارة
      final campaignId = _getCampaignIdFromCategory();
      
      // إعداد headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // إضافة Authorization header فقط إذا كان المستخدم مسجل دخول
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('QuickDonate: Using authenticated request with token');
      } else {
        print('QuickDonate: Using anonymous donation request');
      }
      
      // 1) استدعاء POST /api/v1/donations/with-payment مع return_origin
      final response = await http.post(
        Uri.parse(AppConfig.donationsWithPaymentEndpoint),
        headers: headers,
        body: jsonEncode({
          'campaign_id': campaignId,
          'amount': _selectedAmount,
          'donor_name': 'متبرع',
          'note': 'تبرع سريع للطلاب المحتاجين',
          'is_anonymous': false,
          'type': 'quick',
          'return_origin': origin,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Quick donation response: $data');
        
        // استخراج البيانات من الاستجابة
        final sessionId = data['data']?['payment_session']?['session_id'] ?? 
                         data['session_id'] ?? 
                         data['data']?['session_id'];
        final checkoutUrl = data['data']?['payment_session']?['payment_url'] ?? 
                           data['data']?['payment_url'] ?? 
                           data['checkout_url'] ?? 
                           data['payment_url'];
        
        print('✅ Payment session created: sessionId=$sessionId, checkoutUrl=$checkoutUrl');
        
        // التحقق من وجود البيانات المطلوبة
        if (sessionId == null || checkoutUrl == null) {
          throw Exception('Missing payment session data: sessionId=$sessionId, checkoutUrl=$checkoutUrl');
        }
        
        // 2) فتح checkout مباشرة في نفس التبويب للمنصة الويب
        if (kIsWeb) {
          await launchUrlString(
            checkoutUrl,
            webOnlyWindowName: '_self', // نفس التبويب
          );
          
          // إظهار رسالة للمستخدم
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('payment_page_opened'.tr()),
              backgroundColor: AppColors.info,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // الانتظار قليلاً ثم التحقق من حالة الدفع
          await Future.delayed(const Duration(seconds: 5));
          await _confirmPayment(sessionId);
        } else {
          // للمنصات المحمولة، استخدم CheckoutWebView
          _openCheckoutWebView(checkoutUrl, sessionId);
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'فشل في إنشاء جلسة الدفع';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error: $e');
      _showErrorSnackBar('خطأ في إنشاء التبرع: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _getCampaignIdFromCategory() {
    // إذا كانت الفئة المختارة موجودة في القائمة، استخدم أول حملة من الفئة
    if (_selectedCategory != null) {
      final category = _categories.firstWhere(
        (cat) => cat['id'] == _selectedCategory,
        orElse: () => {'campaigns': []}, // fallback
      );
      
      final campaigns = category['campaigns'] as List<Map<String, dynamic>>?;
      if (campaigns != null && campaigns.isNotEmpty) {
        return int.tryParse(campaigns.first['id'].toString()) ?? 1;
      }
    }
    return 1; // fallback campaign ID
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // احصل على التوكن من التخزين المحلي
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // فتح CheckoutWebView للدفع
  void _openCheckoutWebView(String checkoutUrl, String sessionId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutWebView(
          checkoutUrl: checkoutUrl,
          successUrl: AppConfig.paymentsSuccessUrl,
          cancelUrl: AppConfig.paymentsCancelUrl,
        ),
      ),
    );

    // معالجة النتائج
    if (result != null) {
      if (result['status'] == 'success') {
        // 3) إذا رجع result.status == 'success' ناد POST /api/v1/payments/confirm
        await _confirmPayment(sessionId);
      } else if (result['status'] == 'cancel') {
        // 4) إذا رجع 'cancel' اعرض رسالة إلغاء فقط
        _showCancelMessage();
      }
    }
  }

  // تأكيد الدفع
  Future<void> _confirmPayment(String sessionId) async {
    try {
      final token = await _getAuthToken();
      
      // إعداد headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // إضافة Authorization header فقط إذا كان المستخدم مسجل دخول
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.post(
        Uri.parse(AppConfig.paymentsConfirmEndpoint),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        // اعرض شاشة "نجاح التبرّع"
        _showDonationSuccess();
      } else {
        throw Exception('payment_failed'.tr());
      }
    } catch (e) {
      print('❌ Error confirming payment: $e');
      _showErrorSnackBar('error_occurred'.tr());
    }
  }

  // عرض رسالة الإلغاء
  void _showCancelMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('payment_cancelled'.tr()),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // عرض شاشة نجاح التبرع
  void _showDonationSuccess() {
    final categoryTitle = _selectedCategory != null
        ? _categories.firstWhere((cat) => cat['id'] == _selectedCategory)['title']
        : 'تبرع سريع';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DonationSuccessScreen(
          amount: _selectedAmount,
          campaignTitle: categoryTitle,
          campaignCategory: categoryTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'quick_donation'.tr(),
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.largePadding),
              decoration: BoxDecoration(
                gradient: AppColors.modernGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.surface,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'choose_donation_amount'.tr(),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'every_riyal_helps'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Preset Amounts Section
            Text(
              'suggested_amounts'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Preset Amounts Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _presetAmounts.length,
              itemBuilder: (context, index) {
                final amount = _presetAmounts[index];
                final isSelected = _selectedAmount == amount && !_isCustomAmount;
                
                return GestureDetector(
                  onTap: () => _onAmountSelected(amount),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : AppColors.textPrimary.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.textPrimary.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          amount.toStringAsFixed(0),
                          style: AppTextStyles.titleLarge.copyWith(
                            color: isSelected ? AppColors.surface : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'riyal'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected 
                                ? AppColors.surface.withOpacity(0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Custom Amount Section
            Text(
              'or_enter_custom_amount'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isCustomAmount 
                      ? AppColors.primary 
                      : AppColors.textPrimary.withOpacity(0.1),
                  width: _isCustomAmount ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _customAmountController,
                onChanged: _onCustomAmountChanged,
                keyboardType: TextInputType.number,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'enter_amount'.tr(),
                  hintStyle: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  suffixText: 'riyal'.tr(),
                  suffixStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppConstants.largePadding),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Selected Amount Display
            if (_selectedAmount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.largePadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'selected_amount'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedAmount.toStringAsFixed(0)} ${'riyal'.tr()}',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.extraLargePadding),
            ],

            // Categories Section
            Text(
              'choose_donation_category'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Categories Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
              children: _categories.map((category) => _buildCategoryCard(
                category: category,
                isSelected: _selectedCategory == category['id'],
                onTap: () => _onCategorySelected(category['id']),
              )).toList(),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Note about automatic allocation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'important_note'.tr(),
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'donation_redirect_note'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.extraLargePadding),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_selectedAmount > 0 && _selectedCategory != null && !_isLoading) 
                    ? _onContinue 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedAmount > 0 && _selectedCategory != null && !_isLoading)
                      ? AppColors.primary
                      : AppColors.textSecondary.withOpacity(0.3),
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'processing_payment'.tr(),
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            (_selectedAmount > 0 && _selectedCategory != null)
                                ? 'proceed_to_payment'.tr()
                                : 'choose_amount_category'.tr(),
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: AppColors.surface,
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
    );
  }

  Widget _buildCategoryCard({
    required Map<String, dynamic> category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = category['color'] as Color;
    final icon = category['icon'] as IconData;
    final title = category['title'] as String;
    final description = category['description'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? color.withOpacity(0.25)
                  : AppColors.textPrimary.withOpacity(0.08),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? color.withOpacity(0.2)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.1,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'تعليم':
      case 'education':
        return Icons.school;
      case 'سكن':
      case 'housing':
        return Icons.home;
      case 'أجهزة':
      case 'devices':
        return Icons.computer;
      case 'امتحانات':
      case 'exams':
        return Icons.assignment;
      case 'صحة':
      case 'health':
        return Icons.health_and_safety;
      case 'طعام':
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'تعليم':
      case 'education':
        return AppColors.primary;
      case 'سكن':
      case 'housing':
        return AppColors.secondary;
      case 'أجهزة':
      case 'devices':
        return AppColors.accent;
      case 'امتحانات':
      case 'exams':
        return AppColors.success;
      case 'صحة':
      case 'health':
        return Colors.red;
      case 'طعام':
      case 'food':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
} 