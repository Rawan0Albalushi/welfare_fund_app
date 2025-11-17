import 'package:dio/dio.dart';

import '../models/app_banner.dart';
import 'api_client.dart';

class BannerService {
  BannerService._internal();
  static final BannerService _instance = BannerService._internal();
  factory BannerService() => _instance;

  final ApiClient _apiClient = ApiClient();

  Future<List<AppBanner>> getActiveBanners() async {
    return _fetchBanners('/banners');
  }

  Future<List<AppBanner>> getFeaturedBanners() async {
    return _fetchBanners('/banners/featured');
  }

  Future<AppBanner?> getBannerById(String bannerId) async {
    if (bannerId.isEmpty) return null;
    try {
      final response = await _apiClient.dio.get('/banners/$bannerId');
      final data = response.data['data'] ?? response.data;
      if (data is Map<String, dynamic>) {
        final banner = AppBanner.fromJson(data);
        return banner.shouldDisplayOnHome ? banner : null;
      }
      return null;
    } on DioException catch (error) {
      print('BannerService: Dio error fetching banner $bannerId: ${error.message}');
      return null;
    } catch (error) {
      print('BannerService: Unexpected error fetching banner $bannerId: $error');
      return null;
    }
  }

  Future<List<AppBanner>> _fetchBanners(String endpoint) async {
    try {
      final response = await _apiClient.dio.get(endpoint);
      final data = response.data;
      final List<dynamic> rawList = _extractList(data);
      final banners = rawList
          .whereType<Map<String, dynamic>>()
          .map(AppBanner.fromJson)
          .where((banner) => banner.shouldDisplayOnHome)
          .toList();
      banners.sort((a, b) => a.priority.compareTo(b.priority));
      return banners;
    } on DioException catch (error) {
      print('BannerService: Dio error fetching $endpoint: ${error.message}');
      return [];
    } catch (error) {
      print('BannerService: Unexpected error fetching $endpoint: $error');
      return [];
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final value = data['data'];
      if (value is List) return value;
      if (value is Map<String, dynamic> && value['data'] is List) {
        return value['data'] as List<dynamic>;
      }
    }
    return [];
  }
}


