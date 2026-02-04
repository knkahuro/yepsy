import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling biometric authentication (Face ID, Fingerprint, etc.)
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _pinKey = 'app_pin';

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access Yepsy',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  /// Check if biometric lock is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Enable biometric lock
  Future<void> enableBiometric() async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
  }

  /// Disable biometric lock
  Future<void> disableBiometric() async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
  }

  /// Set PIN as fallback
  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    return storedPin == pin;
  }

  /// Check if PIN is set
  Future<bool> isPinSet() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Remove PIN
  Future<void> removePin() async {
    await _secureStorage.delete(key: _pinKey);
  }

  /// Get biometric type name for display
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }

  /// Full authentication (tries biometric first, falls back to PIN)
  Future<bool> authenticate() async {
    // Try biometric first if enabled
    final biometricEnabled = await isBiometricEnabled();
    if (biometricEnabled) {
      final biometricResult = await authenticateWithBiometrics();
      if (biometricResult) {
        return true;
      }
    }

    // If biometric fails or not enabled, PIN is required
    return false; // PIN verification happens in UI
  }
}
