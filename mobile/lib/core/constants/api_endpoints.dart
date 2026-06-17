import 'package:flutter/foundation.dart';
import 'env.dart';

class ApiEndpoints {
  static String get baseUrl {
    // Allow explicit override for physical devices or testing.
    if (apiHostOverride.isNotEmpty) {
      final host = apiHostOverride.endsWith('/api')
          ? apiHostOverride
          : '${apiHostOverride.replaceAll(RegExp(r'/+$'), '')}/api';
      return host;
    }
    if (kIsWeb) {
      final origin = Uri.base.origin;
      return '$origin/api';
    }
    return 'http://10.0.2.2:3000/api';
  }

  static String get socketUrl {
    if (apiHostOverride.isNotEmpty) {
      // remove trailing /api if present
      return apiHostOverride.replaceAll(RegExp(r'/api/*$'), '');
    }
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return 'http://10.0.2.2:3000';
  }

  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get profile => '$baseUrl/users/me';
  static String get sessions => '$baseUrl/sessions';
  static String get restaurants => '$baseUrl/restaurants';
  static String get transport => '$baseUrl/transport';
  static String get reviews => '$baseUrl/reviews';
  static String get userReviews => '$baseUrl/reviews/user';
  static String get social => '$baseUrl/social';
  static String get chat => '$baseUrl/chat';
}
