import '../datasources/sessions_remote_data_source.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/sessions_repository.dart';

class SessionsRepositoryImpl implements SessionsRepository {
  final SessionsRemoteDataSource remoteDataSource;

  SessionsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Session>> fetchSessions() async {
    return remoteDataSource.fetchSessions();
  }

  @override
  Future<Session> createSession({
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
    return remoteDataSource.createSession(
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

  @override
  Future<void> joinSession(String id) async {
    await remoteDataSource.joinSession(id);
  }

  @override
  Future<Session> getSessionDetails(String id) async {
    return remoteDataSource.getSessionDetails(id);
  }

  @override
  Future<List<Session>> getMySessions() async {
    return await remoteDataSource.fetchMySessions();
  }
}
