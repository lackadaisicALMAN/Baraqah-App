import '../entities/carpool.dart';

abstract class TransportRepository {
  Future<List<Carpool>> fetchCarpools();
  Future<void> pickSeat(String carpoolId, int seatNumber);
}
