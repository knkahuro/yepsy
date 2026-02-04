import '../../features/calendar/services/calendar_data_service.dart';
import '../../features/notes/services/notes_data_service.dart';
import '../../features/meals/services/meals_data_service.dart';
import '../../features/sleep_tracking/services/sleep_data_service.dart';

class StreakService {
  final CalendarDataService _calendarService = CalendarDataService();
  final NotesDataService _notesService = NotesDataService();
  final MealsDataService _mealsService = MealsDataService();
  final SleepDataService _sleepService = SleepDataService();

  Future<void> _initServices() async {
    await _calendarService.init();
    await _notesService.init();
    await _mealsService.init();
    await _sleepService.init();
  }

  /// Calculates the current streak of consecutive days with at least one log.
  Future<int> calculateCurrentStreak() async {
    await _initServices();

    int streak = 0;
    DateTime dateToCheck = DateTime.now();

    // Normalize date to midnight for consistent comparison
    dateToCheck =
        DateTime(dateToCheck.year, dateToCheck.month, dateToCheck.day);

    while (true) {
      final hasLog = await _hasActivityOnDate(dateToCheck);
      if (hasLog) {
        streak++;
        dateToCheck = dateToCheck.subtract(const Duration(days: 1));
      } else {
        // If no log today, streak might still be alive if there was a log yesterday
        // (i.e. if dateToCheck is today and has no log, we check yesterday)
        final isToday = _isSameDay(dateToCheck, DateTime.now());
        if (isToday) {
          dateToCheck = dateToCheck.subtract(const Duration(days: 1));
          final hasYesterdayLog = await _hasActivityOnDate(dateToCheck);
          if (hasYesterdayLog) {
            // Streak is alive from yesterday, but doesn't include today yet
            // The loop will continue from yesterday
            continue;
          } else {
            return 0; // No activity today or yesterday
          }
        }
        break; // Streak ended
      }
    }

    return streak;
  }

  /// Checks if there is any activity (note, meal, symptom, or sleep log) on a specific day.
  Future<bool> _hasActivityOnDate(DateTime date) async {
    // 1. Check Notes
    final notes = await _notesService.getAllNotes();
    final hasNote = notes.any((n) => _isSameDay(n.date, date));
    if (hasNote) return true;

    // 2. Check Meals
    final meals = await _mealsService.getAllMeals();
    if (meals.any((m) => _isSameDay(m.date, date))) return true;

    // 3. Check Symptoms & Events
    final symptoms = await _calendarService.getAllSymptoms();
    if (symptoms.any((s) => _isSameDay(s.date, date))) return true;

    final events = await _calendarService.getAllEvents();
    if (events.any((e) => _isSameDay(e.date, date))) return true;

    // 4. Check Sleep
    final sleepLogs = await _sleepService.getAllLogs();
    if (sleepLogs.any((s) => _isSameDay(s.bedtime, date))) return true;

    return false;
  }

  bool _isSameDay(DateTime? d1, DateTime d2) {
    if (d1 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
