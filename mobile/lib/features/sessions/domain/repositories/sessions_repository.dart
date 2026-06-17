import '../entities/session.dart';

abstract class SessionsRepository {
  Future<List<Session>> fetchSessions();

  Future<Session> createSession({
    required String restaurantId,
    required String restaurantName,
    required String restaurantLocation,
    required DateTime scheduledAt,
    required int maxAttendees,
    required String foodCategory,
    required String splitType,
    List<dynamic> splitDetails,
    required bool hasRideAvailable,
    int availableRideSeats,
    required String hostTransportMode,
  });

  Future<void> joinSession(String id);
  Future<Session> getSessionDetails(String id);
  Future<List<Session>> getMySessions();
}
