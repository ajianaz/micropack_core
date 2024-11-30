// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'dart:developer' as d;

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:micropack_core/micropack_core.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

logSys(String s) {
  if (kDebugMode) {
    d.log(s);
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

  static convertToFile(XFile? xFile) {
    if (xFile != null) {
      var filePhoto = File(xFile.path);
      return filePhoto;
    }
  }

  static Future<File> compressFile(File file, {int quality = 80}) async {
    final filePath = file.absolute.path;
    // Create output file path
    // eg:- "Volume/VM/abcd_out.jpeg"
    final lastIndex = filePath.lastIndexOf(new RegExp(r'.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: quality,
    );
    File resultFile = convertToFile(result);
    logSys("Before Compress : ${file.size}");
    logSys("After Compress : ${resultFile.size}");
    return resultFile;
  }
}
