// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io' show File; // Import hanya untuk platform non-web
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:developer' as d;

import 'package:crypto/crypto.dart';
import 'package:micropack_core/micropack_core.dart';
import 'package:flutter/material.dart';

// for log system with option enable/disable
logSys(String s) {
  if (MicropackInit.logEnabled && kDebugMode) {
    d.log(s);
  }
}

void closeKeyboard(BuildContext context) {
  FocusScopeNode currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
    currentFocus.unfocus();
  }
}

class MicropackUtils {
  static String getEnvironmentLabel() {
    if (MicropackInit.appFlavor == Flavor.development)
      return "Development Environment";
    if (MicropackInit.appFlavor == Flavor.staging) return "Staging Environment";
    if (MicropackInit.appFlavor == Flavor.production)
      return "Production Environment";
    return "Please, set Env";
  }

  //Encyption for header needed
  static Future<String> encryptHMAC(int unixTime, String apiKey) async {
    var currentDate = getPartUnixTime(unixTime);
    var combinedString = apiKey + currentDate;
    logSys("PartUnixTime $currentDate");

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

  static String getPartUnixTime(int number, {int digit = 8}) {
    return number.toString().substring(0, digit);
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

  static dynamic convertToFile(XFile? xFile) {
    if (xFile == null) return null;

    if (kIsWeb) {
      return xFile; // Kembalikan XFile untuk web (tidak bisa dikonversi ke File)
    } else {
      return File(xFile.path); // Konversi ke File untuk mobile/desktop
    }
  }

  static Future<dynamic> compressFile(dynamic file, {int quality = 80}) async {
    if (file == null) return null;

    if (kIsWeb) {
      // Web menggunakan fetch API untuk mendapatkan data blob
      final XFile xFile = file as XFile;
      final response = await http.get(Uri.parse(xFile.path));
      Uint8List uint8List = response.bodyBytes;

      // Tidak ada cara langsung untuk kompresi di web, jadi kita hanya return data asli
      return uint8List;
    } else {
      // Mobile & Desktop menggunakan FlutterImageCompress
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final outPath =
          "${filePath.substring(0, lastIndex)}_compressed${filePath.substring(lastIndex)}";

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: quality,
      );

      return result != null
          ? File(result.path)
          : file; // Jika gagal, return file asli
    }
  }
}
