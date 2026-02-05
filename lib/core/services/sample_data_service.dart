import 'dart:math';
import '../../features/calendar/models/calendar_event.dart';
import '../../features/calendar/models/symptom_log.dart';
import '../../features/calendar/models/cycle_data.dart';
import '../../features/calendar/services/calendar_data_service.dart';
import '../../features/sleep_tracking/models/sleep_log.dart';
import '../../features/sleep_tracking/services/sleep_data_service.dart';

import '../../features/notes/models/note.dart';
import '../../features/notes/services/notes_data_service.dart';
import '../../features/habits/models/habit.dart';
import '../../features/habits/services/habit_service.dart';

/// Service for generating sample data for new users.
///
/// This service populates the database with realistic examples of:
/// - Cycle Profile & Symptom Logs
/// - Sleep logs with analytical data
/// - Notes with varied moods
/// - Habits with categories
/// - Calendar events
class SampleDataService {
  final CalendarDataService _calendarService = CalendarDataService();
  final SleepDataService _sleepService = SleepDataService();

  final NotesDataService _notesService = NotesDataService();
  final HabitService _habitService = HabitService();

  /// Initialize all required features and services
  Future<void> _initServices() async {
    // If we just wiped data, we need to ensure the services re-open their boxes
    // We call init() on each service, which typically checks Hive.isBoxOpen
    // But since we did a hard delete, we might need to force it or handle errors
    try {
      await _calendarService.init();
      await _sleepService.init();
      await _notesService.init();
      await _habitService.init();
    } catch (e) {
      // If initialization fails, rethrow so we can catch it in UI
      throw Exception('Failed to initialize services for sample data: $e');
    }
  }

  /// Generates and seeds a comprehensive set of sample data.
  ///
  /// This is typically called at the end of the onboarding flow
  /// if the user chooses to start with sample data.
  Future<void> generateSampleData() async {
    await _initServices();

    final random = Random();
    final now = DateTime.now();

    // 1. Seed Cycle Profile
    final lastPeriodStart = now.subtract(const Duration(days: 15));
    final profile = UserCycleProfile(
      lastPeriodStart: lastPeriodStart,
      averageCycleLength: 28,
      averagePeriodLength: 5,
    );
    await _calendarService.saveCycleProfile(profile);

    // 2. Seed Symptom Logs (Retrospective 30 days)
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      // Only log symptoms on some days
      if (random.nextDouble() > 0.4) {
        final symptoms = <String>[];
        if (i % 28 < 5) symptoms.add('Cramps');
        if (random.nextBool()) symptoms.add('Headache');
        if (random.nextBool()) symptoms.add('Bloating');

        final log = SymptomLog(
          date: date,
          symptoms: symptoms,
          painLevel: random.nextInt(6),
          flowIntensity: (i % 28 < 5) ? random.nextInt(4) + 1 : 0,
          notes: i == 15 ? 'Period started today. Feeling a bit tired.' : null,
        );
        await _calendarService.saveSymptom(log);
      }
    }

    // 3. Seed Sleep Logs (Last 14 days)
    for (int i = 0; i < 14; i++) {
      final date = now.subtract(Duration(days: i));
      final bedtime = DateTime(date.year, date.month, date.day,
          22 + random.nextInt(2), random.nextInt(60));
      final wakeTime =
          bedtime.add(Duration(hours: 7, minutes: random.nextInt(120)));

      final sleepLog = SleepLog(
        bedtime: bedtime,
        wakeTime: wakeTime,
        quality: random.nextInt(5) + 1,
        notes: i == 0 ? 'Woke up feeling refreshed.' : '',
      );
      await _sleepService.saveLog(sleepLog);
    }

    // 4. Seed Notes (Migrated from hardcoded)
    final sampleNotes = [
      Note(
        title: 'Morning Routine',
        message: 'Meditation, 10 min yoga, and glass of water.',
        isPinned: true,
        mood: Mood.happy,
        date: now,
      ),
      Note(
        title: 'Groceries',
        message: 'Oat milk, berries, chicken breast, spinach.',
        isPinned: true,
        mood: Mood.neutral,
        date: now.subtract(const Duration(days: 1)),
      ),
      Note(
        title: 'Project Ideas',
        message: 'App for plant care tracking...',
        isPinned: false,
        mood: Mood.excited,
        date: now.subtract(const Duration(days: 2)),
      ),
    ];
    for (var note in sampleNotes) {
      await _notesService.saveNote(note);
    }

    // 5. Seed Habits (Migrated from Meals)
    final sampleHabits = [
      Habit(
        title: 'Morning Standup',
        description: 'Prepare notes for daily team meeting',
        isFavorite: true,
        category: 'Work',
        date: now.subtract(const Duration(days: 0)),
        reminderTime: now.add(const Duration(hours: 1)),
        frequency: [1, 2, 3, 4, 5], // Mon-Fri
      ),
      Habit(
        title: 'Drink Water',
        description: 'Glass of water after waking up',
        isFavorite: false,
        category: 'Wellness',
        date: now.subtract(const Duration(days: 1)),
        frequency: [1, 2, 3, 4, 5, 6, 7], // Every day
      ),
      Habit(
        title: 'Read Book',
        description: 'Read 10 pages before bed',
        isFavorite: false,
        category: 'Productivity',
        date: now.subtract(const Duration(days: 2)),
        reminderTime: now.add(const Duration(hours: 2)),
        frequency: [6, 7], // Weekends
      ),
    ];
    for (var habit in sampleHabits) {
      await _habitService.saveHabit(habit);
    }

    // 6. Seed a few Calendar Events
    final events = [
      CalendarEvent(
        title: 'Doctor Appointment',
        description: 'Annual checkup.',
        date: now.add(const Duration(days: 2)),
        category: 'Health',
      ),
      CalendarEvent(
        title: 'Gym Session',
        description: 'Leg day!',
        date: now.subtract(const Duration(days: 1)),
        category: 'Fitness',
      ),
    ];
    for (var event in events) {
      await _calendarService.saveEvent(event);
    }
  }
}
