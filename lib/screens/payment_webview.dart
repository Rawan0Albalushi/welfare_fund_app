import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/payment_provider.dart';
import '../services/donation_service.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String sessionId;

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.sessionId,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  final _donationService = DonationService();
  bool _hasCheckedStatus = false;
  Timer? _statusCheckTimer;
  bool _hasPopped = false;
  bool _pollingDisabled = false;
  bool _isHandlingSuccess = false;

  bool _isSuccessUrl(String url) {
    return url.contains('/payment/bridge/success') ||
           url.contains('/payments/success') ||
           url.contains('/payments/mobile/success') ||
           url.contains('/pay/success') ||
           url.contains('payment_success') ||
           url.contains('sfund.app') ||
           (url.contains('thawani.om') && url.contains('success')) ||
           (url.contains('/mobile/success') && url.contains('donation_id'));
  }
  
  bool _isCancelUrl(String url) {
    return url.contains('/payment/bridge/cancel') ||
           url.contains('/payments/cancel') ||
           url.contains('/pay/cancel') ||
           url.contains('cancel') ||
           url.contains('payment_cancel') ||
           url.contains('thawani.om') && url.contains('cancel');
  }

  void _cancelScheduledStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  Future<void> _safePop(Map<String, dynamic> payload) async {
    if (_hasPopped) return;
    _hasPopped = true;
    _cancelScheduledStatusCheck();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pop(context, payload);
      }
    });
  }

  Future<void> _handleSuccessNavigation(String url) async {
    if (_hasPopped || _hasCheckedStatus || _isHandlingSuccess) return;
    // إيقاف الـ polling فوراً قبل أي شيء
    print('PaymentWebView: Disabling polling and handling success navigation');
    _isHandlingSuccess = true;
    _pollingDisabled = true;
    _hasCheckedStatus = true;
    _cancelScheduledStatusCheck();

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      print('PaymentWebView: Fetching mobile success data...');
      final response = await _donationService.fetchMobilePaymentSuccessData(successUrl: url);
      if (!mounted) return;

      final payload = _buildSuccessResult(response, url);
      await _safePop(payload);
    } catch (e) {
      print('PaymentWebView: Error fetching mobile success data: $e');
      _isHandlingSuccess = false;
      _pollingDisabled = false;
      _hasCheckedStatus = false;
      await _checkPaymentStatusAndComplete();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _buildSuccessResult(Map<String, dynamic> response, String successUrl) {
    final dynamic rawData = response['data'];
    final Map<String, dynamic> data;
    if (rawData is Map<String, dynamic>) {
      data = Map<String, dynamic>.from(rawData);
    } else {
      data = response;
    }

    // استخراج بيانات التبرع (قد تكون في donation object أو مباشرة)
    final dynamic donationObj = data['donation'];
    final Map<String, dynamic> donationData;
    if (donationObj is Map<String, dynamic>) {
      donationData = Map<String, dynamic>.from(donationObj);
    } else {
      donationData = data;
    }

    // استخراج بيانات الحملة (قد تكون في campaign object أو مباشرة)
    final dynamic campaignObj = data['campaign'] ?? donationData['campaign'];
    String? campaignTitle;
    if (campaignObj is Map<String, dynamic>) {
      campaignTitle = (campaignObj['title'] ?? campaignObj['name'])?.toString();
    }
    campaignTitle ??= (data['campaign_title'] ?? 
                       donationData['campaign_title'] ?? 
                       data['campaign'] ?? 
                       data['campaign_name'])?.toString();

    // استخراج donation_id
    final donationId = (donationData['donation_id'] ?? 
                       donationData['donationId'] ?? 
                       donationData['id'] ?? 
                       data['donation_id'] ?? 
                       data['donationId'])?.toString();

    // استخراج session_id
    final sessionId = (data['session_id'] ?? 
                       data['sessionId'] ?? 
                       data['payment_session_id'] ?? 
                       donationData['payment_session_id'] ?? 
                       widget.sessionId)?.toString();

    // استخراج المبلغ (paid_amount أولاً، ثم amount)
    final amount = _tryParseAmount(
      donationData['paid_amount'] ?? 
      donationData['amount'] ?? 
      data['paid_amount'] ?? 
      data['amount'] ?? 
      data['donation_amount']
    );

    print('PaymentWebView: Built success result - donationId: $donationId, amount: $amount, campaignTitle: $campaignTitle');

    return {
      'state': PaymentState.paymentSuccess.name,
      'donationId': donationId,
      'sessionId': sessionId,
      'campaignTitle': campaignTitle,
      'amount': amount,
      'rawResponse': response,
      'successUrl': successUrl,
    };
  }

  double? _tryParseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9\.\-]'), '');
      return double.tryParse(normalized);
    }
    return null;
  }

  Future<void> _checkPaymentStatusAndComplete() async {
    // حماية من race conditions: التحقق من الحالة قبل وبعد الاستدعاء
    if (!mounted || _hasPopped || _pollingDisabled || _isHandlingSuccess) {
      if (_pollingDisabled || _isHandlingSuccess) {
        print('PaymentWebView: Polling disabled or handling success, skipping status check');
      }
      return;
    }

    try {
      final status = await _donationService.checkPaymentStatus(widget.sessionId);
      
      // التحقق مرة أخرى بعد الاستدعاء لتجنب race conditions
      if (!mounted || _hasPopped || _pollingDisabled || _isHandlingSuccess) {
        print('PaymentWebView: Polling was disabled or handling success, ignoring status check result');
        return;
      }

      print('PaymentWebView: Payment status check result: ${status.status}');
      print('PaymentWebView: Is completed: ${status.isCompleted}');

      if (status.isCompleted) {
        if (_isHandlingSuccess) {
          print('PaymentWebView: Success is being handled via mobile API, ignoring polling result');
          return;
        }
        _hasCheckedStatus = true;
        await _safePop({
          'state': PaymentState.paymentSuccess.name,
          'sessionId': status.sessionId ?? widget.sessionId,
          if (status.amount != null) 'amount': status.amount,
          if (status.raw != null) 'rawResponse': status.raw,
        });
      } else if (status.isCancelled) {
        if (!_pollingDisabled && !_hasPopped && !_isHandlingSuccess) {
          await _safePop({'state': PaymentState.paymentCancelled.name});
        }
      } else if (status.isExpired) {
        if (!_pollingDisabled && !_hasPopped && !_isHandlingSuccess) {
          await _safePop({'state': PaymentState.paymentExpired.name});
        }
      } else if (status.isFailed) {
        if (!_pollingDisabled && !_hasPopped && !_isHandlingSuccess) {
          await _safePop({
            'state': PaymentState.paymentFailed.name,
            if (status.error != null) 'error': status.error,
          });
        }
      } else {
        // لا نستمر في الـ polling إذا تم تعطيله أو تم pop
        if (_hasPopped || _pollingDisabled || _isHandlingSuccess) return;
        await Future.delayed(const Duration(seconds: 3));
        if (!_hasPopped && !_pollingDisabled) {
          await _checkPaymentStatusAndComplete();
        }
      }
    } catch (e) {
      // معالجة الأخطاء بشكل آمن دون تسريب معلومات حساسة
      print('PaymentWebView: Error checking payment status');
      if (!mounted || _hasPopped || _isHandlingSuccess) return;
      
      // لا نطبع تفاصيل الخطأ في رسالة المستخدم لأسباب أمنية
      await _safePop({
        'state': PaymentState.paymentFailed.name,
        'error': 'حدث خطأ في التحقق من حالة الدفع',
      });
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Start periodic status checking after 10 seconds
    _statusCheckTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_hasCheckedStatus && !_hasPopped && !_pollingDisabled && !_isHandlingSuccess) {
        _checkPaymentStatusPeriodically();
      }
    });
    
    if (kIsWeb) {
      // For web platform, open payment in browser
      _openPaymentInBrowser();
    } else {
      // For mobile platforms, use WebView
      _controller = WebViewController();
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            print('PaymentWebView: Page finished loading: $url');
            
            if (_isSuccessUrl(url)) {
              print('PaymentWebView: Detected success URL, checking payment status...');
              await _handleSuccessNavigation(url);
            } else if (_isCancelUrl(url)) {
              print('PaymentWebView: Detected cancel URL, returning cancelled...');
              _safePop({'state': PaymentState.paymentCancelled.name});
            }
          },
          onNavigationRequest: (request) {
            print('PaymentWebView: Navigation request to: ${request.url}');
            
            if (_isSuccessUrl(request.url)) {
              print('PaymentWebView: Intercepting success URL');
              _handleSuccessNavigation(request.url);
              return NavigationDecision.prevent;
            } else if (_isCancelUrl(request.url)) {
              print('PaymentWebView: Intercepting cancel URL');
              _safePop({'state': PaymentState.paymentCancelled.name});
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
      
      _controller.loadRequest(Uri.parse(widget.paymentUrl));
    }
  }
  
  Future<void> _openPaymentInBrowser() async {
    try {
      // For web platform, open in same tab using webOnlyWindowName: '_self'
      await launchUrlString(
        widget.paymentUrl,
        webOnlyWindowName: '_self',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('payment_page_opened'.tr()),
            backgroundColor: AppColors.info,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Wait for user to complete payment, then auto-check
        await Future.delayed(const Duration(seconds: 5));
        await _checkPaymentStatusAndComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'payment_page_error'.tr()}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        await _safePop({
          'state': PaymentState.paymentFailed.name,
          'error': e.toString(),
        });
      }
    }
  }

  void _checkPaymentStatusPeriodically() {
    if (!mounted || _hasCheckedStatus || _hasPopped || _pollingDisabled || _isHandlingSuccess) return;
    
    print('PaymentWebView: Starting periodic payment status check...');
    _checkPaymentStatusAndComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web, show a simple loading message
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          title: Text(
            'جاري إتمام الدفع...',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  'جاري التحقق من حالة الدفع...',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'يرجى الانتظار قليلاً',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (!_hasCheckedStatus && !_hasPopped) {
                      _checkPaymentStatusAndComplete();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text('checking_payment_status'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // For mobile platforms, use WebView
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        title: Text(
          'إتمام الدفع',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _safePop({'state': PaymentState.paymentCancelled.name}),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.surface),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: AppColors.background.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاري تحميل صفحة الدفع...',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
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

  @override
  void dispose() {
    _cancelScheduledStatusCheck();
    super.dispose();
  }
}