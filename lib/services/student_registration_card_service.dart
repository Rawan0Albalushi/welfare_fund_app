import '../constants/app_config.dart';
import '../models/student_registration_card.dart';
import 'api_client.dart';

class StudentRegistrationCardService {
  final ApiClient _apiClient = ApiClient();

  Future<StudentRegistrationCardData?> fetchCardData() async {
    try {
      final response = await _apiClient.dio.get('/student-registration-card');
      final rawData = response.data;
      if (rawData == null) {
        return null;
      }

      final Map<String, dynamic>? dataSection = _extractDataSection(rawData);
      if (dataSection == null) {
        return null;
      }

      final StudentRegistrationCardData cardData =
          StudentRegistrationCardData.fromMap(dataSection);
      final String? resolvedImageUrl = _resolveBackgroundImageUrl(dataSection);

      if (resolvedImageUrl != null) {
        return cardData.copyWith(backgroundImageUrl: resolvedImageUrl);
      }

      return cardData;
    } catch (error) {
      rethrow;
    }
  }

  Map<String, dynamic>? _extractDataSection(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      if (payload['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(payload['data'] as Map);
      }
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }

  String? _resolveBackgroundImageUrl(Map<String, dynamic> section) {
    final directUrl = _toNullableString(section['background_image_url']);
    if (directUrl != null) {
      return directUrl;
    }

    final path = _toNullableString(section['background_image']);
    if (path == null) {
      return null;
    }

    final normalizedPath = path.replaceAll('\\', '/').trim();
    if (normalizedPath.isEmpty) return null;

    if (normalizedPath.startsWith('http')) {
      return normalizedPath;
    }

    final cleaned = normalizedPath.startsWith('/') ? normalizedPath.substring(1) : normalizedPath;
    return '${AppConfig.serverBaseUrl}/storage/$cleaned';
  }

  static String? _toNullableString(Object? value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }
}

