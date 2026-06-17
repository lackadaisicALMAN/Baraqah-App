import '../entities/token.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<Token> call(
      String name, String email, String password, String phone) async {
    return repository.register(name, email, password, phone);
  }
}
