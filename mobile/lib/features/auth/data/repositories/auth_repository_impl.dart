import 'package:baraqah_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:baraqah_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:baraqah_mobile/features/auth/data/models/token_model.dart';
import 'package:baraqah_mobile/features/auth/data/models/user_model.dart';
import '../../domain/entities/token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(
      {required this.remoteDataSource, required this.localDataSource});

  @override
  Future<Token> login(String email, String password) async {
    final tokenModel = await remoteDataSource.login(email, password);
    await localDataSource.cacheToken(tokenModel);
    final profile = await remoteDataSource.fetchProfile();
    await localDataSource.cacheUser(profile);
    return tokenModel;
  }

  @override
  Future<Token> register(
      String name, String email, String password, String phone) async {
    final tokenModel =
        await remoteDataSource.register(name, email, password, phone);
    await localDataSource.cacheToken(tokenModel);
    final profile = await remoteDataSource.fetchProfile();
    await localDataSource.cacheUser(profile);
    return tokenModel;
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearSession();
  }

  @override
  Future<User> profile() async {
    final profile = await remoteDataSource.fetchProfile();
    await localDataSource.cacheUser(profile);
    return profile;
  }

  @override
  Future<User?> getCurrentUser() async {
    return localDataSource.getCachedUser();
  }
}
