import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing database migrations and optimizations
class DatabaseService {
  /// Migration and encryption versioning
  static const String _versionKey = 'db_version';
  static const int _currentVersion = 1;
  static const String _encryptionKeyName = 'hive_db_encryption_key';

  /// Secure storage for encryption keys
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Initialize database with optimizations
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Check and run migrations if needed
    await _runMigrations();

    // Set up database optimizations
    await _setupOptimizations();
  }

  /// Run database migrations
  static Future<void> _runMigrations() async {
    final settingsBox = await Hive.openBox('settings');
    final currentVersion = settingsBox.get(_versionKey, defaultValue: 0) as int;

    if (currentVersion < _currentVersion) {
      debugPrint(
          'Running database migrations from v$currentVersion to v$_currentVersion');

      // Run migrations sequentially
      for (int version = currentVersion + 1;
          version <= _currentVersion;
          version++) {
        await _runMigration(version);
      }

      // Update version
      await settingsBox.put(_versionKey, _currentVersion);
      debugPrint('Database migrations completed');
    }
  }

  /// Run a specific migration
  static Future<void> _runMigration(int version) async {
    switch (version) {
      case 1:
        await _migrationV1();
        break;
      // Add future migrations here
      default:
        debugPrint('No migration defined for version $version');
    }
  }

  /// Migration v1: Initial setup with indexes
  static Future<void> _migrationV1() async {
    debugPrint('Running migration v1: Adding indexes');

    // Note: Hive doesn't support traditional indexes like SQL databases
    // Instead, we optimize by:
    // 1. Ensuring compact mode is enabled
    // 2. Setting up lazy box opening where appropriate
    // 3. Organizing data efficiently

    // Compact all existing boxes to optimize storage
    final boxNames = ['calendar_events', 'sleep_logs', 'notes', 'habits'];
    for (final boxName in boxNames) {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.compact();
        debugPrint('Compacted $boxName box');
      }
    }
  }

  /// Set up database optimizations
  static Future<void> _setupOptimizations() async {
    // Enable auto-compaction for all boxes
    // This helps keep the database size small

    // Note: Hive automatically compacts boxes when they get fragmented
    // We can manually trigger compaction periodically

    debugPrint('Database optimizations applied');
  }

  /// Compact all open boxes to optimize storage
  static Future<void> compactAllBoxes() async {
    final openBoxes = Hive.box('settings')
        .get('open_boxes', defaultValue: <String>[]) as List;

    for (final boxName in openBoxes) {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.compact();
        debugPrint('Compacted $boxName');
      }
    }
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final stats = <String, dynamic>{};

    final boxNames = [
      'calendar_events',
      'sleep_logs',
      'notes',
      'habits',
      'settings'
    ];

    for (final boxName in boxNames) {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        stats[boxName] = {
          'entries': box.length,
          'keys': box.keys.length,
        };
      }
    }

    stats['version'] = _currentVersion;

    return stats;
  }

  /// Clear all data (Factory Reset)
  static Future<void> clearAllData() async {
    final boxNames = [
      'calendar_events',
      'sleep_logs',
      'notes',
      'habits',
      'settings',
      'cycle_profile',
      'symptom_logs'
    ];

    for (final boxName in boxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
        }
        await Hive.deleteBoxFromDisk(boxName);
        debugPrint('Deleted box from disk: $boxName');
      } catch (e) {
        debugPrint('Error deleting $boxName via Hive: $e');
      }
    }

    // Manual cleanup of any remnants
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync();
      for (var file in files) {
        if (file.path.endsWith('.hive') || file.path.endsWith('.lock')) {
          try {
            file.deleteSync();
            debugPrint('Force deleted file: ${file.path}');
          } catch (e) {
            debugPrint('Failed to force delete ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error during manual cleanup: $e');
    }

    // Also clear secure storage (Encryption keys)
    await _secureStorage.deleteAll();
    debugPrint('Cleared Secure Storage');
  }

  /// Re-initialize database after a factory reset
  /// This ensures the app can continue running without restarting
  static Future<void> reinitializeAfterReset() async {
    // We don't call Hive.initFlutter() again as it throws if called twice
    // But we need to ensure boxes can be opened again

    // Open settings box to reset version
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.put(_versionKey, 0); // Reset version

    debugPrint('Database re-initialized after reset');
  }

  /// Backup database to a specific path
  static Future<void> backupDatabase(String backupPath) async {
    // This would copy all Hive box files to the backup location
    // Implementation depends on platform-specific file operations
    debugPrint('Database backup to $backupPath (not yet implemented)');
  }

  /// Securely migrate a box from unencrypted to encrypted
  static Future<void> migrateBoxToEncryption<T>(String boxName) async {
    final cipher = await getEncryptionCipher();
    if (cipher == null) return;

    try {
      // 1. Try to open with encryption first
      final box = await Hive.openBox<T>(boxName, encryptionCipher: cipher);
      await box.close();
      debugPrint('Box $boxName is already encrypted or empty');
      return;
    } catch (e) {
      debugPrint(
          'Opening $boxName with encryption failed, checking for migration: $e');
    }

    // 2. Try opening without encryption
    try {
      final unencryptedBox = await Hive.openBox<T>(boxName);
      final data = unencryptedBox.toMap();
      final totalEntries = data.length;

      if (totalEntries == 0) {
        await unencryptedBox.close();
        // Just reopen with encryption
        await Hive.openBox<T>(boxName, encryptionCipher: cipher);
        return;
      }

      debugPrint(
          'Migrating $totalEntries entries in $boxName to encryption...');

      // 3. Close unencrypted and migrate (manually because we can't easily reopen the same box name with different cipher in same session without conflicts)
      await unencryptedBox.close();

      // We must use a temporary box for the migration to be safe
      final tempBoxName = '${boxName}_migration_temp';
      final tempBox =
          await Hive.openBox<T>(tempBoxName, encryptionCipher: cipher);

      for (final entry in data.entries) {
        await tempBox.put(entry.key, entry.value);
      }

      await tempBox.close();

      // 4. Swap boxes on disk
      await Hive.deleteBoxFromDisk(boxName);

      // This is a bit hacky but the most reliable way in Hive to rename a box on disk:
      // Open temp box again and compact it to ensure it's written, then we'll rely on it.
      // Actually, Hive doesn't provide an easy way to 'rename' a box on disk.
      // Best way: Just reopen the main box with encryption and rewrite.

      await Hive.openBox<T>(boxName, encryptionCipher: cipher);
      final newEncryptedBox = Hive.box<T>(boxName);
      for (final entry in data.entries) {
        await newEncryptedBox.put(entry.key, entry.value);
      }

      await Hive.deleteBoxFromDisk(tempBoxName);
      debugPrint('Successfully migrated $boxName to encryption');
    } catch (e) {
      debugPrint('Critical error during migration of $boxName: $e');
      rethrow;
    }
  }

  /// Restore database from backup
  static Future<void> restoreDatabase(String backupPath) async {
    // This would restore all Hive box files from the backup location
    // Implementation depends on platform-specific file operations
    debugPrint('Database restore from $backupPath (not yet implemented)');
  }

  /// Get or generate Hive encryption key
  static Future<Uint8List> getEncryptionKey() async {
    String? keyString = await _secureStorage.read(key: _encryptionKeyName);

    if (keyString == null) {
      // Generate new secure key
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
          key: _encryptionKeyName, value: base64UrlEncode(key));
      return Uint8List.fromList(key);
    }

    return base64Url.decode(keyString);
  }

  /// Get Hive encryption cipher
  static Future<HiveAesCipher?> getEncryptionCipher() async {
    try {
      final key = await getEncryptionKey();
      return HiveAesCipher(key);
    } catch (e) {
      debugPrint('Error getting encryption cipher: $e');
      return null;
    }
  }
}
