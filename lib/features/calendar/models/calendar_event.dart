import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'calendar_event.g.dart';

@HiveType(typeId: 0)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String? category;

  CalendarEvent({
    String? id,
    required this.date,
    required this.title,
    this.description,
    this.category,
  }) : id = id ?? const Uuid().v4();

  CalendarEvent copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? description,
    String? category,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }
}
