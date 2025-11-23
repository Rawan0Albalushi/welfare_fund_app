import 'package:flutter/foundation.dart';
import '../models/setting_page_model.dart';
import '../services/api_client.dart';
import 'package:dio/dio.dart';

class SettingPageProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  SettingPageModel? _page;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SettingPageModel? get page => _page;

  Future<void> fetchPage(String key) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final apiClient = ApiClient();
      final dio = apiClient.dio;

      // Build the endpoint URL
      // The endpoint should be: /api/settings-pages/{key}
      // But since we're using apiBaseUrlV1 which already includes /api/v1
      // We need to check if the endpoint should be /settings-pages/{key} or /api/settings-pages/{key}
      // Based on the requirement, it should be GET /api/settings-pages/{key}
      // Since apiBaseUrlV1 is /api/v1, we'll use /settings-pages/{key} and let the backend handle it
      // Or we can use the authBaseUrl which is /api
      
      final endpoint = '/settings-pages/$key';
      
      if (kDebugMode) {
        debugPrint('SettingPageProvider: Fetching page with key: $key');
        debugPrint('SettingPageProvider: Endpoint: $endpoint');
      }

      final response = await dio.get(endpoint);

      if (kDebugMode) {
        debugPrint('SettingPageProvider: Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Handle different response formats
        Map<String, dynamic> pageData;
        if (data is Map<String, dynamic>) {
          // If the response is directly the page data
          if (data.containsKey('data')) {
            pageData = data['data'] as Map<String, dynamic>;
          } else {
            pageData = data;
          }
        } else {
          throw Exception('Invalid response format');
        }

        // Add the key to the data if it's not present
        if (!pageData.containsKey('key')) {
          pageData['key'] = key;
        }

        _page = SettingPageModel.fromJson(pageData);
        _errorMessage = null;
      } else {
        throw Exception('Failed to load page: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SettingPageProvider: Error fetching page: $e');
      }
      
      // Handle DioError specifically
      if (e is DioException) {
        if (e.response != null) {
          _errorMessage = 'فشل في تحميل الصفحة: ${e.response?.statusCode}';
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.receiveTimeout) {
          _errorMessage = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
        } else if (e.type == DioExceptionType.connectionError) {
          _errorMessage = 'لا يمكن الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت';
        } else {
          _errorMessage = 'حدث خطأ أثناء تحميل الصفحة';
        }
      } else {
        _errorMessage = e.toString().contains('404')
            ? 'الصفحة غير موجودة'
            : 'حدث خطأ أثناء تحميل الصفحة';
      }
      _page = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _page = null;
    notifyListeners();
  }
}

