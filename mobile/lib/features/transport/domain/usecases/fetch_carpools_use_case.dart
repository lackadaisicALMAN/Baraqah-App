import '../entities/carpool.dart';
import '../repositories/transport_repository.dart';

class FetchCarpoolsUseCase {
  final TransportRepository repository;
  FetchCarpoolsUseCase(this.repository);

  Future<List<Carpool>> call() async {
    return repository.fetchCarpools();
  }
}
