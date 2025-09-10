import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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

  bool _isBridgeUrl(String url) {
    return url.contains('/payment/bridge/success') ||
           url.contains('/payment/bridge/cancel');
  }

  Future<void> _finishAndPop() async {
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
        await Future.delayed(const Duration(seconds: 2));
        await _finishAndPop();
      }
    } catch (e) {
      print('PaymentWebView: Error checking payment status: $e');
      if (!mounted) return;
      Navigator.pop(context, PaymentState.paymentFailed);
    }
  }

  Future<void> _openPaymentInBrowser() async {
    try {
      final uri = Uri.parse(widget.paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم فتح صفحة الدفع. يرجى إتمام الدفع...'),
              backgroundColor: AppColors.info,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Wait for user to complete payment, then auto-check
          await Future.delayed(const Duration(seconds: 5));
          await _finishAndPop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن فتح صفحة الدفع'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context, PaymentState.paymentFailed);
        }
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

  @override
  void initState() {
    super.initState();
    
    if (kIsWeb) {
      // On web, open payment in same browser
      _openPaymentInBrowser();
    } else {
      // On mobile, use WebView
      _controller = WebViewController();
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            if (_isBridgeUrl(url)) {
              await _finishAndPop();
            }
          },
          onNavigationRequest: (request) {
            if (_isBridgeUrl(request.url)) {
              _finishAndPop();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
      
      _controller.loadRequest(Uri.parse(widget.paymentUrl));
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