import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:micropack_core/micropack_core.dart';

class MicropackStorage {
  static late FlutterSecureStorage _storage;

  // Create instance dari FlutterSecureStorage
  Future<MicropackStorage> init() async {
    _storage = const FlutterSecureStorage();
    return this;
  }

  static Future<void> write(
      {required String key, required String value}) async {
    await _storage.write(key: key, value: value);
    logSys("Save $key : $value");
  }

  static Future<String?> read({required String key}) async {
    final s = await _storage.read(key: key);
    logSys("Load $key : $s");
    return s;
  }

  static Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  static Future<bool> isContain({required String key}) async {
    final s = await _storage.read(key: key);
    return s != null;
  }

  static Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
