import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'meal.g.dart';

@HiveType(typeId: 5)
class Meal {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final bool isFavorite;
  @HiveField(4)
  final String? imagePath;
  @HiveField(5)
  final String category;
  @HiveField(6)
  final int rating;
  @HiveField(7)
  final DateTime date;

  Meal({
    String? id,
    required this.title,
    required this.description,
    this.isFavorite = false,
    this.imagePath,
    this.category = 'Other',
    this.rating = 0,
    DateTime? date,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Meal copyWith({
    String? id,
    String? title,
    String? description,
    bool? isFavorite,
    String? imagePath,
    String? category,
    int? rating,
    DateTime? date,
  }) {
    return Meal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      date: date ?? this.date,
    );
  }
}
