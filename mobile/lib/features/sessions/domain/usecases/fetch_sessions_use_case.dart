import '../entities/session.dart';
import '../repositories/sessions_repository.dart';

class FetchSessionsUseCase {
  final SessionsRepository repository;
  FetchSessionsUseCase(this.repository);

  Future<List<Session>> call() async {
    return repository.fetchSessions();
  }
}
