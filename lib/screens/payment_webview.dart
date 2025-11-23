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
  DateTime? _successHandlingStartTime;

  /// التحقق من URL النجاح بشكل آمن
  /// ⚠️ مهم: نستخدم whitelist دقيق لمنع URL manipulation
  /// ✅ إصلاح: منع deep link URLs على الموبايل (مثل sfund.app://) لأن PaymentWebView يتعامل مع النتيجة مباشرة
  bool _isSuccessUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // ✅ إصلاح: منع deep link URLs (custom schemes) على الموبايل
      // هذه URLs تفتح التطبيق من جديد وتسبب فتح صفحة مكررة
      if (!kIsWeb && uri.scheme != 'http' && uri.scheme != 'https') {
        print('PaymentWebView: Blocking deep link URL (custom scheme): $url');
        return false;
      }
      
      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();
      
      // Whitelist للـ hosts المسموحة
      final allowedHosts = [
        'sfund.app',
        'thawani.om',
        'api.thawani.om',
        'localhost',
      ];
      
      // ✅ إصلاح: السماح بـ IP addresses المحلية (للاختبار)
      // التحقق من أن الـ host مسموح أو IP address محلي
      final isLocalIp = RegExp(r'^192\.168\.\d+\.\d+|^10\.\d+\.\d+\.\d+|^172\.(1[6-9]|2\d|3[01])\.\d+\.\d+|^127\.0\.0\.1').hasMatch(host);
      final isAllowedHost = isLocalIp || allowedHosts.any((allowed) => host.contains(allowed) || host.endsWith(allowed));
      if (!isAllowedHost) {
        return false;
      }
      
      // Whitelist للـ paths المسموحة
      final successPaths = [
        '/payment/bridge/success',
        '/payments/success',
        '/payments/mobile/success',
        '/pay/success',
        '/mobile/success',
      ];
      
      // التحقق من أن الـ path يطابق أحد المسارات المسموحة
      final isSuccessPath = successPaths.any((pathPattern) => path.contains(pathPattern));
      
      // للـ thawani.om، نتحقق من وجود 'success' في query parameters
      final hasSuccessParam = uri.queryParameters.containsKey('success') ||
                             uri.queryParameters.containsKey('status') && 
                             uri.queryParameters['status']?.toLowerCase() == 'success';
      
      return isSuccessPath || (host.contains('thawani.om') && hasSuccessParam) ||
             (path.contains('payment_success') && isAllowedHost) ||
             (path.contains('/mobile/success') && uri.queryParameters.containsKey('donation_id'));
    } catch (e) {
      // في حالة خطأ في parsing، نرفض URL
      return false;
    }
  }
  
  /// التحقق من URL الإلغاء بشكل آمن
  /// ⚠️ مهم: نستخدم whitelist دقيق لمنع URL manipulation
  /// ✅ إصلاح: منع deep link URLs على الموبايل (مثل sfund.app://) لأن PaymentWebView يتعامل مع النتيجة مباشرة
  bool _isCancelUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // ✅ إصلاح: منع deep link URLs (custom schemes) على الموبايل
      // هذه URLs تفتح التطبيق من جديد وتسبب فتح صفحة مكررة
      if (!kIsWeb && uri.scheme != 'http' && uri.scheme != 'https') {
        print('PaymentWebView: Blocking deep link URL (custom scheme): $url');
        return false;
      }
      
      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();
      
      // Whitelist للـ hosts المسموحة
      final allowedHosts = [
        'sfund.app',
        'thawani.om',
        'api.thawani.om',
        'localhost',
      ];
      
      // ✅ إصلاح: السماح بـ IP addresses المحلية (للاختبار)
      // التحقق من أن الـ host مسموح أو IP address محلي
      final isLocalIp = RegExp(r'^192\.168\.\d+\.\d+|^10\.\d+\.\d+\.\d+|^172\.(1[6-9]|2\d|3[01])\.\d+\.\d+|^127\.0\.0\.1').hasMatch(host);
      final isAllowedHost = isLocalIp || allowedHosts.any((allowed) => host.contains(allowed) || host.endsWith(allowed));
      if (!isAllowedHost) {
        return false;
      }
      
      // Whitelist للـ paths المسموحة
      final cancelPaths = [
        '/payment/bridge/cancel',
        '/payments/cancel',
        '/pay/cancel',
      ];
      
      // التحقق من أن الـ path يطابق أحد المسارات المسموحة
      final isCancelPath = cancelPaths.any((pathPattern) => path.contains(pathPattern));
      
      // للـ thawani.om، نتحقق من وجود 'cancel' في query parameters
      final hasCancelParam = uri.queryParameters.containsKey('cancel') ||
                             uri.queryParameters.containsKey('status') && 
                             uri.queryParameters['status']?.toLowerCase() == 'cancel';
      
      return isCancelPath || (host.contains('thawani.om') && hasCancelParam) ||
             (path.contains('payment_cancel') && isAllowedHost);
    } catch (e) {
      // في حالة خطأ في parsing، نرفض URL
      return false;
    }
  }

  void _cancelScheduledStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  Future<void> _safePop(Map<String, dynamic> payload) async {
    if (_hasPopped) return;
    _hasPopped = true;
    _cancelScheduledStatusCheck();

    // ✅ إصلاح: إغلاق WebView فوراً دون انتظار postFrameCallback
    // هذا يمنع التطبيق من البقاء معلق على صفحة الدفع
    if (mounted) {
      Navigator.pop(context, payload);
    } else {
      // إذا لم يكن mounted، نستخدم postFrameCallback كـ fallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, payload);
        }
      });
    }
  }

  Future<void> _handleSuccessNavigation(String url) async {
    if (_hasPopped || _hasCheckedStatus || _isHandlingSuccess) return;
    // إيقاف الـ polling فوراً قبل أي شيء
    print('PaymentWebView: Disabling polling and handling success navigation');
    _isHandlingSuccess = true;
    _successHandlingStartTime = DateTime.now();
    _pollingDisabled = true;
    _hasCheckedStatus = true;
    _cancelScheduledStatusCheck();

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      print('PaymentWebView: Fetching mobile success data...');
      // إضافة timeout لمدة 10 ثواني
      final response = await _donationService.fetchMobilePaymentSuccessData(successUrl: url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('PaymentWebView: Timeout fetching mobile success data');
              throw TimeoutException('Timeout fetching mobile success data');
            },
          );
      if (!mounted) return;

      // التحقق من حالة التبرع الفعلية قبل عرض النجاح
      final isActuallyCompleted = _verifyDonationStatus(response);
      if (!isActuallyCompleted) {
        print('PaymentWebView: Donation is still pending, continuing to poll instead of showing success');
        // إعادة تعيين الحالة للسماح بالانتقال عبر polling
        _isHandlingSuccess = false;
        _successHandlingStartTime = null;
        _pollingDisabled = false;
        _hasCheckedStatus = false;
        // استخدام polling للتحقق من الحالة والانتقال
        await _checkPaymentStatusAndComplete();
        return;
      }

      final payload = _buildSuccessResult(response, url);
      await _safePop(payload);
    } catch (e) {
      print('PaymentWebView: Error fetching mobile success data: $e');
      // إعادة تعيين الحالة للسماح بالانتقال عبر polling
      _isHandlingSuccess = false;
      _successHandlingStartTime = null;
      _pollingDisabled = false;
      _hasCheckedStatus = false;
      // استخدام polling للتحقق من الحالة والانتقال
      await _checkPaymentStatusAndComplete();
    } finally {
      // فقط إعادة تعيين حالة التحميل، الحالة الأخرى تُعاد في catch أو عند النجاح
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// التحقق من حالة التبرع الفعلية
  bool _verifyDonationStatus(Map<String, dynamic> response) {
    try {
      final dynamic rawData = response['data'];
      final Map<String, dynamic> data;
      if (rawData is Map<String, dynamic>) {
        data = Map<String, dynamic>.from(rawData);
      } else {
        data = response;
      }

      // استخراج بيانات التبرع
      final dynamic donationObj = data['donation'];
      final Map<String, dynamic> donationData;
      if (donationObj is Map<String, dynamic>) {
        donationData = Map<String, dynamic>.from(donationObj);
      } else {
        donationData = data;
      }

      // التحقق من donation_status
      final donationStatus = (data['donation_status'] ?? 
                              donationData['donation_status'] ?? 
                              donationData['status'] ?? 
                              data['status'])?.toString().toLowerCase().trim();
      
      // التحقق من payment_status_fromThawani
      final paymentStatusFromThawani = (data['payment_status_fromThawani'] ?? 
                                        donationData['payment_status_fromThawani'])?.toString().toLowerCase().trim();

      print('PaymentWebView: Verifying donation status - donation_status: $donationStatus, payment_status_fromThawani: $paymentStatusFromThawani');

      // إذا كان donation_status = pending أو unpaid أو payment_status_fromThawani = unpaid، التبرع قيد الانتظار
      if (donationStatus == 'pending' || donationStatus == 'unpaid' || paymentStatusFromThawani == 'unpaid') {
        print('PaymentWebView: Donation is pending/unpaid, cannot show success');
        return false;
      }

      // إذا كان donation_status = paid أو completed، التبرع ناجح
      if (donationStatus == 'paid' || donationStatus == 'completed') {
        print('PaymentWebView: Donation is paid/completed, can show success');
        return true;
      }

      // إذا كان payment_status_fromThawani = paid، التبرع ناجح
      if (paymentStatusFromThawani == 'paid') {
        print('PaymentWebView: Payment from Thawani is paid, can show success');
        return true;
      }

      // في حالة عدم التأكد، نتحقق من sessionId عبر API
      print('PaymentWebView: Status unclear, will verify via payment status API');
      return false; // سنتحقق عبر polling
    } catch (e) {
      print('PaymentWebView: Error verifying donation status: $e');
      return false; // في حالة الخطأ، نتحقق عبر polling
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

  /// التحقق من حالة الدفع عند اكتشاف success URL مباشرة (دون التحقق من _pollingDisabled)
  Future<void> _checkPaymentStatusImmediately() async {
    if (!mounted || _hasPopped || _isHandlingSuccess) {
      return;
    }

    try {
      final status = await _donationService.checkPaymentStatus(widget.sessionId);
      
      if (!mounted || _hasPopped || _isHandlingSuccess) {
        return;
      }

      print('PaymentWebView: Immediate payment status check result: ${status.status}');
      print('PaymentWebView: Is completed: ${status.isCompleted}');
      print('PaymentWebView: Is pending: ${status.isPending}');

      if (status.isCompleted && !status.isPending) {
        _hasCheckedStatus = true;
        await _safePop({
          'state': PaymentState.paymentSuccess.name,
          'sessionId': status.sessionId ?? widget.sessionId,
          if (status.amount != null) 'amount': status.amount,
          if (status.raw != null) 'rawResponse': status.raw,
        });
      } else if (status.isCancelled) {
        await _safePop({'state': PaymentState.paymentCancelled.name});
      } else if (status.isExpired) {
        await _safePop({'state': PaymentState.paymentExpired.name});
      } else if (status.isFailed) {
        await _safePop({
          'state': PaymentState.paymentFailed.name,
          if (status.error != null) 'error': status.error,
        });
      } else {
        // إذا كانت pending، نستمر في polling
        _pollingDisabled = false;
        await _checkPaymentStatusAndComplete();
      }
    } catch (e) {
      print('PaymentWebView: Error in immediate status check: $e');
      // في حالة الخطأ، نستمر في polling
      _pollingDisabled = false;
      await _checkPaymentStatusAndComplete();
    }
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
      print('PaymentWebView: Is pending: ${status.isPending}');
      print('PaymentWebView: Message: ${status.message}');

      // التحقق من pending أولاً - لا نعرض نجح إذا كانت الحالة pending
      if (status.isPending) {
        // حالة الانتظار - نستمر في الـ polling
        print('PaymentWebView: Payment is pending, continuing to poll...');
        if (_hasPopped || _pollingDisabled || _isHandlingSuccess) return;
        await Future.delayed(const Duration(seconds: 3));
        if (!_hasPopped && !_pollingDisabled && !_isHandlingSuccess) {
          await _checkPaymentStatusAndComplete();
        }
        return;
      }

      // التحقق من الحالة الفعلية للتأكد من عدم عرض النجاح عند pending
      // نتحقق من raw response للحصول على donation_status و payment_status_fromThawani
      bool isActuallyCompleted = status.isCompleted && !status.isPending;
      
      if (status.raw != null) {
        final raw = status.raw as Map<String, dynamic>;
        
        // البحث في raw_response أيضاً إذا كان موجوداً
        final Map<String, dynamic>? rawResponse = raw['raw_response'] is Map
            ? Map<String, dynamic>.from(raw['raw_response'] as Map)
            : null;
        
        // البحث في جميع المصادر المحتملة
        final donationStatus = (raw['donation_status'] ?? 
                               rawResponse?['donation_status'] ?? 
                               rawResponse?['data']?['donation']?['donation_status'] ??
                               rawResponse?['data']?['donation_status'])?.toString().toLowerCase().trim();
        
        final paymentStatusFromThawani = (raw['payment_status_fromThawani'] ?? 
                                         rawResponse?['payment_status_fromThawani'] ??
                                         rawResponse?['data']?['payment_status_fromThawani'])?.toString().toLowerCase().trim();
        
        print('PaymentWebView: Raw status check - donation_status: $donationStatus, payment_status_fromThawani: $paymentStatusFromThawani');
        
        // إذا كان donation_status = pending أو payment_status_fromThawani = unpaid، لا نعرض النجاح
        if (donationStatus == 'pending' || paymentStatusFromThawani == 'unpaid' || donationStatus == 'unpaid') {
          print('PaymentWebView: Donation is pending according to raw data, continuing to poll');
          isActuallyCompleted = false;
        }
      }

      // لا نعرض نجح إلا إذا كانت الحالة completed فعلاً وليست pending
      if (isActuallyCompleted) {
        // إذا كان هناك محاولة لمعالجة النجاح عبر mobile API، انتظر لمدة 12 ثانية كحد أقصى
        if (_isHandlingSuccess && _successHandlingStartTime != null) {
          final elapsed = DateTime.now().difference(_successHandlingStartTime!);
          if (elapsed.inSeconds < 12) {
            print('PaymentWebView: Success is being handled via mobile API, waiting... (${elapsed.inSeconds}s)');
            return;
          } else {
            print('PaymentWebView: Mobile API handling took too long (${elapsed.inSeconds}s), using polling result instead');
            _isHandlingSuccess = false;
            _successHandlingStartTime = null;
          }
        } else if (_isHandlingSuccess) {
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
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            // ✅ إصلاح: التحقق من HTTP URLs عند بدء التحميل لمنع أخطاء cleartext
            if (!kIsWeb) {
              try {
                final uri = Uri.parse(url);
                if (uri.scheme == 'http') {
                  if (_isSuccessUrl(url) || url.contains('success') || url.contains('payment/success') || url.contains('/payments/mobile/success')) {
                    print('PaymentWebView: Detected HTTP success URL at page start, checking status directly...');
                    // ✅ إصلاح: إغلاق WebView فوراً والتحقق من الحالة في الخلفية
                    _hasCheckedStatus = true;
                    _pollingDisabled = true;
                    Future.microtask(() async {
                      await _checkPaymentStatusImmediately();
                    });
                    return;
                  } else if (_isCancelUrl(url) || url.contains('cancel') || url.contains('payment/cancel')) {
                    print('PaymentWebView: Detected HTTP cancel URL at page start, returning cancelled...');
                    Future.microtask(() => _safePop({'state': PaymentState.paymentCancelled.name}));
                    return;
                  }
                }
              } catch (e) {
                print('PaymentWebView: Error parsing URL in onPageStarted: $e');
              }
            }
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            print('PaymentWebView: Page finished loading: $url');
            
            // ✅ إصلاح: التحقق من HTTP URLs قبل محاولة التعامل معها
            // إذا كان HTTP URL، نتعامل معه مباشرة دون انتظار تحميل الصفحة
            if (!kIsWeb) {
              try {
                final uri = Uri.parse(url);
                if (uri.scheme == 'http') {
                  if (_isSuccessUrl(url) || url.contains('success') || url.contains('payment/success') || url.contains('/payments/mobile/success')) {
                    print('PaymentWebView: Detected HTTP success URL, checking payment status directly...');
                    // ✅ إصلاح: إغلاق WebView فوراً والتحقق من الحالة في الخلفية
                    _hasCheckedStatus = true;
                    _pollingDisabled = true;
                    await _checkPaymentStatusImmediately();
                    return;
                  } else if (_isCancelUrl(url) || url.contains('cancel') || url.contains('payment/cancel')) {
                    print('PaymentWebView: Detected HTTP cancel URL, returning cancelled...');
                    _safePop({'state': PaymentState.paymentCancelled.name});
                    return;
                  }
                }
              } catch (e) {
                print('PaymentWebView: Error parsing URL in onPageFinished: $e');
              }
            }
            
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
            
            // ✅ إصلاح: منع deep link URLs (custom schemes) على الموبايل
            // هذه URLs تفتح التطبيق من جديد وتسبب فتح صفحة مكررة
            if (!kIsWeb) {
              try {
                final uri = Uri.parse(request.url);
                
                // ✅ إصلاح: منع HTTP URLs على الموبايل (cleartext not permitted)
                // Android يمنع تحميل HTTP URLs في WebView، لذلك نتعامل معها مباشرة
                if (uri.scheme == 'http') {
                  print('PaymentWebView: Blocking HTTP URL (cleartext not permitted): ${request.url}');
                  // إذا كان HTTP URL لصفحة success/cancel، نتعامل معها مباشرة
                  if (_isSuccessUrl(request.url) || request.url.contains('success') || request.url.contains('payment/success') || request.url.contains('/payments/mobile/success')) {
                    print('PaymentWebView: Handling success HTTP URL directly, checking status...');
                    // استخراج donation_id أو session_id من URL
                    final donationId = uri.queryParameters['donation_id'];
                    final sessionId = uri.queryParameters['session_id'] ?? widget.sessionId;
                    print('PaymentWebView: Success URL params - donationId: $donationId, sessionId: $sessionId');
                    // ✅ إصلاح: إغلاق WebView فوراً والتحقق من الحالة في الخلفية
                    // هذا يمنع التطبيق من البقاء معلق على صفحة الدفع
                    _hasCheckedStatus = true;
                    _pollingDisabled = true;
                    // إغلاق WebView فوراً والتحقق من الحالة بشكل async
                    Future.microtask(() async {
                      await _checkPaymentStatusImmediately();
                    });
                    return NavigationDecision.prevent;
                  } else if (_isCancelUrl(request.url) || request.url.contains('cancel') || request.url.contains('payment/cancel')) {
                    print('PaymentWebView: Handling cancel HTTP URL directly');
                    _safePop({'state': PaymentState.paymentCancelled.name});
                    return NavigationDecision.prevent;
                  }
                  // منع تحميل أي HTTP URL آخر في WebView
                  return NavigationDecision.prevent;
                }
                
                if (uri.scheme != 'http' && uri.scheme != 'https') {
                  print('PaymentWebView: Blocking deep link navigation (custom scheme): ${request.url}');
                  // إذا كان deep link لصفحة success/cancel، نتعامل معها مباشرة دون فتح التطبيق
                  if (request.url.contains('success') || request.url.contains('payment/success')) {
                    // استخراج session_id أو donation_id من URL إذا كان موجوداً
                    final sessionId = uri.queryParameters['session_id'] ?? widget.sessionId;
                    print('PaymentWebView: Handling success via deep link, checking status with sessionId: $sessionId');
                    // ✅ إصلاح: إغلاق WebView فوراً والتحقق من الحالة في الخلفية
                    _hasCheckedStatus = true;
                    _pollingDisabled = true;
                    Future.microtask(() async {
                      await _checkPaymentStatusImmediately();
                    });
                    return NavigationDecision.prevent;
                  } else if (request.url.contains('cancel') || request.url.contains('payment/cancel')) {
                    print('PaymentWebView: Handling cancel via deep link');
                    _safePop({'state': PaymentState.paymentCancelled.name});
                    return NavigationDecision.prevent;
                  }
                  // منع فتح أي deep link آخر
                  return NavigationDecision.prevent;
                }
              } catch (e) {
                print('PaymentWebView: Error parsing URL in navigation request: $e');
              }
            }
            
            if (_isSuccessUrl(request.url)) {
              print('PaymentWebView: Intercepting success URL');
              // ✅ إصلاح: إغلاق WebView فوراً والتحقق من الحالة في الخلفية
              _hasCheckedStatus = true;
              _pollingDisabled = true;
              Future.microtask(() async {
                await _checkPaymentStatusImmediately();
              });
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        // إذا تم pop بالفعل، لا نفعل شيء
        if (_hasPopped) return;
        
        // التحقق من حالة الدفع قبل السماح بالعودة
        print('PaymentWebView: Back button/swipe detected, checking payment status...');
        
        try {
          final status = await _donationService.checkPaymentStatus(widget.sessionId);
          
          print('PaymentWebView: Payment status on back: ${status.status}');
          print('PaymentWebView: Is pending: ${status.isPending}');
          print('PaymentWebView: Is completed: ${status.isCompleted}');
          
          // إذا كانت الحالة pending، نمنع العودة ونستمر في polling
          if (status.isPending) {
            print('PaymentWebView: Payment is pending, preventing back navigation');
            // نستمر في polling بدلاً من العودة
            if (!_hasPopped && !_pollingDisabled && !_isHandlingSuccess) {
              await _checkPaymentStatusAndComplete();
            }
            return;
          }
          
          // إذا كانت الحالة completed، نتحقق مرة أخرى من donation_status و payment_status_fromThawani
          if (status.isCompleted) {
            bool isActuallyCompleted = true;
            
            if (status.raw != null) {
              final raw = status.raw as Map<String, dynamic>;
              
              // البحث في raw_response أيضاً إذا كان موجوداً
              final Map<String, dynamic>? rawResponse = raw['raw_response'] is Map
                  ? Map<String, dynamic>.from(raw['raw_response'] as Map)
                  : null;
              
              // البحث في جميع المصادر المحتملة
              final donationStatus = (raw['donation_status'] ?? 
                                     rawResponse?['donation_status'] ?? 
                                     rawResponse?['data']?['donation']?['donation_status'] ??
                                     rawResponse?['data']?['donation_status'])?.toString().toLowerCase().trim();
              
              final paymentStatusFromThawani = (raw['payment_status_fromThawani'] ?? 
                                               rawResponse?['payment_status_fromThawani'] ??
                                               rawResponse?['data']?['payment_status_fromThawani'])?.toString().toLowerCase().trim();
              
              print('PaymentWebView: Raw status on back - donation_status: $donationStatus, payment_status_fromThawani: $paymentStatusFromThawani');
              
              // إذا كان donation_status = pending أو payment_status_fromThawani = unpaid، لا نعرض النجاح
              if (donationStatus == 'pending' || paymentStatusFromThawani == 'unpaid' || donationStatus == 'unpaid') {
                print('PaymentWebView: Donation is pending according to raw data, preventing back navigation');
                isActuallyCompleted = false;
              }
            }
            
            if (isActuallyCompleted && !status.isPending) {
              print('PaymentWebView: Payment is completed, allowing back navigation with success');
              if (!_hasPopped) {
                await _safePop({
                  'state': PaymentState.paymentSuccess.name,
                  'sessionId': status.sessionId ?? widget.sessionId,
                  if (status.amount != null) 'amount': status.amount,
                  if (status.raw != null) 'rawResponse': status.raw,
                });
              }
              return;
            }
          }
          
          // في حالات أخرى (failed, cancelled, expired)، نسمح بالعودة
          print('PaymentWebView: Payment is not pending, allowing back navigation');
          if (!_hasPopped) {
            if (status.isCancelled) {
              await _safePop({'state': PaymentState.paymentCancelled.name});
            } else if (status.isExpired) {
              await _safePop({'state': PaymentState.paymentExpired.name});
            } else if (status.isFailed) {
              await _safePop({
                'state': PaymentState.paymentFailed.name,
                if (status.error != null) 'error': status.error,
              });
            } else {
              // حالة غير معروفة، نعتبرها إلغاء
              await _safePop({'state': PaymentState.paymentCancelled.name});
            }
          }
        } catch (e) {
          print('PaymentWebView: Error checking payment status on back: $e');
          // في حالة الخطأ، نعتبرها إلغاء
          if (!_hasPopped) {
            await _safePop({'state': PaymentState.paymentCancelled.name});
          }
        }
      },
      child: Scaffold(
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
            onPressed: () async {
              // التحقق من حالة الدفع قبل الإغلاق
              print('PaymentWebView: Close button pressed, checking payment status...');
              try {
                final status = await _donationService.checkPaymentStatus(widget.sessionId);
                
                // إذا كانت الحالة pending، نمنع الإغلاق
                if (status.isPending) {
                  print('PaymentWebView: Payment is pending, preventing close');
                  // نستمر في polling
                  if (!_hasPopped && !_pollingDisabled && !_isHandlingSuccess) {
                    await _checkPaymentStatusAndComplete();
                  }
                  return;
                }
                
                // التحقق من donation_status و payment_status_fromThawani
                if (status.isCompleted) {
                  bool isActuallyCompleted = true;
                  
                  if (status.raw != null) {
                    final raw = status.raw as Map<String, dynamic>;
                    
                    // البحث في raw_response أيضاً إذا كان موجوداً
                    final Map<String, dynamic>? rawResponse = raw['raw_response'] is Map
                        ? Map<String, dynamic>.from(raw['raw_response'] as Map)
                        : null;
                    
                    // البحث في جميع المصادر المحتملة
                    final donationStatus = (raw['donation_status'] ?? 
                                           rawResponse?['donation_status'] ?? 
                                           rawResponse?['data']?['donation']?['donation_status'] ??
                                           rawResponse?['data']?['donation_status'])?.toString().toLowerCase().trim();
                    
                    final paymentStatusFromThawani = (raw['payment_status_fromThawani'] ?? 
                                                     rawResponse?['payment_status_fromThawani'] ??
                                                     rawResponse?['data']?['payment_status_fromThawani'])?.toString().toLowerCase().trim();
                    
                    if (donationStatus == 'pending' || paymentStatusFromThawani == 'unpaid' || donationStatus == 'unpaid') {
                      isActuallyCompleted = false;
                    }
                  }
                  
                  if (isActuallyCompleted && !status.isPending) {
                    await _safePop({
                      'state': PaymentState.paymentSuccess.name,
                      'sessionId': status.sessionId ?? widget.sessionId,
                      if (status.amount != null) 'amount': status.amount,
                      if (status.raw != null) 'rawResponse': status.raw,
                    });
                    return;
                  }
                }
                
                // في حالات أخرى، نعتبرها إلغاء
                await _safePop({'state': PaymentState.paymentCancelled.name});
              } catch (e) {
                print('PaymentWebView: Error checking payment status on close: $e');
                await _safePop({'state': PaymentState.paymentCancelled.name});
              }
            },
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
      ),
    );
  }

  @override
  void dispose() {
    _cancelScheduledStatusCheck();
    super.dispose();
  }
}