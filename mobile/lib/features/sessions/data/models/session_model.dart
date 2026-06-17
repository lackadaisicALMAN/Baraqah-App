import '../../domain/entities/session.dart';

class SessionModel extends Session {
  const SessionModel({
    required String id,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required DateTime startTime,
    required String host,
    required int availableSeats,
    required int capacity,
    bool joined = false,
    String status = 'OPEN',
    String? restaurantId,
    String restaurantLocation = '',
    List<SessionAttendee> attendees = const [],
  }) : super(
          id: id,
          title: title,
          description: description,
          latitude: latitude,
          longitude: longitude,
          startTime: startTime,
          host: host,
          availableSeats: availableSeats,
          capacity: capacity,
          joined: joined,
          status: status,
          restaurantId: restaurantId,
          restaurantLocation: restaurantLocation,
          attendees: attendees,
        );

  factory SessionModel.fromJson(Map<String, dynamic> json) {
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

    // The backend wraps details in { session: {...}, attendees: [...] }
    final sessionMap = json.containsKey('session')
        ? Map<String, dynamic>.from(json['session'] as Map)
        : json;

    final List<dynamic> attendeesJson = json.containsKey('attendees')
        ? json['attendees'] as List<dynamic>
        : [];
    final List<SessionAttendee> attendeesList = attendeesJson.map((a) {
      final map = Map<String, dynamic>.from(a as Map);
      return SessionAttendee(
        userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
        name: map['full_name']?.toString() ??
            map['display_name']?.toString() ??
            'User',
        baraqahScore: parseDouble(map['baraqah_score'], 5.0),
        isHost: map['is_host'] == true,
        transportMode:
            map['transport_mode']?.toString() ?? 'MEET_THERE',
      );
    }).toList();

    final maxAttendees = parseInt(sessionMap['max_attendees'] ?? sessionMap['capacity'], 4);
    final currentAttendees = parseInt(sessionMap['current_attendees'], 1);

    // Compute available seats properly
    final availableSeats = (maxAttendees - currentAttendees).clamp(0, maxAttendees);

    // Prefer restaurant_name for display title
    final title = sessionMap['restaurant_name']?.toString() ??
        sessionMap['title']?.toString() ??
        'Dining Plan';

    // Build location label
    final restaurantLocation =
        sessionMap['restaurant_address']?.toString() ??
        sessionMap['meeting_note']?.toString() ??
        '';

    return SessionModel(
      id: sessionMap['id']?.toString() ??
          sessionMap['_id']?.toString() ?? '',
      title: title,
      description: sessionMap['description']?.toString() ?? '',
      latitude: parseDouble(sessionMap['meeting_lat'] ?? sessionMap['latitude'], 0.0),
      longitude: parseDouble(sessionMap['meeting_lng'] ?? sessionMap['longitude'], 0.0),
      startTime: DateTime.parse(
          sessionMap['scheduled_at']?.toString() ??
              sessionMap['startTime']?.toString() ??
              DateTime.now().toIso8601String()),
      host: sessionMap['host_display_name']?.toString() ??
          sessionMap['host']?.toString() ?? 'Host',
      availableSeats: availableSeats,
      capacity: maxAttendees,
      joined: json['joined'] == true || sessionMap['joined'] == true,
      status: sessionMap['status']?.toString() ?? 'OPEN',
      restaurantId: sessionMap['restaurant_id']?.toString(),
      restaurantLocation: restaurantLocation,
      attendees: attendeesList,
    );
  }
}
