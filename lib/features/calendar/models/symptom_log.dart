import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'symptom_log.g.dart';

@HiveType(typeId: 1)
class SymptomLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final List<String> symptoms;

  @HiveField(3)
  final int? painLevel;

  @HiveField(4)
  final int? flowIntensity;

  @HiveField(5)
  final String? notes;

  SymptomLog({
    String? id,
    required this.date,
    required this.symptoms,
    this.painLevel,
    this.flowIntensity,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  SymptomLog copyWith({
    String? id,
    DateTime? date,
    List<String>? symptoms,
    int? painLevel,
    int? flowIntensity,
    String? notes,
  }) {
    return SymptomLog(
      id: id ?? this.id,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      painLevel: painLevel ?? this.painLevel,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      notes: notes ?? this.notes,
    );
  }
}
