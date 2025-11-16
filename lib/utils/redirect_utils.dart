enum PaymentRedirectType { success, cancel, none }

class PaymentRedirectResult {
  final PaymentRedirectType type;
  final Map<String, String> queryParams;
  const PaymentRedirectResult(this.type, this.queryParams);
}

PaymentRedirectResult parsePaymentRedirect(Uri uri) {
  if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'payment') {
    final action = uri.pathSegments[1];
    if (action == 'success') {
      return PaymentRedirectResult(PaymentRedirectType.success, uri.queryParameters);
    }
    if (action == 'cancel') {
      return PaymentRedirectResult(PaymentRedirectType.cancel, uri.queryParameters);
    }
  }
  return const PaymentRedirectResult(PaymentRedirectType.none, {});
}


