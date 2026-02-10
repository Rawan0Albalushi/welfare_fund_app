import 'package:flutter/foundation.dart';
import '../models/fund_partner.dart';
import 'api_client.dart';

/// Public API (no auth):
/// GET /api/v1/fund-partners - list active partners (?featured=1 & ?limit=20)
/// GET /api/v1/fund-partners/featured - featured only
/// GET /api/v1/fund-partners/{id} - single partner
class FundPartnerService {
  final ApiClient _api = ApiClient();

  Future<List<FundPartner>> getActivePartners({bool? featured, int? limit}) async {
    final query = <String, dynamic>{};
    if (featured == true) query['featured'] = '1';
    if (limit != null) query['limit'] = limit.toString();
    final response = await _api.dio.get(
      '/fund-partners',
      queryParameters: query.isEmpty ? null : query,
    );
    final list = _parseList(response.data);
    if (kDebugMode) {
      debugPrint('FundPartnerService: getActivePartners parsed ${list.length} items');
    }
    return list;
  }

  Future<List<FundPartner>> getFeaturedPartners() async {
    final response = await _api.dio.get('/fund-partners/featured');
    final list = _parseList(response.data);
    if (kDebugMode) {
      debugPrint('FundPartnerService: getFeaturedPartners parsed ${list.length} items');
    }
    return list;
  }

  Future<FundPartner?> getPartnerById(int id) async {
    try {
      final response = await _api.dio.get('/fund-partners/$id');
      final data = response.data;
      if (data == null) return null;
      final Map<String, dynamic> item = data is Map ? Map<String, dynamic>.from(data) : {};
      final inner = item['data'] ?? item;
      final map = inner is Map ? Map<String, dynamic>.from(inner) : null;
      return map != null ? FundPartner.fromJson(map) : null;
    } catch (_) {
      return null;
    }
  }

  List<FundPartner> _parseList(dynamic data) {
    if (data == null) return [];
    List<dynamic> raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      final map = data as Map<String, dynamic>;
      final maybeData = map['data'];
      if (maybeData is List) {
        raw = maybeData;
      } else if (maybeData is Map) {
        final inner = maybeData as Map<String, dynamic>;
        if (inner['data'] is List) raw = inner['data'] as List;
      }
      if (raw.isEmpty && map['fund_partners'] is List) raw = map['fund_partners'] as List;
      if (raw.isEmpty && map['partners'] is List) raw = map['partners'] as List;
    }
    final result = <FundPartner>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        final map = Map<String, dynamic>.from(e);
        final partner = FundPartner.fromJson(map);
        result.add(partner);
        if (kDebugMode) {
          debugPrint('FundPartnerService: partner id=${partner.id} name_ar=${partner.nameAr} logo=${map["logo"]} logo_url=${map["logo_url"]}');
        }
      } catch (err) {
        assert(() {
          debugPrint('FundPartnerService: skip item parse error: $err');
          return true;
        }());
      }
    }
    return result;
  }
}
