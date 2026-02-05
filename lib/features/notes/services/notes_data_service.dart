import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/secure_delete_service.dart';

class NotesDataService {
  static final NotesDataService _instance = NotesDataService._internal();
  factory NotesDataService() => _instance;
  NotesDataService._internal();

  static const String _boxName = 'notes';

  // Encryption service
  final EncryptionService _encryptionService = EncryptionService();

  // Secure delete service
  final SecureDeleteService _secureDeleteService = SecureDeleteService();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    // Migrate to encryption if needed
    await DatabaseService.migrateBoxToEncryption<Note>(_boxName);

    final cipher = await DatabaseService.getEncryptionCipher();
    await Hive.openLazyBox<Note>(_boxName, encryptionCipher: cipher);

    // Initialize encryption service
    await _encryptionService.initialize();
    _isInitialized = true;
  }

  LazyBox<Note> get _box => Hive.lazyBox<Note>(_boxName);

  Future<List<Note>> getAllNotes() async {
    final List<Note> notes = [];
    for (var key in _box.keys) {
      final note = await _box.get(key);
      if (note != null) notes.add(note);
    }
    // Sort by date, newest first
    notes.sort((a, b) {
      if (a.date == null || b.date == null) return 0;
      return b.date!.compareTo(a.date!);
    });
    return notes;
  }

  Future<void> saveNote(Note note) async {
    await _box.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    final note = await _box.get(id);
    if (note == null) return;

    await _secureDeleteService.multiPassOverwrite(() async {
      // Overwrite with random data
      final randomNote = Note(
        id: note.id,
        title: _secureDeleteService.secureOverwriteString(note.title),
        message: _secureDeleteService.secureOverwriteString(note.message),
        isPinned: false,
        mood: note.mood,
        date: _secureDeleteService.secureOverwriteDateTime(),
      );
      await _box.put(id, randomNote);
    });

    await _box.delete(id);
    _secureDeleteService.logSecureDeletion('Note', id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Get mood history for the last [days] days
  /// Returns a Map<DateTime, double> where key is date and value is average mood score (1-5)
  Future<Map<DateTime, double>> getMoodHistory(int days) async {
    final Map<DateTime, List<double>> dailyScores = {};
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));

    // Mood Score Mapping (Percentage 20-100%)
    double getMoodScore(Mood mood) {
      switch (mood) {
        case Mood.excited:
          return 100.0;
        case Mood.happy:
          return 80.0;
        case Mood.neutral:
          return 60.0;
        case Mood.tired:
          return 40.0;
        case Mood.sad:
          return 20.0;
      }
    }

    for (var key in _box.keys) {
      final note = await _box.get(key);
      if (note != null && note.date != null && note.mood != null) {
        if (note.date!.isAfter(cutoff)) {
          final normalizedDate =
              DateTime(note.date!.year, note.date!.month, note.date!.day);

          if (!dailyScores.containsKey(normalizedDate)) {
            dailyScores[normalizedDate] = [];
          }
          dailyScores[normalizedDate]!.add(getMoodScore(note.mood!));
        }
      }
    }

    // Calculate averages
    final Map<DateTime, double> history = {};

    // Initialize empty days with 0.0 (or skip, but 0 helps graph)
    for (int i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(d.year, d.month, d.day);
      history[normalizedDate] = 0.0;
    }

    dailyScores.forEach((date, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      history[date] = avg;
    });

    return history;
  }
}
