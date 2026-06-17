import 'package:hive_flutter/hive_flutter.dart';

class LocalDb {
  static const String userBox = 'userBox';

  Future<void> init() async {
    await Hive.openBox<Map>(userBox);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final box = Hive.box<Map>(userBox);
    await box.put('currentUser', user);
  }

  Map<String, dynamic>? getUser() {
    final box = Hive.box<Map>(userBox);
    final stored = box.get('currentUser');
    return stored?.cast<String, dynamic>();
  }

  Future<void> clearUser() async {
    final box = Hive.box<Map>(userBox);
    await box.delete('currentUser');
  }
}
