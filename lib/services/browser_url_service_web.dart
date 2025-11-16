// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

abstract class BrowserUrlService {
  void cleanQuery();
}

class BrowserUrlServiceImpl implements BrowserUrlService {
  @override
  void cleanQuery() {
    try {
      final uri = html.window.location;
      final cleanUrl = '${uri.protocol}//${uri.host}${uri.port.isNotEmpty ? ':${uri.port}' : ''}${uri.pathname}';
      html.window.history.replaceState(null, html.document.title, cleanUrl);
    } catch (_) {
      // Swallow errors silently on web
    }
  }
}


