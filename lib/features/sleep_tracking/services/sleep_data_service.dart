import 'package:hive_flutter/hive_flutter.dart';
import '../models/sleep_log.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/secure_delete_service.dart';

class SleepDataService {
  static final SleepDataService _instance = SleepDataService._internal();
  factory SleepDataService() => _instance;
  SleepDataService._internal();

  static const String _boxName = 'sleep_logs';
  final SecureDeleteService _secureDeleteService = SecureDeleteService();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    // Migrate to encryption if needed
    await DatabaseService.migrateBoxToEncryption<SleepLog>(_boxName);

    final cipher = await DatabaseService.getEncryptionCipher();

    await Hive.openLazyBox<SleepLog>(_boxName, encryptionCipher: cipher);
    _isInitialized = true;
  }

  LazyBox<SleepLog> get _box => Hive.lazyBox<SleepLog>(_boxName);

  Future<List<SleepLog>> getAllLogs() async {
    final List<SleepLog> logs = [];
    for (var key in _box.keys) {
      final log = await _box.get(key);
      if (log != null) logs.add(log);
    }
    return logs..sort((a, b) => b.bedtime.compareTo(a.bedtime)); // Newest first
  }

  // Paginated logs
  Future<List<SleepLog>> getLogs(
      {required int page, required int pageSize}) async {
    final allLogs = await getAllLogs();
    final startIndex = page * pageSize;

    if (startIndex >= allLogs.length) {
      return [];
    }

    final endIndex = (startIndex + pageSize).clamp(0, allLogs.length);
    return allLogs.sublist(startIndex, endIndex);
  }

  Future<List<SleepLog>> getLogsForRange(DateTime start, DateTime end) async {
    final List<SleepLog> logs = [];
    for (var key in _box.keys) {
      final log = await _box.get(key);
      if (log != null &&
          log.bedtime.isAfter(start.subtract(const Duration(seconds: 1))) &&
          log.bedtime.isBefore(end.add(const Duration(days: 1)))) {
        logs.add(log);
      }
    }
    return logs;
  }

  // Get logs for the last 7 days (for graph)
  Future<List<SleepLog>> getRecentLogs() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return await getLogsForRange(sevenDaysAgo, now);
  }

  Future<void> saveLog(SleepLog log) async {
    await _box.put(log.id, log);
  }

  Future<void> deleteLog(String id) async {
    final log = await _box.get(id);
    if (log == null) return;

    await _secureDeleteService.multiPassOverwrite(() async {
      final randomLog = SleepLog(
        id: log.id,
        bedtime: _secureDeleteService.secureOverwriteDateTime(),
        wakeTime: _secureDeleteService.secureOverwriteDateTime(),
        quality: _secureDeleteService.secureOverwriteInt(1, 5),
        notes: _secureDeleteService.secureOverwriteString(log.notes),
      );
      await _box.put(id, randomLog);
    });

    await _box.delete(id);
    _secureDeleteService.logSecureDeletion('SleepLog', id);
  }

  Future<double> getAverageSleepDuration() async {
    final logs = await getAllLogs();
    if (logs.isEmpty) return 0;

    final totalHours = logs.fold(0.0, (sum, log) => sum + log.durationHours);
    return totalHours / logs.length;
  }

  Future<Map<String, dynamic>> getSleepInsights() async {
    final logs = await getAllLogs();
    if (logs.isEmpty) {
      return {
        'avgQuality': 0.0,
        'totalLogs': 0,
        'bestSleepDuration': 0.0,
      };
    }

    final totalQuality = logs.fold(0, (sum, log) => sum + log.quality);
    final avgQuality = totalQuality / logs.length;

    // Find best sleep (longest duration)
    double maxDuration = 0.0;
    for (var log in logs) {
      if (log.durationHours > maxDuration) {
        maxDuration = log.durationHours;
      }
    }

    return {
      'avgQuality': avgQuality,
      'totalLogs': logs.length,
      'bestSleepDuration': maxDuration,
    };
  }
}
