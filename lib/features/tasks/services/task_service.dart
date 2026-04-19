import 'package:hive/hive.dart';
import '../models/task.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/secure_delete_service.dart';
import '../../calendar/services/notification_service.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  static const String _tasksBoxName = 'tasks';

  // Boxes
  late LazyBox<ActivityTask> _tasksBox;

  // Encryption service
  final EncryptionService _encryptionService = EncryptionService();

  // Secure delete service
  final SecureDeleteService _secureDeleteService = SecureDeleteService();

  // Notification service
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;

  // Initialize Hive boxes
  Future<void> init() async {
    if (_isInitialized) return;
    // Migrate boxes to encryption if needed
    await DatabaseService.migrateBoxToEncryption<ActivityTask>(_tasksBoxName);

    final cipher = await DatabaseService.getEncryptionCipher();

    _tasksBox =
        await Hive.openLazyBox<ActivityTask>(_tasksBoxName, encryptionCipher: cipher);

    // Initialize encryption
    await _encryptionService.initialize();

    // Initialize notifications
    await _notificationService.initialize();

    _isInitialized = true;
  }

  Future<void> saveTask(ActivityTask task) async {
    // Encrypt description if encryption is enabled
    final encryptedDesc =
        await _encryptionService.encryptIfEnabled(task.description);

    final encryptedTask = task.copyWith(description: encryptedDesc);
    await _tasksBox.put(task.id, encryptedTask);

    // Schedule or cancel notification
    if (task.taskTime != null) {
      await _notificationService.scheduleTaskTask(task);
    } else {
      await _notificationService.cancelTaskTask(task.id);
    }
  }

  Future<void> deleteTask(String taskId) async {
    await secureDeleteTask(taskId);
  }

  /// Securely delete task with multi-pass overwrite
  Future<void> secureDeleteTask(String taskId) async {
    // Cancel notification first (don't depend on task object existence)
    await _notificationService.cancelTaskTask(taskId);

    final task = await _tasksBox.get(taskId);
    if (task == null) return;

    await _secureDeleteService.multiPassOverwrite(() async {
      // Overwrite with random data
      final randomTask = ActivityTask(
        id: task.id,
        title: _secureDeleteService.secureOverwriteString(task.title),
        description:
            _secureDeleteService.secureOverwriteString(task.description),
        category: _secureDeleteService.secureOverwriteString(task.category),
        date: _secureDeleteService.secureOverwriteDateTime(),
      );
      await _tasksBox.put(taskId, randomTask);
    });

    // Final delete
    await _tasksBox.delete(taskId);
    _secureDeleteService.logSecureDeletion('ActivityTask', taskId);
  }

  Future<List<ActivityTask>> getAllTasks() async {
    final List<ActivityTask> tasks = [];
    for (var key in _tasksBox.keys) {
      final task = await _tasksBox.get(key);
      if (task != null) {
        tasks.add(_decryptTask(task));
      }
    }
    // Sort by date descending
    tasks.sort((a, b) => b.date.compareTo(a.date));
    return tasks;
  }

  Future<ActivityTask?> getTask(String id) async {
    final task = await _tasksBox.get(id);
    if (task != null) {
      return _decryptTask(task);
    }
    return null;
  }

  // Helper method to decrypt task description
  ActivityTask _decryptTask(ActivityTask task) {
    if (task.description.isEmpty) {
      return task;
    }

    // Decrypt description synchronously (encryption service handles the check)
    final decryptedDesc = _encryptionService.decrypt(task.description);
    return task.copyWith(description: decryptedDesc);
  }

  Future<void> clearAllData() async {
    // Cancel all task notifications before clearing
    for (var key in _tasksBox.keys) {
      await _notificationService.cancelTaskTask(key.toString());
    }
    await _tasksBox.clear();
  }

  bool isCompletedOnDate(ActivityTask task, DateTime date) {
    return task.completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  Future<ActivityTask?> toggleCompletion(String taskId, DateTime date) async {
    final task = await getTask(taskId);
    if (task == null) return null;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    List<DateTime> newCompletedDates = List.from(task.completedDates);

    if (isCompletedOnDate(task, normalizedDate)) {
      newCompletedDates.removeWhere((d) =>
          d.year == normalizedDate.year &&
          d.month == normalizedDate.month &&
          d.day == normalizedDate.day);
    } else {
      newCompletedDates.add(normalizedDate);
    }

    final updatedTask = task.copyWith(completedDates: newCompletedDates);
    await saveTask(updatedTask);
    return updatedTask;
  }

  bool isDueToday(ActivityTask task) {
    final now = DateTime.now();
    return task.frequency.contains(now.weekday);
  }

  /// Get completion history for the last [days] days
  /// Returns a Map<DateTime, int> where key is date (at midnight) and value is completion count
  Future<Map<DateTime, int>> getCompletionHistory(int days) async {
    final Map<DateTime, int> history = {};
    final now = DateTime.now();

    // Initialize with 0 for all days
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      history[normalizedDate] = 0;
    }

    // Populate counts
    for (var key in _tasksBox.keys) {
      final task = await _tasksBox.get(key);
      if (task != null) {
        final decryptedTask = _decryptTask(task);
        for (var completedDate in decryptedTask.completedDates) {
          final normalizedComp = DateTime(
              completedDate.year, completedDate.month, completedDate.day);

          if (history.containsKey(normalizedComp)) {
            history[normalizedComp] = (history[normalizedComp] ?? 0) + 1;
          }
        }
      }
    }

    return history;
  }

  /// Get completion rate history (percentage) for the last [days] days
  /// Returns a Map<DateTime, double> where key is date and value is completion percentage (0-100)
  Future<Map<DateTime, double>> getCompletionRateHistory(int days) async {
    final Map<DateTime, double> history = {};
    final now = DateTime.now();

    // Cache all decrypted tasks first to avoid repeated decryptions
    final List<ActivityTask> allTasks = [];
    for (var key in _tasksBox.keys) {
      final task = await _tasksBox.get(key);
      if (task != null) {
        allTasks.add(_decryptTask(task));
      }
    }

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final weekday = date.weekday;

      int scheduledCount = 0;
      int completedCount = 0;

      for (var task in allTasks) {
        // Check if task existed on this date (created on or before)
        // Comparing only date parts to be inclusive of creation day
        final taskDate =
            DateTime(task.date.year, task.date.month, task.date.day);
        if (taskDate.isAfter(normalizedDate)) continue;

        // Check if scheduled for this weekday
        if (task.frequency.contains(weekday)) {
          scheduledCount++;

          // Check if completed on this date
          if (isCompletedOnDate(task, normalizedDate)) {
            completedCount++;
          }
        }
      }

      if (scheduledCount > 0) {
        history[normalizedDate] = (completedCount / scheduledCount) * 100.0;
      } else {
        history[normalizedDate] = 0.0;
      }
    }

    return history;
  }
}
