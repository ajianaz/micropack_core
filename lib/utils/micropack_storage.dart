import 'package:flutter/services.dart';
import '../micropack_core.dart';

class MicropackStorage {
  static final MicropackStorage _instance = MicropackStorage._internal();
  factory MicropackStorage() => _instance;

  static late FlutterSecureStorage _storage;
  static Map<String, String>? _cache; // Cache untuk mempercepat pembacaan

  MicropackStorage._internal();

  Future<MicropackStorage> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: true,
        encryptedSharedPreferences: true,
      ),
    );

    _cache ??=
        await _storage.readAll(); // Load semua data ke cache saat startup
    logSys("MicropackStorage initialized with cache: $_cache");
    return this;
  }

  static Future<void> write(
      {required String key, required String value}) async {
    _cache?[key] = value; // Update cache
    await _storage.write(key: key, value: value);
    logSys("Save $key : $value");
  }

  static Future<String?> read({required String key}) async {
    try {
      // Cek cache dulu, kalau ada langsung return
      if (_cache?.containsKey(key) == true) {
        logSys("Load from cache $key : ${_cache?[key]}");
        return _cache?[key];
      }

      // Kalau tidak ada di cache, baca dari Secure Storage
      final s = await _storage.read(key: key);
      logSys("Load $key : $s");

      if (s != null) {
        _cache?[key] = s; // Simpan ke cache agar lebih cepat diakses nanti
      }

      return s;
    } on PlatformException catch (e) {
      logSys("Error reading key $key: ${e.message}");

      // Workaround untuk kasus token error
      if (key == "token") {
        await _storage.deleteAll();
        _cache?.clear(); // Hapus cache juga
        logSys("All secure storage data deleted due to token key error.");
      }

      return null;
    } catch (e) {
      logSys("Unexpected error while reading key $key: $e");
      return null;
    }
  }

  static Future<void> delete({required String key}) async {
    _cache?.remove(key); // Hapus dari cache juga
    await _storage.delete(key: key);
  }

  static Future<bool> isContain({required String key}) async {
    return _cache?.containsKey(key) ?? await _storage.containsKey(key: key);
  }

  static Future<Map<String, String>> readAll() async {
    return _cache ??= await _storage.readAll();
  }

  static Future<void> deleteAll() async {
    _cache?.clear(); // Bersihkan cache
    await _storage.deleteAll();
  }
}
