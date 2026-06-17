import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'local_db.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;
  SecureStorage() : _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final box = Hive.box<Map>(LocalDb.userBox);
      await box.put('accessToken', {'value': token});
      return;
    }
    await _storage.write(key: 'accessToken', value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      final box = Hive.box<Map>(LocalDb.userBox);
      await box.put('refreshToken', {'value': token});
      return;
    }
    await _storage.write(key: 'refreshToken', value: token);
  }

  Future<String?> readToken() async {
    if (kIsWeb) {
      final box = Hive.box<Map>(LocalDb.userBox);
      final data = box.get('accessToken');
      return data?['value']?.toString();
    }
    try {
      return await _storage.read(key: 'accessToken');
    } catch (_) {
      return null;
    }
  }

  Future<String?> readRefreshToken() async {
    if (kIsWeb) {
      final box = Hive.box<Map>(LocalDb.userBox);
      final data = box.get('refreshToken');
      return data?['value']?.toString();
    }
    try {
      return await _storage.read(key: 'refreshToken');
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final box = Hive.box<Map>(LocalDb.userBox);
      await box.delete('accessToken');
      await box.delete('refreshToken');
      return;
    }
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }
}
