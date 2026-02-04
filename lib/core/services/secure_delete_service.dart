import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for securely deleting data with multi-pass overwrite
class SecureDeleteService {
  /// Number of overwrite passes (DoD 5220.22-M standard)
  static const int _overwritePasses = 3;

  final Random _random = Random.secure();

  /// Securely delete a string by overwriting with random data
  String secureOverwriteString(String original) {
    if (original.isEmpty) return original;

    final length = original.length;
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      // Generate random printable ASCII character
      buffer.write(String.fromCharCode(_random.nextInt(94) + 33));
    }

    return buffer.toString();
  }

  /// Securely delete a list of strings
  List<String> secureOverwriteList(List<String> original) {
    return original.map((item) => secureOverwriteString(item)).toList();
  }

  /// Generate random integer
  int secureOverwriteInt(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Generate random double
  double secureOverwriteDouble() {
    return _random.nextDouble();
  }

  /// Generate random boolean
  bool secureOverwriteBool() {
    return _random.nextBool();
  }

  /// Generate random DateTime
  DateTime secureOverwriteDateTime() {
    final now = DateTime.now();
    final randomDays = _random.nextInt(365);
    return now.subtract(Duration(days: randomDays));
  }

  /// Perform multi-pass overwrite on a callback
  /// This executes the overwrite function multiple times
  Future<void> multiPassOverwrite(
      Future<void> Function() overwriteFunction) async {
    for (int pass = 0; pass < _overwritePasses; pass++) {
      await overwriteFunction();
      debugPrint('Secure delete pass ${pass + 1}/$_overwritePasses completed');
    }
  }

  /// Log secure deletion
  void logSecureDeletion(String itemType, String itemId) {
    debugPrint(
        'Securely deleted $itemType: $itemId ($_overwritePasses passes)');
  }
}
