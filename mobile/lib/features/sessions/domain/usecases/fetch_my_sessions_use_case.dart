import '../entities/session.dart';
import '../repositories/sessions_repository.dart';

class FetchMySessionsUseCase {
  final SessionsRepository repository;
  FetchMySessionsUseCase(this.repository);

  Future<List<Session>> call() async {
    return await repository.getMySessions();
  }
}
