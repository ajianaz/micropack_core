import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:developer' as d;

import 'package:crypto/crypto.dart';

logSys(String s) {
  if (kDebugMode) {
    d.log(s);
  }
}

class MicropackUtils {
  //Encyption for header needed
  static String encryptHMAC(int unixTime, String apiKey) {
    final currentDate = DateTime.now().toIso8601String().substring(0, 10);
    final combinedString = apiKey + currentDate;

    final keyBytes = utf8.encode(combinedString); // convert key to bytes
    final plainBytes =
        utf8.encode(unixTime.toString()); // convert unixtime to bytes

    final hmacSha256 = Hmac(
        sha256, keyBytes); // Preparing encyption HMAC-SHA256 using previous key
    final digest = hmacSha256.convert(plainBytes); // Encrypt data

    final cipherHexString =
        digest.toString(); // convert encrypted data to string

    return cipherHexString;
  }
}
