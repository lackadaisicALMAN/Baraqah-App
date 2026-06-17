import 'package:baraqah_mobile/core/constants/api_endpoints.dart';
import 'package:baraqah_mobile/core/network/api_client.dart';
import '../models/session_model.dart';

class RestaurantOption {
  final String id;
  final String name;
  final String address;
  final String city;
  final List<dynamic> cuisineTags;
  final double avgRating;
  final int reviewCount;
  final double lat;
  final double lng;

  RestaurantOption({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.cuisineTags,
    required this.avgRating,
    required this.reviewCount,
    required this.lat,
    required this.lng,
  });

  String get locationLabel => address;

  factory RestaurantOption.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v, double def) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? def;
      return def;
    }
    int parseInt(dynamic v, int def) {
      if (v == null) return def;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    return RestaurantOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      cuisineTags: (json['cuisine_tags'] as List<dynamic>?) ?? [],
      avgRating: parseDouble(json['avg_rating'], 0.0),
      reviewCount: parseInt(json['verified_review_count'], 0),
      lat: parseDouble(json['lat'], 0.0),
      lng: parseDouble(json['lng'], 0.0),
    );
  }
}

class SessionsRemoteDataSource {
  final ApiClient apiClient;
  SessionsRemoteDataSource({required this.apiClient});

  Future<List<SessionModel>> fetchSessions() async {
    final response = await apiClient.get('${ApiEndpoints.sessions}/browse');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => SessionModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<SessionModel>> fetchMySessions() async {
    final response = await apiClient.get('${ApiEndpoints.sessions}/mine');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => SessionModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<RestaurantOption>> fetchRestaurants() async {
    final response = await apiClient.get(ApiEndpoints.restaurants);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => RestaurantOption.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<SessionModel> createSession({
    required String restaurantId,
    required String restaurantName,
    required String restaurantLocation,
    required DateTime scheduledAt,
    required int maxAttendees,
    required String foodCategory,
    required String splitType,
    List<dynamic> splitDetails = const [],
    required bool hasRideAvailable,
    int availableRideSeats = 0,
    required String hostTransportMode,
  }) async {
    final response = await apiClient.post(ApiEndpoints.sessions, data: {
      'restaurant_id': restaurantId,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'max_attendees': maxAttendees,
      'food_category': foodCategory,
      'split_type': splitType,
      'split_details': splitDetails,
      'has_ride_available': hasRideAvailable,
      'available_ride_seats': availableRideSeats,
      'host_transport_mode': hostTransportMode,
    });
    return SessionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> joinSession(String id) async {
    await apiClient.post('${ApiEndpoints.sessions}/$id/join', data: {
      'transport_mode': 'MEET_THERE',
    });
  }

  Future<SessionModel> getSessionDetails(String id) async {
    final response = await apiClient.get('${ApiEndpoints.sessions}/$id');
    return SessionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
