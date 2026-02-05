import 'package:hive/hive.dart';
import '../models/calendar_event.dart';
import '../models/symptom_log.dart';
import '../models/cycle_data.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/secure_delete_service.dart';

class CalendarDataService {
  static final CalendarDataService _instance = CalendarDataService._internal();
  factory CalendarDataService() => _instance;
  CalendarDataService._internal();

  static const String _eventsBoxName = 'calendar_events';
  static const String _symptomsBoxName = 'symptom_logs';
  static const String _cycleProfileBoxName = 'cycle_profile';

  // Boxes
  late LazyBox<CalendarEvent> _eventsBox;
  late LazyBox<SymptomLog> _symptomsBox;
  late LazyBox<UserCycleProfile> _cycleProfileBox;

  // Encryption service
  final EncryptionService _encryptionService = EncryptionService();

  // Secure delete service
  final SecureDeleteService _secureDeleteService = SecureDeleteService();

  bool _isInitialized = false;

  // Initialize Hive boxes
  Future<void> init() async {
    if (_isInitialized) return;
    // Migrate boxes to encryption if needed
    await DatabaseService.migrateBoxToEncryption<CalendarEvent>(_eventsBoxName);
    await DatabaseService.migrateBoxToEncryption<SymptomLog>(_symptomsBoxName);
    await DatabaseService.migrateBoxToEncryption<UserCycleProfile>(
        _cycleProfileBoxName);

    final cipher = await DatabaseService.getEncryptionCipher();

    _eventsBox = await Hive.openLazyBox<CalendarEvent>(_eventsBoxName,
        encryptionCipher: cipher);
    _symptomsBox = await Hive.openLazyBox<SymptomLog>(_symptomsBoxName,
        encryptionCipher: cipher);
    _cycleProfileBox = await Hive.openLazyBox<UserCycleProfile>(
        _cycleProfileBoxName,
        encryptionCipher: cipher);

    // Initialize encryption
    await _encryptionService.initialize();
    _isInitialized = true;
  }

  // ============ Events ============

  Future<void> saveEvent(CalendarEvent event) async {
    await _eventsBox.put(event.id, event);
  }

  Future<void> deleteEvent(String eventId) async {
    await secureDeleteEvent(eventId);
  }

  /// Securely delete event with multi-pass overwrite
  Future<void> secureDeleteEvent(String eventId) async {
    final event = await _eventsBox.get(eventId);
    if (event == null) return;

    await _secureDeleteService.multiPassOverwrite(() async {
      // Overwrite with random data
      final randomEvent = CalendarEvent(
        id: event.id,
        title: _secureDeleteService.secureOverwriteString(event.title),
        description: event.description != null
            ? _secureDeleteService.secureOverwriteString(event.description!)
            : '',
        date: _secureDeleteService.secureOverwriteDateTime(),
        category: event.category != null
            ? _secureDeleteService.secureOverwriteString(event.category!)
            : '',
      );
      await _eventsBox.put(eventId, randomEvent);
    });

    // Final delete
    await _eventsBox.delete(eventId);
    _secureDeleteService.logSecureDeletion('Event', eventId);
  }

  Future<List<CalendarEvent>> getAllEvents() async {
    final List<CalendarEvent> events = [];
    for (var key in _eventsBox.keys) {
      final event = await _eventsBox.get(key);
      if (event != null) events.add(event);
    }
    return events;
  }

  Future<List<CalendarEvent>> getEventsForDay(DateTime day) async {
    final List<CalendarEvent> events = [];
    for (var key in _eventsBox.keys) {
      final event = await _eventsBox.get(key);
      if (event != null &&
          event.date.year == day.year &&
          event.date.month == day.month &&
          event.date.day == day.day) {
        events.add(event);
      }
    }
    return events;
  }

  // ============ Symptoms ============

  Future<void> saveSymptom(SymptomLog symptom) async {
    // Encrypt notes if encryption is enabled
    final encryptedNotes = symptom.notes != null
        ? await _encryptionService.encryptIfEnabled(symptom.notes!)
        : null;

    final encryptedSymptom = symptom.copyWith(notes: encryptedNotes);
    await _symptomsBox.put(encryptedSymptom.id, encryptedSymptom);
  }

  Future<void> deleteSymptom(String symptomId) async {
    await secureDeleteSymptom(symptomId);
  }

