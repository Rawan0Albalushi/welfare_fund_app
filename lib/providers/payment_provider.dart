import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/payment_response.dart' hide PaymentStatusResponse;
import '../models/payment_status_response.dart';
import '../services/payment_service.dart';
import '../services/donation_service.dart';

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
  String? _errorMessage;
  double _currentAmount = 0.0;

  // Getters
  PaymentState get state => _state;
  PaymentResponse? get paymentResponse => _paymentResponse;
  PaymentStatusResponse? get statusResponse => _statusResponse;
  String? get currentSessionId => _currentSessionId;
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

      print('PaymentProvider: Creating donation with payment for $finalItemType: $finalItemId, amount: $amount');

      // الحصول على origin للمنصة الويب
      String origin;
      try {
        origin = Uri.base.origin;
        // إذا كان origin غير صالح (مثل file:/// على Android)، استخدم fallback
        if (!origin.startsWith('http://') && !origin.startsWith('https://')) {
          origin = 'http://localhost:8000'; // Fallback للمنصات المحمولة
        }
      } catch (e) {
        origin = 'http://localhost:8000'; // Fallback في حالة الخطأ
      }
      
      print('PaymentProvider: Using origin: $origin');
      
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
        _currentAmount = amount;
        _state = PaymentState.sessionCreated;
        
        // إنشاء PaymentResponse وهمي للتوافق
        _paymentResponse = PaymentResponse(
          success: true,
          sessionId: _currentSessionId,
          paymentUrl: result['payment_url'].toString(),
          message: 'تم إنشاء التبرع بنجاح',
        );
        
        notifyListeners();
      } else {
        _errorMessage = 'فشل في إنشاء التبرع';
        _state = PaymentState.paymentFailed;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      // طباعة الخطأ للتصحيح فقط (في بيئة التطوير)
      print('PaymentProvider: Error in initiateDonationWithPayment');
      // لا نطبع تفاصيل الخطأ في رسالة المستخدم لأسباب أمنية
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
        _currentAmount = amount;
        _state = PaymentState.sessionCreated;
        notifyListeners();
      } else {
        _errorMessage = response.error ?? response.message ?? 'حدث خطأ في إنشاء جلسة الدفع';
        _state = PaymentState.paymentFailed;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ غير متوقع: $e';
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
        data = Map<String, dynamic>.from(payload as Map);
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

  /// التحقق من حالة الدفع من الباكند
  Future<void> checkPaymentStatus() async {
    if (_currentSessionId == null) {
      _errorMessage = 'لا يوجد معرف جلسة صالح';
      _state = PaymentState.paymentFailed;
      notifyListeners();
      return;
    }

    try {
      _state = (_state == PaymentState.paymentInProgress) ? PaymentState.paymentInProgress : PaymentState.loading;
      notifyListeners();

      final response = await _paymentService.checkPaymentStatus(_currentSessionId!);
      _statusResponse = response;

      if (response.success) {
        switch (response.status) {
          case PaymentStatus.completed:
            _state = PaymentState.paymentSuccess;
            _errorMessage = null;
            break;
          case PaymentStatus.failed:
            _state = PaymentState.paymentFailed;
            _errorMessage = response.error ?? 'فشل في عملية الدفع';
            break;
          case PaymentStatus.cancelled:
            _state = PaymentState.paymentCancelled;
            _errorMessage = 'تم إلغاء عملية الدفع';
            break;
          case PaymentStatus.expired:
            _state = PaymentState.paymentExpired;
            _errorMessage = 'انتهت صلاحية جلسة الدفع';
            break;
          case PaymentStatus.pending:
            _state = PaymentState.paymentInProgress;
            break;
          default:
            _state = PaymentState.paymentFailed;
            _errorMessage = 'حالة دفع غير معروفة';
        }
      } else {
        _state = PaymentState.paymentFailed;
        _errorMessage = response.error ?? 'حدث خطأ في التحقق من حالة الدفع';
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'حدث خطأ في التحقق من حالة الدفع: $e';
      _state = PaymentState.paymentFailed;
      notifyListeners();
    }
  }

  /// إلغاء الدفع يدويًا (لو أغلق المستخدم الـ WebView مثلاً)
  void cancelPayment() {
    _state = PaymentState.paymentCancelled;
    _errorMessage = 'تم إلغاء عملية الدفع';
    notifyListeners();
  }

  /// إعادة ضبط الحالة
  void resetPaymentState() {
    _state = PaymentState.initial;
    _paymentResponse = null;
    _statusResponse = null;
    _currentSessionId = null;
    _errorMessage = null;
    _currentAmount = 0.0;
    notifyListeners();
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
    if (_statusResponse?.isCompleted == true) {
      return 'تم إتمام عملية الدفع بنجاح! شكراً لك على تبرعك.';
    }
    return 'تم إتمام العملية بنجاح';
    }

  /// رسالة الخطأ للعرض
  String get displayErrorMessage => _errorMessage ?? 'حدث خطأ غير متوقع';
}
