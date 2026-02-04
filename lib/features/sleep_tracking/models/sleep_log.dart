import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'sleep_log.g.dart';

@HiveType(typeId: 2)
class SleepLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime bedtime;

  @HiveField(2)
  final DateTime wakeTime;

  @HiveField(3)
  final int quality; // 1-5 rating

  @HiveField(4)
  final String notes;

  SleepLog({
    String? id,
    required this.bedtime,
    required this.wakeTime,
    this.quality = 3,
    this.notes = '',
  }) : id = id ?? const Uuid().v4();

  // Duration in hours
  double get durationHours {
    final diff = wakeTime.difference(bedtime);
    return diff.inMinutes / 60.0;
  }

  // Formatted duration string
  String get durationString {
    final diff = wakeTime.difference(bedtime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
