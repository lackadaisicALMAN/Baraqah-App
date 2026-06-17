import 'package:baraqah_mobile/features/auth/data/models/token_model.dart';
import 'package:baraqah_mobile/features/auth/data/models/user_model.dart';
import '../../../../core/storage/local_db.dart';
import '../../../../core/storage/secure_storage.dart';

class AuthLocalDataSource {
  final SecureStorage secureStorage;
  final LocalDb localDb;

  AuthLocalDataSource({required this.secureStorage, required this.localDb});

  Future<void> cacheToken(TokenModel token) async {
    await secureStorage.saveToken(token.accessToken);
    await secureStorage.saveRefreshToken(token.refreshToken);
  }

  Future<void> cacheUser(UserModel user) async {
    await localDb.saveUser(user.toJson());
  }

  UserModel? getCachedUser() {
    final stored = localDb.getUser();
    if (stored == null) {
      return null;
    }
    return UserModel.fromJson(stored);
  }

  Future<void> clearSession() async {
    await secureStorage.clear();
    await localDb.clearUser();
  }
}
