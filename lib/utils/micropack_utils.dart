import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:developer' as d;

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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

  static Future<bool> checkTokenValidity(String token) async {
    try {
      final exp = JwtDecoder.getExpirationDate(token);
      final currentTime = DateTime.now();

      // Log current time and expiration time
      final formattedCurrentTime =
          DateFormat('dd MMM yyyy HH:mm').format(currentTime);
      final formattedExpirationDate =
          DateFormat('dd MMM yyyy HH:mm').format(exp);

      logSys('Current time: $formattedCurrentTime');
      logSys('Token expires at: $formattedExpirationDate');
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      logSys(e.toString());
      return false;
    }
  }

  static String formatDateTime(
      {required DateTime value, String? format, String? locale}) {
    format ??= 'yyyy-MM-dd';
    locale ??= 'en';
    try {
      return DateFormat(format, locale).format(value);
    } catch (e) {
      return 'Invalid date';
    }
  }

  static bool isValidTimeRange(String startTime, String endTime) {
    // Parse string ke objek DateTime
    DateTime start = DateFormat("yyyy-MM-dd HH:mm:ss").parse(startTime);
    DateTime end = DateFormat("yyyy-MM-dd HH:mm:ss").parse(endTime);

    // Bandingkan waktu
    if (start.isAfter(end) || start.isAtSameMomentAs(end)) {
      return false; // Jika waktu mulai melebihi atau sama dengan waktu selesai
    } else {
      return true; // Jika waktu mulai tidak melebihi waktu selesai
    }
  }
}
