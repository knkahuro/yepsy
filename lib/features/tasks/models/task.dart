import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@HiveType(typeId: 5)
class ActivityTask {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final bool isFavorite;
  @HiveField(5)
  final String category;
  @HiveField(7)
  final DateTime date;
  @HiveField(8)
  final DateTime? taskTime;
  @HiveField(9)
  final List<DateTime> completedDates;
  @HiveField(10)
  final List<int> frequency;

  ActivityTask({
    String? id,
    required this.title,
    required this.description,
    this.isFavorite = false,
    this.category = 'Other',
    DateTime? date,
    this.taskTime,
    List<DateTime>? completedDates,
    List<int>? frequency,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        completedDates = completedDates ?? [],
        frequency = frequency ?? [1, 2, 3, 4, 5, 6, 7];

  ActivityTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isFavorite,
    String? category,
    DateTime? date,
    DateTime? taskTime,
    List<DateTime>? completedDates,
    List<int>? frequency,
  }) {
    return ActivityTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      date: date ?? this.date,
      taskTime: taskTime ?? this.taskTime,
      completedDates: completedDates ?? this.completedDates,
      frequency: frequency ?? this.frequency,
    );
  }
}
