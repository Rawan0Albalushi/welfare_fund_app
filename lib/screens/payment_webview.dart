import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
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
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final DonationService _donationService = DonationService();

  @override
  void initState() {
    super.initState();
    
    // Check if running on web platform
    if (kIsWeb) {
      _openPaymentInBrowser();
    } else {
      _initializeWebView();
    }
  }

  void _openPaymentInBrowser() async {
    try {
      final Uri url = Uri.parse(widget.paymentUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم فتح صفحة الدفع في المتصفح'),
              backgroundColor: AppColors.info,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Check payment status
          await _checkPaymentStatus();
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'لا يمكن فتح صفحة الدفع';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'حدث خطأ في فتح صفحة الدفع: $e';
      });
    }
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            // Check if this is the return URL
            if (url.contains('example.com/return') ||
                url.contains('example.com/success') ||
                url.contains('example.com/cancel')) {
              _handlePaymentReturn();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle return URL
            if (request.url.contains('example.com/return') ||
                request.url.contains('example.com/success') ||
                request.url.contains('example.com/cancel')) {
              _handlePaymentReturn();
              return NavigationDecision.prevent;
            }
            
            // Allow all other navigation
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'حدث خطأ في تحميل صفحة الدفع: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _checkPaymentStatus() async {
    try {
      print('PaymentWebView: Checking payment status for session: ${widget.sessionId}');
      
      final statusResponse = await _donationService.checkPaymentStatus(widget.sessionId);
      
      print('PaymentWebView: Payment status response: ${statusResponse.status}');
      
      if (mounted) {
        String result;
        if (statusResponse.isCompleted) {
          result = 'success';
        } else if (statusResponse.isFailed) {
          result = 'failed';
        } else if (statusResponse.isCancelled) {
          result = 'cancelled';
        } else if (statusResponse.isExpired) {
          result = 'expired';
        } else {
          result = 'pending';
        }
        
        Navigator.pop(context, result);
      }
    } catch (e) {
      print('PaymentWebView: Error checking payment status: $e');
      if (mounted) {
        Navigator.pop(context, 'failed');
      }
    }
  }

  void _handlePaymentReturn() async {
    // Check payment status
    await _checkPaymentStatus();
  }

  void _cancelPayment() {
    Navigator.pop(context, 'cancelled');
  }

  @override
  Widget build(BuildContext context) {
    // For web platform, show a simple message
    if (kIsWeb) {
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
            onPressed: _cancelPayment,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.payment,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'تم فتح صفحة الدفع في المتصفح',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'يرجى إتمام عملية الدفع في المتصفح ثم العودة للتطبيق',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _checkPaymentStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('تحقق من حالة الدفع'),
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
          onPressed: _cancelPayment,
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _webViewController),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: AppColors.background.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
          
          // Error overlay
          if (_hasError)
            Container(
              color: AppColors.background,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'حدث خطأ',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _isLoading = true;
                              });
                              _webViewController.reload();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
                            ),
                            child: const Text('إعادة المحاولة'),
                          ),
                          ElevatedButton(
                            onPressed: _cancelPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.surface,
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
