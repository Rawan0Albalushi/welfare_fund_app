abstract class BrowserUrlService {
  void cleanQuery();
}

class BrowserUrlServiceImpl implements BrowserUrlService {
  @override
  void cleanQuery() {
    // No-op on non-web platforms
  }
}


