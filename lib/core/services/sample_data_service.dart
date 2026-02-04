import 'dart:math';
import '../../features/calendar/models/calendar_event.dart';
import '../../features/calendar/models/symptom_log.dart';
import '../../features/calendar/models/cycle_data.dart';
import '../../features/calendar/services/calendar_data_service.dart';
import '../../features/sleep_tracking/models/sleep_log.dart';
import '../../features/sleep_tracking/services/sleep_data_service.dart';
import '../../features/notes/models/note.dart';
import '../../features/notes/services/notes_data_service.dart';
import '../../features/meals/models/meal.dart';
import '../../features/meals/services/meals_data_service.dart';

/// Service for generating sample data for new users.
///
/// This service populates the database with realistic examples of:
/// - Cycle Profile & Symptom Logs
/// - Sleep logs with analytical data
/// - Notes with varied moods
/// - Meals with categories and ratings
/// - Calendar events
class SampleDataService {
  final CalendarDataService _calendarService = CalendarDataService();
  final SleepDataService _sleepService = SleepDataService();
  final NotesDataService _notesService = NotesDataService();
  final MealsDataService _mealsService = MealsDataService();

  /// Initialize all required features and services
  Future<void> _initServices() async {
    await _calendarService.init();
    await _sleepService.init();
    await _notesService.init();
    await _mealsService.init();
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

    // 5. Seed Meals (Migrated from hardcoded)
    final sampleMeals = [
      Meal(
        title: 'Supper',
        description: 'Rice + beef + cabbage',
        isFavorite: true,
        category: 'Dinner',
        rating: 5,
        date: now.subtract(const Duration(days: 0)),
      ),
      Meal(
        title: 'Breakfast',
        description: 'Oatmeal with berries',
        isFavorite: false,
        category: 'Breakfast',
        rating: 4,
        date: now.subtract(const Duration(days: 1)),
      ),
      Meal(
        title: 'Lunch',
        description: 'Grilled chicken salad',
        isFavorite: false,
        category: 'Lunch',
        rating: 3,
        date: now.subtract(const Duration(days: 2)),
      ),
    ];
    for (var meal in sampleMeals) {
      await _mealsService.saveMeal(meal);
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
