import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/secure_delete_service.dart';

class NotesDataService {
  static const String _boxName = 'notes';

  // Encryption service
  final EncryptionService _encryptionService = EncryptionService();

  // Secure delete service
  final SecureDeleteService _secureDeleteService = SecureDeleteService();

  Future<void> init() async {
    // Migrate to encryption if needed
    await DatabaseService.migrateBoxToEncryption<Note>(_boxName);

    final cipher = await DatabaseService.getEncryptionCipher();
    await Hive.openLazyBox<Note>(_boxName, encryptionCipher: cipher);

    // Initialize encryption service
    await _encryptionService.initialize();
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
}
