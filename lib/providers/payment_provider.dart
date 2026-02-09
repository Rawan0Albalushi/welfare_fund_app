import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_response.dart' hide PaymentStatusResponse;
import '../models/payment_status_response.dart';
import '../services/payment_service.dart';
import '../services/donation_service.dart';
import '../constants/app_config.dart';

enum PaymentState {
  initial,
  loading,
  sessionCreated,
  paymentInProgress,
  paymentSuccess,
  paymentFailed,
  paymentCancelled,
  paymentExpired,
}

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final DonationService _donationService = DonationService();

  PaymentState _state = PaymentState.initial;
  PaymentResponse? _paymentResponse;
  PaymentStatusResponse? _statusResponse;
  String? _currentSessionId;
  String? _currentDonationId; // ✅ إضافة: حفظ donation_id للتحقق من الحالة
  String? _errorMessage;
  double _currentAmount = 0.0;
  Timer? _pollingTimer;
  bool _isPolling = false;

  // Getters
  PaymentState get state => _state;
  PaymentResponse? get paymentResponse => _paymentResponse;
  PaymentStatusResponse? get statusResponse => _statusResponse;
  String? get currentSessionId => _currentSessionId;
  String? get currentDonationId => _currentDonationId; // ✅ إضافة: getter للـ donation_id
  String? get errorMessage => _errorMessage;
  double get currentAmount => _currentAmount;
  bool get isLoading => _state == PaymentState.loading;
  bool get isPaymentInProgress => _state == PaymentState.paymentInProgress;

  /// تهيئة الحالة قبل إنشاء جلسة
  void initializePayment(double amount) {
    _currentAmount = amount;
    _state = PaymentState.initial;
    _errorMessage = null;
    _paymentResponse = null;
    _statusResponse = null;
    _currentSessionId = null;
    _currentDonationId = null; // ✅ إصلاح: إعادة ضبط donation_id عند التهيئة
    notifyListeners();
  }

  /// إنشاء التبرع مع الدفع مباشرة (الطريقة الموصى بها)
  Future<void> initiateDonationWithPayment({
    required double amount,
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    String? message,
    String? itemId,
    String? itemType,   // 'program' | 'campaign'
    int? programId,
    int? campaignId,
    String? note,
    bool isAnonymous = false,
  }) async {
    try {
      _state = PaymentState.loading;
      _errorMessage = null;
      notifyListeners();

      // تحديد itemId و itemType إذا لم يتم توفيرهما
      String finalItemId = itemId ?? '';
      String finalItemType = itemType ?? 'program';
      
      if (programId != null) {
        finalItemId = programId.toString();
        finalItemType = 'program';
      } else if (campaignId != null) {
        finalItemId = campaignId.toString();
        finalItemType = 'campaign';
      }

      // ⚠️ لا نطبع معلومات حساسة في الإنتاج
      if (kDebugMode) {
        debugPrint('PaymentProvider: Initiating donation payment');
      }

      // الحصول على origin للمنصة الويب
      // ✅ إصلاح: استخدام AppConfig.serverBaseUrl بدلاً من Uri.base.origin
      // Uri.base.origin يعيد file:/// على الموبايل وليس URL صالح
      String origin;
      if (kIsWeb) {
        // على الويب، يمكن استخدام Uri.base.origin
        try {
          origin = Uri.base.origin;
          if (!origin.startsWith('http://') && !origin.startsWith('https://')) {
            origin = AppConfig.serverBaseUrl;
          }
        } catch (e) {
          origin = AppConfig.serverBaseUrl;
        }
      } else {
        // على الموبايل، استخدم serverBaseUrl مباشرة
        // ⚠️ تأكد من أن serverBaseUrl في القائمة البيضاء في الباكند
        origin = AppConfig.serverBaseUrl;
      }
      
      // ⚠️ لا نطبع origin في الإنتاج لأسباب أمنية
      if (kDebugMode) {
        debugPrint('PaymentProvider: Origin configured');
      }
      
      final result = await _donationService.createDonationWithPayment(
        itemId: finalItemId,
        itemType: finalItemType,
        amount: amount,
        donorName: donorName ?? 'متبرع',
        donorEmail: donorEmail,
        donorPhone: donorPhone,
        message: message ?? note ?? 'تبرع',
        isAnonymous: isAnonymous,
        returnOrigin: origin,
      );

      if (result['ok'] == true && result['payment_url'] != null) {
        _currentSessionId = result['payment_session_id']?.toString();
        _currentDonationId = result['donation_id']?.toString() ??
            result['data']?['donation']?['donation_id']?.toString() ??
            result['data']?['donation']?['id']?.toString();
        _currentAmount = amount;
        _state = PaymentState.sessionCreated;

        _paymentResponse = PaymentResponse(
          success: true,
          sessionId: _currentSessionId,
          paymentUrl: result['payment_url'].toString(),
          message: 'تم إنشاء التبرع بنجاح',
        );

        notifyListeners();
      } else {
        final backendMsg = result['error_message']?.toString() ?? '';
        final paymentError = result['payment_error'];
        final did = result['donation_id']?.toString() ??
            result['data']?['donation']?['donation_id']?.toString() ??
            result['data']?['donation']?['id']?.toString();
        if (kDebugMode) {
          debugPrint('═══════════════════════════════════════════════════════════');
          debugPrint('🔴 [PaymentProvider] فشل إنشاء جلسة الدفع');
          debugPrint('🔴 result keys: ${result.keys.toList()}');
          debugPrint('🔴 error_message: $backendMsg');
          debugPrint('🔴 payment_error: $paymentError');
          debugPrint('🔴 donation_id: $did');
          debugPrint('═══════════════════════════════════════════════════════════');
        }
        if (backendMsg.toLowerCase().contains('payment session failed') ||
            backendMsg.toLowerCase().contains('donation created but')) {
          _errorMessage = 'تم إنشاء التبرع لكن تعذر فتح صفحة الدفع. يرجى المحاولة لاحقاً أو التواصل مع الدعم.';
        } else {
          _errorMessage = backendMsg.isNotEmpty ? backendMsg : 'فشل في إنشاء التبرع';
        }
        _currentDonationId = did;
        _currentAmount = amount;
        _state = PaymentState.paymentFailed;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('🔴 [PaymentProvider] استثناء أثناء initiateDonationWithPayment');
        debugPrint('🔴 الاستثناء: $e');
        debugPrint('🔴 Stack trace: $stackTrace');
        debugPrint('═══════════════════════════════════════════════════════════');
      }
      _errorMessage = 'حدث خطأ في إنشاء التبرع. يرجى المحاولة مرة أخرى';
      _state = PaymentState.paymentFailed;
      notifyListeners();
    }
  }

  /// إنشاء جلسة الدفع مع الباكند (تستدعي createPaymentSession V2 داخليًا)
  Future<void> initiatePayment({
    required double amount,
    String? donorName,
    String? donorEmail, // لا تُستخدم في الباكند الحالي (مسموح تمريرها بلا ضرر)
    String? donorPhone, // لا تُستخدم في الباكند الحالي
    String? message,    // سيُعرض كاسم المنتج في صفحة ثواني
    String? itemId,     // يمكن تمرير program/campaign من هنا (سيحوّلها السيرفس)
    String? itemType,   // 'program' | 'campaign'
    int? programId,     // بديل أوضح لـ itemId/itemType
    int? campaignId,    // بديل أوضح لـ itemId/itemType
    String? note,       // ملاحظة تصل للباكند
    String type = 'quick',
  }) async {
    try {
      _state = PaymentState.loading;
      _errorMessage = null;
      notifyListeners();

      final clientReferenceId = _paymentService.generateClientReferenceId();
      final returnUrl = 'about:blank'; // لن يُستخدم، موجود للتوافق فقط

      // إذا وفّرتِ programId/campaignId نمرّرها مباشرة؛ وإلا نرسل itemId/itemType (سيحوّلها السيرفس)
      final response = await _paymentService.createPaymentSession(
        amount: amount,
        clientReferenceId: clientReferenceId,
        returnUrl: returnUrl, // مُهمَل في الباكند
        donorName: donorName ?? 'متبرع',
        donorEmail: donorEmail,
        donorPhone: donorPhone,
        message: message ?? 'تبرع',
        itemId: itemId,
        itemType: itemType,
        programId: programId,
        campaignId: campaignId,
        note: note ?? message,
        type: type,
      );

      if (response.success && response.sessionId != null && response.paymentUrl != null) {
        _paymentResponse = response;
        _currentSessionId = response.sessionId;
        // ✅ إضافة: استخراج donation_id من raw response
        _currentDonationId = response.raw?['data']?['donation']?['donation_id']?.toString() ??
                           response.raw?['donation_id']?.toString();
        _currentAmount = amount;
        _state = PaymentState.sessionCreated;
        notifyListeners();
      } else {
        _errorMessage = response.error ?? response.message ?? 'حدث خطأ في إنشاء جلسة الدفع';
        _state = PaymentState.paymentFailed;
        notifyListeners();
      }
    } catch (e) {
      // ⚠️ لا نعرض تفاصيل الخطأ للمستخدم لأسباب أمنية
      if (kDebugMode) {
        debugPrint('PaymentProvider: Error in initiatePayment: $e');
      }
      _errorMessage = 'حدث خطأ في إنشاء جلسة الدفع. يرجى المحاولة مرة أخرى';
      _state = PaymentState.paymentFailed;
      notifyListeners();
    }
  }

  /// استدعِها عند فتح الـ WebView
  void startPayment() {
    if (_state == PaymentState.sessionCreated) {
      _state = PaymentState.paymentInProgress;
      notifyListeners();
    }
  }

  /// دالة مساعدة: التعامل مع رسالة صفحات الـ Bridge (success/cancel) القادمة من الـ WebView
  /// - في flutter_inappwebview ستصلك Map مباشرة.
  /// - في webview_flutter ستصلك String (JSON) عبر JavascriptChannel.
  Future<void> handleBridgeMessage(dynamic payload) async {
    try {
      Map<String, dynamic> data;

      if (payload is String) {
        data = jsonDecode(payload) as Map<String, dynamic>;
      } else if (payload is Map) {
        data = Map<String, dynamic>.from(payload);
      } else {
        // غير معروف
        return;
      }

      final String status = (data['status']?.toString().toLowerCase() ?? 'unknown');
      final String? sid = data['session_id']?.toString();

      // لو الصفحة رجّعت session_id نحدّثه (اختياري)
      if (sid != null && sid.isNotEmpty) {
        _currentSessionId = sid;
      }

      if (status == 'success') {
        // لا نعلن النجاح مباشرة — نتحقق من الباكند
        await checkPaymentStatus();
      } else if (status == 'cancel' || status == 'cancelled' || status == 'canceled') {
        _state = PaymentState.paymentCancelled;
        _errorMessage = 'تم إلغاء عملية الدفع';
        notifyListeners();
      } else {
        // في حالات أخرى، جرّبي التحقق
        await checkPaymentStatus();
      }
    } catch (_) {
      // تجاهل أي parsing error وحاول الاستعلام عن الحالة مباشرة
      await checkPaymentStatus();
    }
  }

  /// إيقاف الـ polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  /// بدء الـ polling عند حالة pending
  void _startPolling() {
    if (_isPolling || _currentSessionId == null) return;
    
    _isPolling = true;
    _pollingTimer?.cancel();
    
    // إعادة الفحص كل 3 ثواني
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_state != PaymentState.paymentInProgress) {
        _stopPolling();
        return;
      }
      await checkPaymentStatus();
    });
  }

  /// التحقق من حالة الدفع من الباكند
  /// ✅ محسّن: يستخدم mobileSuccess إذا كان donationId متوفراً (أكثر دقة)
  Future<void> checkPaymentStatus() async {
    if (_currentSessionId == null && _currentDonationId == null) {
      _errorMessage = 'لا يوجد معرف جلسة أو تبرع صالح';
      _state = PaymentState.paymentFailed;
      _stopPolling();
      notifyListeners();
      return;
    }

    try {
      // لا نغير الحالة إذا كانت paymentInProgress (لنعرض حالة الانتظار)
      if (_state != PaymentState.paymentInProgress) {
        _state = PaymentState.loading;
        notifyListeners();
      }

      // ✅ إضافة: استخدام mobileSuccess إذا كان donationId متوفراً (أفضل دقة)
      PaymentStatusResponse? response;
      if (_currentDonationId != null) {
        try {
          final mobileResult = await _paymentService.mobileSuccess(
            donationId: _currentDonationId!,
            sessionId: _currentSessionId,
          );
          
          // تحويل mobileSuccess response إلى PaymentStatusResponse
          final donationStatus = mobileResult['donation_status']?.toString() ?? 
                                mobileResult['status']?.toString();
          final paymentStatusFromThawani = mobileResult['payment_status_from_thawani']?.toString();
          
          // إنشاء PaymentStatusResponse من mobileSuccess response
          response = PaymentStatusResponse(
            success: mobileResult['status'] == 'success' || donationStatus == 'paid',
            status: _mapStatusFromString(donationStatus ?? paymentStatusFromThawani ?? 'pending'),
            sessionId: mobileResult['session_id']?.toString() ?? _currentSessionId,
            message: mobileResult['message']?.toString(),
            raw: mobileResult,
          );
          
          if (kDebugMode) {
            debugPrint('PaymentProvider: Used mobileSuccess endpoint for status check');
          }
        } catch (e) {
          // إذا فشل mobileSuccess، نستخدم checkPaymentStatus كـ fallback
          if (kDebugMode) {
            debugPrint('PaymentProvider: mobileSuccess failed, falling back to checkPaymentStatus: $e');
          }
        }
      }
      
      // Fallback: استخدام checkPaymentStatus إذا لم يكن donationId متوفراً أو فشل mobileSuccess
      if (response == null && _currentSessionId != null) {
        response = await _paymentService.checkPaymentStatus(_currentSessionId!);
      }
      
      if (response == null) {
        throw Exception('فشل في التحقق من حالة الدفع');
      }
      
      _statusResponse = response;

      // استخدام message من الاستجابة إذا كانت موجودة
      final String? responseMessage = response.message;

      if (response.success && response.status == PaymentStatus.completed) {
        // فقط عند completed نعتبره نجاح
        _state = PaymentState.paymentSuccess;
        _errorMessage = null;
        _stopPolling();
      } else {
        switch (response.status) {
          case PaymentStatus.completed:
            // لا يجب أن نصل هنا لأن success && completed تم التعامل معه أعلاه
            _state = PaymentState.paymentSuccess;
            _errorMessage = null;
            _stopPolling();
            break;
          case PaymentStatus.failed:
            _state = PaymentState.paymentFailed;
            // استخدام message إذا كانت موجودة، وإلا error
            _errorMessage = responseMessage ?? response.error ?? 'فشل في عملية الدفع';
            _stopPolling();
            break;
          case PaymentStatus.cancelled:
            _state = PaymentState.paymentCancelled;
            _errorMessage = responseMessage ?? 'تم إلغاء عملية الدفع';
            _stopPolling();
            break;
          case PaymentStatus.expired:
            _state = PaymentState.paymentExpired;
            _errorMessage = responseMessage ?? 'انتهت صلاحية جلسة الدفع';
            _stopPolling();
            break;
          case PaymentStatus.pending:
            // حالة الانتظار - نعرض رسالة الانتظار ونبدأ polling
            _state = PaymentState.paymentInProgress;
            _errorMessage = null; // لا نعرض خطأ عند pending
            // استخدام message إذا كانت موجودة لعرض حالة الانتظار
            if (responseMessage != null && responseMessage.isNotEmpty) {
              // يمكن حفظ الرسالة في متغير منفصل للعرض
            }
            _startPolling();
            break;
          default:
            _state = PaymentState.paymentFailed;
            _errorMessage = responseMessage ?? response.error ?? 'حالة دفع غير معروفة';
            _stopPolling();
        }
      }

      notifyListeners();
    } catch (e) {
      // ⚠️ لا نعرض تفاصيل الخطأ للمستخدم لأسباب أمنية
      if (kDebugMode) {
        debugPrint('PaymentProvider: Error checking payment status: $e');
      }
      _errorMessage = 'حدث خطأ في التحقق من حالة الدفع. يرجى المحاولة مرة أخرى';
      _state = PaymentState.paymentFailed;
      _stopPolling();
      notifyListeners();
    }
  }

  /// إلغاء الدفع يدويًا (لو أغلق المستخدم الـ WebView مثلاً)
  void cancelPayment() {
    _stopPolling();
    _state = PaymentState.paymentCancelled;
    _errorMessage = 'تم إلغاء عملية الدفع';
    notifyListeners();
  }

  /// إعادة ضبط الحالة
  void resetPaymentState() {
    _stopPolling();
    _state = PaymentState.initial;
    _paymentResponse = null;
    _statusResponse = null;
    _currentSessionId = null;
    _currentDonationId = null; // ✅ إضافة: إعادة ضبط donation_id
    _errorMessage = null;
    _currentAmount = 0.0;
    notifyListeners();
  }
  
  /// ✅ إضافة: دالة مساعدة لتحويل حالة الدفع من string إلى PaymentStatus
  PaymentStatus _mapStatusFromString(String? statusStr) {
    if (statusStr == null) return PaymentStatus.unknown;
    
    final status = statusStr.toLowerCase().trim();
    switch (status) {
      case 'paid':
      case 'success':
      case 'completed':
        return PaymentStatus.completed;
      case 'pending':
      case 'unpaid':
      case 'awaiting_payment':
        return PaymentStatus.pending;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      case 'failed':
      case 'error':
      case 'declined':
        return PaymentStatus.failed;
      case 'expired':
        return PaymentStatus.expired;
      default:
        return PaymentStatus.unknown;
    }
  }

  /// إعادة المحاولة بنفس المبلغ
  Future<void> retryPayment({
    String? donorName,
    String? message,
    String? itemId,
    String? itemType,
    int? programId,
    int? campaignId,
    String? note,
    String type = 'quick',
  }) async {
    if (_currentAmount > 0) {
      await initiatePayment(
        amount: _currentAmount,
        donorName: donorName,
        message: message,
        itemId: itemId,
        itemType: itemType,
        programId: programId,
        campaignId: campaignId,
        note: note,
        type: type,
      );
    }
  }

  /// رابط الدفع لعرضه داخل WebView
  String? get paymentUrl => _paymentResponse?.paymentUrl;

  /// هل الدفع ناجح؟
  bool get isPaymentSuccessful => _state == PaymentState.paymentSuccess;

  /// هل الدفع فشل (يشمل الإلغاء والانتهاء)؟
  bool get isPaymentFailed =>
      _state == PaymentState.paymentFailed ||
      _state == PaymentState.paymentCancelled ||
      _state == PaymentState.paymentExpired;

  /// رسالة نجاح افتراضية
  String get successMessage {
    // استخدام message من الاستجابة إذا كانت موجودة
    if (_statusResponse?.message != null && _statusResponse!.message!.isNotEmpty) {
      return _statusResponse!.message!;
    }
    if (_statusResponse?.isCompleted == true) {
      return 'تم إتمام عملية الدفع بنجاح! شكراً لك على تبرعك.';
    }
    return 'تم إتمام العملية بنجاح';
  }

  /// رسالة حالة الانتظار
  String get pendingMessage {
    // استخدام message من الاستجابة إذا كانت موجودة
    if (_statusResponse?.message != null && _statusResponse!.message!.isNotEmpty) {
      return _statusResponse!.message!;
    }
    return 'جاري التحقق من حالة الدفع...';
  }

  /// هل الحالة pending؟
  bool get isPending => _state == PaymentState.paymentInProgress && 
                       (_statusResponse?.isPending ?? false);

  /// رسالة الخطأ للعرض
  String get displayErrorMessage => _errorMessage ?? 'حدث خطأ غير متوقع';

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
