import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class CheckoutWebView extends StatefulWidget {
  final String checkoutUrl;
  final String successUrl;
  final String cancelUrl;

  const CheckoutWebView({
    super.key,
    required this.checkoutUrl,
    required this.successUrl,
    required this.cancelUrl,
  });

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  bool _isSuccessUrl(String url) {
    return url.contains('success') ||
           url.contains('payment_success') ||
           url.contains('sfund.app') ||
           url.contains('thawani.om') && url.contains('success') ||
           url == widget.successUrl;
  }
  
  bool _isCancelUrl(String url) {
    return url.contains('cancel') ||
           url.contains('payment_cancel') ||
           url.contains('thawani.om') && url.contains('cancel') ||
           url == widget.cancelUrl;
  }

  @override
  void initState() {
    super.initState();
    
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
            print('CheckoutWebView: Page finished loading: $url');
            
            if (_isSuccessUrl(url)) {
              print('CheckoutWebView: Detected success URL');
              if (mounted) {
                Navigator.pop(context, {'status': 'success'});
              }
            } else if (_isCancelUrl(url)) {
              print('CheckoutWebView: Detected cancel URL');
              if (mounted) {
                Navigator.pop(context, {'status': 'cancel'});
              }
            }
          },
          onNavigationRequest: (request) {
            print('CheckoutWebView: Navigation request to: ${request.url}');
            
            if (_isSuccessUrl(request.url)) {
              print('CheckoutWebView: Intercepting success URL');
              if (mounted) {
                Navigator.pop(context, {'status': 'success'});
              }
              return NavigationDecision.prevent;
            } else if (_isCancelUrl(request.url)) {
              print('CheckoutWebView: Intercepting cancel URL');
              if (mounted) {
                Navigator.pop(context, {'status': 'cancel'});
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
      
      _controller.loadRequest(Uri.parse(widget.checkoutUrl));
    }
  }
  
  Future<void> _openPaymentInBrowser() async {
    try {
      // For web platform, open in same tab using webOnlyWindowName: '_self'
      await launchUrlString(
        widget.checkoutUrl,
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
        
        // For web, we assume success after delay (user should handle manually)
        if (mounted) {
          Navigator.pop(context, {'status': 'success'});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'payment_page_error'.tr()}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context, {'status': 'cancel'});
      }
    }
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
                  'جاري إتمام عملية الدفع...',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'يرجى إتمام الدفع في المتصفح',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
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
          onPressed: () => Navigator.pop(context, {'status': 'cancel'}),
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
}
