import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// Service for encrypting and decrypting sensitive text fields
class EncryptionService {
  static const String _encryptionKeyName = 'field_encryption_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  enc.Encrypter? _encrypter;
  enc.IV? _iv;

  /// Initialize encryption with stored or new key
  Future<void> initialize() async {
    try {
      // Get or create encryption key
      String? keyString = await _secureStorage.read(key: _encryptionKeyName);

      if (keyString == null) {
        // Generate new key
        final key = enc.Key.fromSecureRandom(32);
        keyString = key.base64;
        await _secureStorage.write(key: _encryptionKeyName, value: keyString);
      }

      final key = enc.Key.fromBase64(keyString);
      _encrypter = enc.Encrypter(enc.AES(key));
      _iv = enc.IV.fromLength(16);

      debugPrint('Encryption service initialized');
    } catch (e) {
      debugPrint('Error initializing encryption: $e');
    }
  }

  /// Check if encryption is enabled (always returns true)
  Future<bool> isEncryptionEnabled() async {
    return true;
  }

  /// Enable encryption (no-op as it's now always enabled)
  Future<void> enableEncryption() async {}

  /// Disable encryption (no-op as it's now always enabled)
  Future<void> disableEncryption() async {}

  /// Encrypt text
  String encrypt(String plainText) {
    if (_encrypter == null) {
      debugPrint('Encryption not initialized, returning plain text');
      return plainText;
    }

    if (plainText.isEmpty) {
      return plainText;
    }

    try {
      // Generate a comprehensive IV for this specific encryption
      final iv = enc.IV.fromLength(16);
      final encrypted = _encrypter!.encrypt(plainText, iv: iv);
      // Prepend IV to ciphertext for storage
      return "${iv.base64}:${encrypted.base64}";
    } catch (e) {
      debugPrint('Error encrypting text: $e');
      return plainText;
    }
  }

  /// Decrypt text
  String decrypt(String encryptedText) {
    if (_encrypter == null) {
      debugPrint('Encryption not initialized, returning encrypted text as-is');
      return encryptedText;
    }

    if (encryptedText.isEmpty) {
      return encryptedText;
    }

    try {
      // Check for IV:Ciphertext format
      if (encryptedText.contains(':')) {
        final parts = encryptedText.split(':');
        if (parts.length == 2) {
          final iv = enc.IV.fromBase64(parts[0]);
          final encrypted = enc.Encrypted.fromBase64(parts[1]);
          return _encrypter!.decrypt(encrypted, iv: iv);
        }
      }

      // Fallback: Try decrypting as legacy (using session IV - unreliable but worth a shot)
      // or assume it's plain text if it fails.
      if (_iv != null) {
        final encrypted = enc.Encrypted.fromBase64(encryptedText);
        return _encrypter!.decrypt(encrypted, iv: _iv!);
      }

      return encryptedText;
    } catch (e) {
      // If decryption fails, text might not be encrypted (plain text)
      // debugPrint('Error decrypting text (might be plain text): $e');
      return encryptedText;
    }
  }

  /// Encrypt text if encryption is enabled, otherwise return plain text
  Future<String> encryptIfEnabled(String plainText) async {
    final enabled = await isEncryptionEnabled();
    if (!enabled) {
      return plainText;
    }
    return encrypt(plainText);
  }

  /// Decrypt text if encryption is enabled, otherwise return as-is
  Future<String> decryptIfEnabled(String text) async {
    final enabled = await isEncryptionEnabled();
    if (!enabled) {
      return text;
    }
    return decrypt(text);
  }

  /// Reset encryption (generate new key)
  Future<void> resetEncryption() async {
    await _secureStorage.delete(key: _encryptionKeyName);
    await initialize();
  }

  /// Check if text appears to be encrypted (base64 format with optional IV prefix)
  bool isEncrypted(String text) {
    if (text.isEmpty) return false;

    if (text.contains(':')) {
      final parts = text.split(':');
      return parts.length == 2;
    }

    try {
      // Try to decode as base64 (Legacy check)
      enc.Encrypted.fromBase64(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Derives an encryption key from a password and salt using SHA-256
  enc.Key _deriveKey(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final hash = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  /// Encrypt any content with a password
  String encryptWithPassword(String content, String password, String salt) {
    final key = _deriveKey(password, salt);
    final encrypter = enc.Encrypter(enc.AES(key));
    final iv = enc.IV.fromLength(16);

    final encrypted = encrypter.encrypt(content, iv: iv);
    // Include IV in the output so it can be used for decryption
    return "${base64.encode(iv.bytes)}:${encrypted.base64}";
  }

  /// Decrypt content with a password
  String decryptWithPassword(
      String encryptedContentWithIv, String password, String salt) {
    try {
      final parts = encryptedContentWithIv.split(':');
      if (parts.length != 2) throw Exception('Invalid encrypted format');

      final iv = enc.IV(base64.decode(parts[0]));
      final encrypted = enc.Encrypted.fromBase64(parts[1]);

      final key = _deriveKey(password, salt);
      final encrypter = enc.Encrypter(enc.AES(key));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('Error decrypting with password: $e');
      rethrow;
    }
  }
}
