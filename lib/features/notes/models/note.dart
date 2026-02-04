import 'package:hive/hive.dart';

import 'package:uuid/uuid.dart';

part 'note.g.dart';

@HiveType(typeId: 4)
enum Mood {
  @HiveField(0)
  happy,
  @HiveField(1)
  sad,
  @HiveField(2)
  neutral,
  @HiveField(3)
  excited,
  @HiveField(4)
  tired,
}

@HiveType(typeId: 3)
class Note {
  @HiveField(0)
  final String title;
  @HiveField(1)
  final String message;
  @HiveField(2)
  final bool isPinned;
  @HiveField(3)
  final Mood? mood;
  @HiveField(4)
  final DateTime? date;
  @HiveField(5)
  final String id;

  Note({
    required this.title,
    required this.message,
    this.isPinned = false,
    this.mood,
    this.date,
    String? id,
  }) : id = id ?? const Uuid().v4();

  Note copyWith({
    String? title,
    String? message,
    bool? isPinned,
    Mood? mood,
    DateTime? date,
    String? id,
  }) {
    return Note(
      title: title ?? this.title,
      message: message ?? this.message,
      isPinned: isPinned ?? this.isPinned,
      mood: mood ?? this.mood,
      date: date ?? this.date,
      id: id ?? this.id,
    );
  }
}
