import '../entities/token.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<Token> call(String email, String password) async {
    return repository.login(email, password);
  }
}
