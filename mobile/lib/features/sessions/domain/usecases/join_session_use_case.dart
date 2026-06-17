import '../repositories/sessions_repository.dart';

class JoinSessionUseCase {
  final SessionsRepository repository;
  JoinSessionUseCase(this.repository);

  Future<void> call(String id) async {
    await repository.joinSession(id);
  }
}
