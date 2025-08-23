import 'package:flutter/material.dart';
import '../models/payment_response.dart';
import '../models/payment_status_response.dart';
import '../services/payment_service.dart';

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

  /// Initialize payment with amount
  void initializePayment(double amount) {
    _currentAmount = amount;
    _state = PaymentState.initial;
    _errorMessage = null;
    _paymentResponse = null;
    _statusResponse = null;
    _currentSessionId = null;
    notifyListeners();
  }

  /// Create payment session
  Future<void> initiatePayment({
    required double amount,
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    String? message,
    String? itemId,
    String? itemType,
  }) async {
    try {
      _state = PaymentState.loading;
      _errorMessage = null;
      notifyListeners();

      final clientReferenceId = _paymentService.generateClientReferenceId();
      final returnUrl = _paymentService.generateReturnUrl();

             final response = await _paymentService.createPaymentSession(
         amount: amount,
         clientReferenceId: clientReferenceId,
         returnUrl: returnUrl,
         donorName: donorName ?? 'متبرع',
         donorEmail: donorEmail ?? 'donor@example.com',
         donorPhone: donorPhone ?? '+96812345678',
         message: message ?? 'تبرع خيري - صندوق رعاية الطلاب',
         itemId: itemId,
         itemType: itemType,
       );

      if (response.success && response.sessionId != null && response.paymentUrl != null) {
        _paymentResponse = response;
        _currentSessionId = response.sessionId;
        _currentAmount = amount;
        _state = PaymentState.sessionCreated;
        notifyListeners();
      } else {
        _errorMessage = response.error ?? 'حدث خطأ في إنشاء جلسة الدفع';
        _state = PaymentState.paymentFailed;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ غير متوقع: $e';
      _state = PaymentState.paymentFailed;
      notifyListeners();
    }
  }

  /// Start payment process (open WebView)
  void startPayment() {
    if (_state == PaymentState.sessionCreated) {
      _state = PaymentState.paymentInProgress;
      notifyListeners();
    }
  }

  /// Check payment status
  Future<void> checkPaymentStatus() async {
    if (_currentSessionId == null) {
      _errorMessage = 'لا يوجد معرف جلسة صالح';
      _state = PaymentState.paymentFailed;
      notifyListeners();
      return;
    }

    try {
      _state = PaymentState.loading;
      notifyListeners();

      final response = await _paymentService.checkPaymentStatus(_currentSessionId!);
      _statusResponse = response;

      if (response.success) {
        switch (response.status) {
          case PaymentStatus.completed:
            _state = PaymentState.paymentSuccess;
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

  /// Cancel payment
  void cancelPayment() {
    _state = PaymentState.paymentCancelled;
    _errorMessage = 'تم إلغاء عملية الدفع';
    notifyListeners();
  }

  /// Reset payment state
  void resetPaymentState() {
    _state = PaymentState.initial;
    _paymentResponse = null;
    _statusResponse = null;
    _currentSessionId = null;
    _errorMessage = null;
    _currentAmount = 0.0;
    notifyListeners();
  }

  /// Retry payment
  Future<void> retryPayment() async {
    if (_currentAmount > 0) {
      await initiatePayment(amount: _currentAmount);
    }
  }

  /// Get payment URL for WebView
  String? get paymentUrl {
    return _paymentResponse?.paymentUrl;
  }

  /// Check if payment is successful
  bool get isPaymentSuccessful {
    return _state == PaymentState.paymentSuccess;
  }

  /// Check if payment failed
  bool get isPaymentFailed {
    return _state == PaymentState.paymentFailed || 
           _state == PaymentState.paymentCancelled || 
           _state == PaymentState.paymentExpired;
  }

  /// Get success message
  String get successMessage {
    if (_statusResponse?.isCompleted == true) {
      return 'تم إتمام عملية الدفع بنجاح! شكراً لك على تبرعك.';
    }
    return 'تم إتمام العملية بنجاح';
  }

  /// Get error message for display
  String get displayErrorMessage {
    return _errorMessage ?? 'حدث خطأ غير متوقع';
  }
}
