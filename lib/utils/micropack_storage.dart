import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:io'; // Untuk cek platform Desktop
import '../micropack_core.dart';

class MicropackStorage {
  static final MicropackStorage _instance = MicropackStorage._internal();
  factory MicropackStorage() => _instance;

  static FlutterSecureStorage? _secureStorage;
  static SharedPreferences? _prefs;
  static Map<String, String>? _cache; // Cache untuk mempercepat pembacaan

  MicropackStorage._internal();

  Future<MicropackStorage> init() async {
    if (kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // Desktop & Web pakai SharedPreferences
      _prefs = await SharedPreferences.getInstance();
    } else {
      // Mobile pakai FlutterSecureStorage
      _secureStorage = FlutterSecureStorage(
        aOptions: const AndroidOptions(
          resetOnError: true,
          encryptedSharedPreferences: true,
        ),
        iOptions: const IOSOptions(),
        webOptions: kIsWeb
            ? const WebOptions(
                dbName: "micropack_secure_storage",
                publicKey: "micropack_key",
              )
            : WebOptions.defaultOptions,
      );
    }

    try {
      _cache =
          kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS
              ? {} // Cache kosong untuk desktop/web
              : await _secureStorage?.readAll(); // Load cache untuk mobile

      logSys("MicropackStorage initialized with cache: $_cache");
    } catch (e) {
      logSys("Error initializing storage: $e");
      _cache = {}; // Gunakan cache kosong jika ada error
    }

    return this;
  }

  static Future<void> write(
      {required String key, required String value}) async {
    _cache?[key] = value; // Update cache

    try {
      if (kIsWeb ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isMacOS) {
        // Desktop & Web pakai SharedPreferences
        await _prefs?.setString(key, value);
      } else {
        // Mobile pakai FlutterSecureStorage
        await _secureStorage?.write(key: key, value: value);
      }
      logSys("Save $key : $value");
    } catch (e) {
      logSys("Error saving key $key: $e");
    }
  }

  static Future<String?> read({required String key}) async {
    try {
      if (_cache?.containsKey(key) == true) {
        logSys("Load from cache $key : ${_cache?[key]}");
        return _cache?[key];
      }

      String? value;
      if (kIsWeb ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isMacOS) {
        // Desktop & Web pakai SharedPreferences
        value = _prefs?.getString(key);
      } else {
        // Mobile pakai FlutterSecureStorage
        value = await _secureStorage?.read(key: key);
      }

      logSys("Load $key : $value");

      if (value != null) {
        _cache?[key] = value;
      }

      return value;
    } on PlatformException catch (e) {
      logSys("Error reading key $key: ${e.message}");
      return null;
    } catch (e) {
      logSys("Unexpected error while reading key $key: $e");
      return null;
    }
  }

  static Future<void> delete({required String key}) async {
    _cache?.remove(key);

    try {
      if (kIsWeb ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isMacOS) {
        await _prefs?.remove(key);
      } else {
        await _secureStorage?.delete(key: key);
      }
      logSys("Deleted key: $key");
    } catch (e) {
      logSys("Error deleting key $key: $e");
    }
  }

  static Future<bool> isContain({required String key}) async {
    return _cache?.containsKey(key) ??
        (kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS
            ? _prefs?.containsKey(key) ?? false
            : await _secureStorage?.containsKey(key: key) ?? false);
  }

  static Future<void> deleteAll() async {
    _cache?.clear();

    try {
      if (kIsWeb ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isMacOS) {
        await _prefs?.clear();
      } else {
        await _secureStorage?.deleteAll();
      }
      logSys("All storage data deleted.");
    } catch (e) {
      logSys("Error deleting all data: $e");
    }
  }
}
