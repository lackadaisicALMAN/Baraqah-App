import '../datasources/transport_remote_data_source.dart';
import '../../domain/entities/carpool.dart';
import '../../domain/repositories/transport_repository.dart';

class TransportRepositoryImpl implements TransportRepository {
  final TransportRemoteDataSource remoteDataSource;

  TransportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Carpool>> fetchCarpools() async {
    return remoteDataSource.fetchCarpools();
  }

  @override
  Future<void> pickSeat(String carpoolId, int seatNumber) async {
    await remoteDataSource.pickSeat(carpoolId, seatNumber);
  }
}
