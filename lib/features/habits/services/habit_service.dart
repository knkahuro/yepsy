import 'package:hive/hive.dart';
import '../models/habit.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/secure_delete_service.dart';
import '../../calendar/services/notification_service.dart';

class HabitService {
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;
  HabitService._internal();

  static const String _habitsBoxName = 'habits';

  // Boxes
  late LazyBox<Habit> _habitsBox;

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
    await DatabaseService.migrateBoxToEncryption<Habit>(_habitsBoxName);

    final cipher = await DatabaseService.getEncryptionCipher();

    _habitsBox =
        await Hive.openLazyBox<Habit>(_habitsBoxName, encryptionCipher: cipher);

    // Initialize encryption
    await _encryptionService.initialize();

    // Initialize notifications
    await _notificationService.initialize();

    _isInitialized = true;
  }

  Future<void> saveHabit(Habit habit) async {
    // Encrypt description if encryption is enabled
    final encryptedDesc =
        await _encryptionService.encryptIfEnabled(habit.description);

    final encryptedHabit = habit.copyWith(description: encryptedDesc);
    await _habitsBox.put(habit.id, encryptedHabit);

    // Schedule or cancel notification
    if (habit.reminderTime != null) {
      await _notificationService.scheduleHabitReminder(habit);
    } else {
      await _notificationService.cancelHabitReminder(habit.id);
    }
  }

  Future<void> deleteHabit(String habitId) async {
    await secureDeleteHabit(habitId);
  }

  /// Securely delete habit with multi-pass overwrite
  Future<void> secureDeleteHabit(String habitId) async {
    final habit = await _habitsBox.get(habitId);
    if (habit == null) return;

    // Cancel notification
    await _notificationService.cancelHabitReminder(habitId);

    await _secureDeleteService.multiPassOverwrite(() async {
      // Overwrite with random data
      final randomHabit = Habit(
        id: habit.id,
        title: _secureDeleteService.secureOverwriteString(habit.title),
        description:
            _secureDeleteService.secureOverwriteString(habit.description),
        category: _secureDeleteService.secureOverwriteString(habit.category),
        date: _secureDeleteService.secureOverwriteDateTime(),
      );
      await _habitsBox.put(habitId, randomHabit);
    });

    // Final delete
    await _habitsBox.delete(habitId);
    _secureDeleteService.logSecureDeletion('Habit', habitId);
  }

  Future<List<Habit>> getAllHabits() async {
    final List<Habit> habits = [];
    for (var key in _habitsBox.keys) {
      final habit = await _habitsBox.get(key);
      if (habit != null) {
        habits.add(_decryptHabit(habit));
      }
    }
    // Sort by date descending
    habits.sort((a, b) => b.date.compareTo(a.date));
    return habits;
  }

  Future<Habit?> getHabit(String id) async {
    final habit = await _habitsBox.get(id);
    if (habit != null) {
      return _decryptHabit(habit);
    }
    return null;
  }

  // Helper method to decrypt habit description
  Habit _decryptHabit(Habit habit) {
    if (habit.description.isEmpty) {
      return habit;
    }

    // Decrypt description synchronously (encryption service handles the check)
    final decryptedDesc = _encryptionService.decrypt(habit.description);
    return habit.copyWith(description: decryptedDesc);
  }

  Future<void> clearAllData() async {
    // Cancel all habit notifications before clearing
    for (var key in _habitsBox.keys) {
      await _notificationService.cancelHabitReminder(key.toString());
    }
    await _habitsBox.clear();
  }

  bool isCompletedOnDate(Habit habit, DateTime date) {
    return habit.completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  Future<Habit?> toggleCompletion(String habitId, DateTime date) async {
    final habit = await getHabit(habitId);
    if (habit == null) return null;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    List<DateTime> newCompletedDates = List.from(habit.completedDates);

    if (isCompletedOnDate(habit, normalizedDate)) {
      newCompletedDates.removeWhere((d) =>
          d.year == normalizedDate.year &&
          d.month == normalizedDate.month &&
          d.day == normalizedDate.day);
    } else {
      newCompletedDates.add(normalizedDate);
    }

    final updatedHabit = habit.copyWith(completedDates: newCompletedDates);
    await saveHabit(updatedHabit);
    return updatedHabit;
  }

  bool isDueToday(Habit habit) {
    final now = DateTime.now();
    return habit.frequency.contains(now.weekday);
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
    for (var key in _habitsBox.keys) {
      final habit = await _habitsBox.get(key);
      if (habit != null) {
        final decryptedHabit = _decryptHabit(habit);
        for (var completedDate in decryptedHabit.completedDates) {
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

    // Cache all decrypted habits first to avoid repeated decryptions
    final List<Habit> allHabits = [];
    for (var key in _habitsBox.keys) {
      final habit = await _habitsBox.get(key);
      if (habit != null) {
        allHabits.add(_decryptHabit(habit));
      }
    }

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final weekday = date.weekday;

      int scheduledCount = 0;
      int completedCount = 0;

      for (var habit in allHabits) {
        // Check if habit existed on this date (created on or before)
        // Comparing only date parts to be inclusive of creation day
        final habitDate =
            DateTime(habit.date.year, habit.date.month, habit.date.day);
        if (habitDate.isAfter(normalizedDate)) continue;

        // Check if scheduled for this weekday
        if (habit.frequency.contains(weekday)) {
          scheduledCount++;

          // Check if completed on this date
          if (isCompletedOnDate(habit, normalizedDate)) {
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
