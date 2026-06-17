import '../entities/session.dart';
import '../repositories/sessions_repository.dart';

class GetSessionDetailsUseCase {
  final SessionsRepository repository;
  GetSessionDetailsUseCase(this.repository);

  Future<Session> call(String id) async {
    return repository.getSessionDetails(id);
  }
}
