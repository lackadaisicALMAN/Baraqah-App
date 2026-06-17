import '../repositories/transport_repository.dart';

class PickSeatUseCase {
  final TransportRepository repository;
  PickSeatUseCase(this.repository);

  Future<void> call(String carpoolId, int seatNumber) async {
    await repository.pickSeat(carpoolId, seatNumber);
  }
}
