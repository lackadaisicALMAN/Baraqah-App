import '../entities/token.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Token> login(String email, String password);
  Future<Token> register(
      String name, String email, String password, String phone);
  Future<User> profile();
  Future<void> logout();
  Future<User?> getCurrentUser();
}
