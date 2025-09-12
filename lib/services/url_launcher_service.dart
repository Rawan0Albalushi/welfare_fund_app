import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Service for launching URLs with platform-specific behavior
class UrlLauncherService {
  /// Opens a checkout URL with appropriate behavior for each platform
  /// 
  /// For web: Opens in the same tab using webOnlyWindowName: '_self'
  /// For mobile: Opens in a new tab/window
  static Future<void> openCheckout(String checkoutUrl) async {
    if (kIsWeb) {
      // For web platform, open in same tab
      await launchUrlString(
        checkoutUrl,
        webOnlyWindowName: '_self',
      );
    } else {
      // For mobile platforms, open in new tab
      await launchUrlString(
        checkoutUrl,
        webOnlyWindowName: '_blank',
      );
    }
  }

  /// Opens a URL directly using dart:html (web only)
  /// Alternative method for web platform
  static void openCheckoutDirect(String checkoutUrl) {
    if (kIsWeb) {
      // This would require dart:html import
      // html.window.location.assign(checkoutUrl);
      // For now, use the launchUrlString method above
      openCheckout(checkoutUrl);
    }
  }
}
