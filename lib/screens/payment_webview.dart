import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
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

  bool _isSuccessUrl(String url) {
    return url.contains('/payment/bridge/success') ||
           url.contains('/payments/success') ||
           url.contains('/pay/success') ||
           url.contains('success') ||
           url.contains('payment_success') ||
           url.contains('sfund.app') ||
           url.contains('thawani.om') && url.contains('success');
  }
  
  bool _isCancelUrl(String url) {
    return url.contains('/payment/bridge/cancel') ||
           url.contains('/payments/cancel') ||
           url.contains('/pay/cancel') ||
           url.contains('cancel') ||
           url.contains('payment_cancel') ||
           url.contains('thawani.om') && url.contains('cancel');
  }

  Future<void> _finishAndPop() async {
    if (_hasCheckedStatus) return; // Prevent multiple checks
    _hasCheckedStatus = true;
    
    try {
      final status = await _donationService.checkPaymentStatus(widget.sessionId);
      if (!mounted) return;

      print('PaymentWebView: Payment status check result: ${status.status}');
      print('PaymentWebView: Is completed: ${status.isCompleted}');

      if (status.isCompleted) {
        Navigator.pop(context, PaymentState.paymentSuccess);
      } else if (status.isCancelled) {
        Navigator.pop(context, PaymentState.paymentCancelled);
      } else if (status.isExpired) {
        Navigator.pop(context, PaymentState.paymentExpired);
      } else if (status.isFailed) {
        Navigator.pop(context, PaymentState.paymentFailed);
      } else {
        // Still pending - try again after a short delay
        _hasCheckedStatus = false; // Reset flag for retry
        await Future.delayed(const Duration(seconds: 3));
        await _finishAndPop();
      }
    } catch (e) {
      print('PaymentWebView: Error checking payment status: $e');
      if (!mounted) return;
      Navigator.pop(context, PaymentState.paymentFailed);
    }
  }


  @override
  void initState() {
    super.initState();
    
    // Start periodic status checking after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_hasCheckedStatus) {
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
              await _finishAndPop();
            } else if (_isCancelUrl(url)) {
              print('PaymentWebView: Detected cancel URL, returning cancelled...');
              if (mounted) {
                Navigator.pop(context, PaymentState.paymentCancelled);
              }
            }
          },
          onNavigationRequest: (request) {
            print('PaymentWebView: Navigation request to: ${request.url}');
            
            if (_isSuccessUrl(request.url)) {
              print('PaymentWebView: Intercepting success URL');
              _finishAndPop();
              return NavigationDecision.prevent;
            } else if (_isCancelUrl(request.url)) {
              print('PaymentWebView: Intercepting cancel URL');
              if (mounted) {
                Navigator.pop(context, PaymentState.paymentCancelled);
              }
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
          const SnackBar(
            content: Text('تم فتح صفحة الدفع في نفس التبويب. يرجى إتمام الدفع...'),
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Wait for user to complete payment, then auto-check
        await Future.delayed(const Duration(seconds: 5));
        await _finishAndPop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح صفحة الدفع: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context, PaymentState.paymentFailed);
      }
    }
  }

  void _checkPaymentStatusPeriodically() {
    if (!mounted || _hasCheckedStatus) return;
    
    print('PaymentWebView: Starting periodic payment status check...');
    _finishAndPop();
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
                    if (!_hasCheckedStatus) {
                      _finishAndPop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('التحقق من حالة الدفع'),
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
          onPressed: () => Navigator.pop(context, PaymentState.paymentCancelled),
        ),
        actions: [
          // Manual check button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (!_hasCheckedStatus) {
                _finishAndPop();
              }
            },
            tooltip: 'التحقق من حالة الدفع',
          ),
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
          // Help message overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'بعد إتمام الدفع، اضغط على زر التحديث 🔄',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أو انتظر 10 ثوانٍ للتحقق التلقائي',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.surface.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}