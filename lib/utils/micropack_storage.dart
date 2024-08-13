import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MicropackStorage {
  // create instance dari FlutterSecureStorage
  static const _storage = FlutterSecureStorage();

  static Future<void> write(
      {required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> read({required String key}) async {
    final s = await _storage.read(key: key);
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
