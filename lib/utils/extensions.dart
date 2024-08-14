// ignore_for_file: unnecessary_this

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

extension FileUtils on File {
  get size {
    int bytes = this.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return "${((bytes / pow(1024, i)).toStringAsFixed(3))} ${suffixes[i]}";
  }
}

extension ColorExtension on String {
  toColor() {
    var hexStringColor = this;
    final buffer = StringBuffer();

    if (hexStringColor.length == 6 || hexStringColor.length == 7) {
      buffer.write('ff');
      buffer.write(hexStringColor.replaceFirst("#", ""));
      return Color(int.parse(buffer.toString(), radix: 16));
    }
  }
}
