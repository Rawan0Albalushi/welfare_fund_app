import 'package:flutter/foundation.dart';
import '../models/fund_news.dart';
import 'api_client.dart';

/// Public API (no auth):
/// GET /api/v1/fund-news - list active news
/// GET /api/v1/fund-news/featured - list featured news
/// GET /api/v1/fund-news/{id} - get single news
///
/// Backend (scopeActive): news appears only when:
/// - status == 'active'
/// - published_at is NULL or <= now
/// - deleted_at is NULL (soft deletes)
class FundNewsService {
  final ApiClient _api = ApiClient();

  Future<List<FundNews>> getActiveNews() async {
    final response = await _api.dio.get('/fund-news');
    final list = _parseList(response.data);
    if (kDebugMode) {
      debugPrint('FundNewsService: getActiveNews parsed ${list.length} items');
    }
    return list;
  }

  Future<List<FundNews>> getFeaturedNews() async {
    final response = await _api.dio.get('/fund-news/featured');
    final list = _parseList(response.data);
    if (kDebugMode) {
      debugPrint('FundNewsService: getFeaturedNews parsed ${list.length} items');
    }
    return list;
  }

  Future<FundNews?> getNewsById(int id) async {
    try {
      final response = await _api.dio.get('/fund-news/$id');
      final data = response.data;
      if (data == null) return null;
      final Map<String, dynamic> item = data is Map ? Map<String, dynamic>.from(data) : {};
      final inner = item['data'] ?? item;
      final map = inner is Map ? Map<String, dynamic>.from(inner) : null;
      return map != null ? FundNews.fromJson(map) : null;
    } catch (_) {
      return null;
    }
  }

  List<FundNews> _parseList(dynamic data) {
    if (data == null) return [];
    List<dynamic> raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      final map = data as Map<String, dynamic>;
      // data.data (array) or data.data (paginated object with .data)
      final maybeData = map['data'];
      if (maybeData is List) {
        raw = maybeData;
      } else if (maybeData is Map) {
        final inner = maybeData as Map<String, dynamic>;
        if (inner['data'] is List) {
          raw = inner['data'] as List;
        }
      }
      if (raw.isEmpty && map['fund_news'] is List) raw = map['fund_news'] as List;
      if (raw.isEmpty && map['news'] is List) raw = map['news'] as List;
    }
    final result = <FundNews>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        result.add(FundNews.fromJson(Map<String, dynamic>.from(e)));
      } catch (err) {
        assert(() {
          print('FundNewsService: skip item parse error: $err');
          return true;
        }());
      }
    }
    return result;
  }
}
