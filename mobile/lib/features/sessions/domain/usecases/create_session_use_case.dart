import '../entities/session.dart';
import '../repositories/sessions_repository.dart';

class CreateSessionUseCase {
  final SessionsRepository repository;
  CreateSessionUseCase(this.repository);

  Future<Session> call({
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
    return repository.createSession(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantLocation: restaurantLocation,
      scheduledAt: scheduledAt,
      maxAttendees: maxAttendees,
      foodCategory: foodCategory,
      splitType: splitType,
      splitDetails: splitDetails,
      hasRideAvailable: hasRideAvailable,
      availableRideSeats: availableRideSeats,
      hostTransportMode: hostTransportMode,
    );
  }
}