  /// Securely delete symptom with multi-pass overwrite
  Future<void> secureDeleteSymptom(String symptomId) async {
    final symptom = await _symptomsBox.get(symptomId);
    if (symptom == null) return;

    await _secureDeleteService.multiPassOverwrite(() async {
      // Overwrite with random data
      final randomSymptom = SymptomLog(
        id: symptom.id,
        date: _secureDeleteService.secureOverwriteDateTime(),
        symptoms: _secureDeleteService.secureOverwriteList(symptom.symptoms),
        painLevel: _secureDeleteService.secureOverwriteInt(0, 10),
        flowIntensity: _secureDeleteService.secureOverwriteInt(0, 5),
        notes: symptom.notes != null
            ? _secureDeleteService.secureOverwriteString(symptom.notes!)
            : null,
      );
      await _symptomsBox.put(symptomId, randomSymptom);
    });

    // Final delete
    await _symptomsBox.delete(symptomId);
    _secureDeleteService.logSecureDeletion('Symptom', symptomId);
  }

  Future<List<SymptomLog>> getAllSymptoms() async {
    final List<SymptomLog> symptoms = [];
    for (var key in _symptomsBox.keys) {
      final symptom = await _symptomsBox.get(key);
      if (symptom != null) {
        symptoms.add(_decryptSymptom(symptom));
      }
    }
    return symptoms;
  }

  Future<List<SymptomLog>> getSymptomsForDay(DateTime day) async {
    final List<SymptomLog> symptoms = [];
    for (var key in _symptomsBox.keys) {
      final symptom = await _symptomsBox.get(key);
      if (symptom != null &&
          symptom.date.year == day.year &&
          symptom.date.month == day.month &&
          symptom.date.day == day.day) {
        symptoms.add(_decryptSymptom(symptom));
      }
    }
    return symptoms;
  }

  // Helper method to decrypt symptom notes
  SymptomLog _decryptSymptom(SymptomLog symptom) {
    if (symptom.notes == null || symptom.notes!.isEmpty) {
      return symptom;
    }

    // Decrypt notes synchronously (encryption service handles the check)
    final decryptedNotes = _encryptionService.decrypt(symptom.notes!);
    return symptom.copyWith(notes: decryptedNotes);
  }

  /// Get health score history (percentage) for the last [days] days
  /// Returns a Map<DateTime, double> where key is date and value is health score (100 - symptom intensity)
  Future<Map<DateTime, double>> getSymptomHistory(int days) async {
    final Map<DateTime, double> history = {};
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));

    // Initialize days with 100.0 (Perfect Health default)
    // If no log exists, we assume good health
    for (int i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(d.year, d.month, d.day);
      history[normalizedDate] = 100.0;
    }

    // Populate with wellness score
    for (var key in _symptomsBox.keys) {
      final symptom = await _symptomsBox.get(key);
      if (symptom != null) {
        if (symptom.date.isAfter(cutoff)) {
          final normalizedDate =
              DateTime(symptom.date.year, symptom.date.month, symptom.date.day);

          final pain = (symptom.painLevel ?? 0).toDouble(); // 0-10
          final flow = (symptom.flowIntensity ?? 0).toDouble(); // 0-5
          final totalIntensity = pain + flow;

          // Max possible intensity assumed around 15 (10 pain + 5 flow)
          // We map this to a percentage deduction
          // 15 intensity = 100% deduction -> 0% Health
          // 0 intensity = 0% deduction -> 100% Health
          const maxIntensity = 15.0;
          final deduction = (totalIntensity / maxIntensity) * 100.0;

          // Wellness Score
          final wellnessScore = (100.0 - deduction).clamp(0.0, 100.0);

          // If multiple logs, take the lowest wellness score (highest intensity)
          if (wellnessScore < (history[normalizedDate] ?? 100.0)) {
            history[normalizedDate] = wellnessScore;
          }
        }
      }
    }

    return history;
  }

  // ============ Cycle Profile ============

  Future<void> saveCycleProfile(UserCycleProfile profile) async {
    await _cycleProfileBox.put('profile', profile);
  }

  Future<UserCycleProfile?> getCycleProfile() async {
    return await _cycleProfileBox.get('profile');
  }

  Future<UserCycleProfile> getOrCreateCycleProfile() async {
    final profile = await _cycleProfileBox.get('profile');
    if (profile != null) return profile;

    // Create default profile
    final defaultProfile = UserCycleProfile();
    await saveCycleProfile(defaultProfile);
    return defaultProfile;
  }

  // ============ Cleanup ============

  Future<void> clearAllData() async {
    await _eventsBox.clear();
    await _symptomsBox.clear();
    await _cycleProfileBox.clear();
  }
}
