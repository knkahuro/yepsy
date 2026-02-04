import 'package:hive/hive.dart';

part 'cycle_data.g.dart';

@HiveType(typeId: 6)
class CycleData extends HiveObject {
  @HiveField(0)
  final DateTime periodStartDate;

  @HiveField(1)
  final DateTime? periodEndDate;

  @HiveField(2)
  final int cycleLength;

  @HiveField(3)
  final int periodLength;

  @HiveField(4)
  final bool isAnomaly;

  CycleData({
    required this.periodStartDate,
    this.periodEndDate,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.isAnomaly = false,
  });

  CycleData copyWith({
    DateTime? periodStartDate,
    DateTime? periodEndDate,
    int? cycleLength,
    int? periodLength,
    bool? isAnomaly,
  }) {
    return CycleData(
      periodStartDate: periodStartDate ?? this.periodStartDate,
      periodEndDate: periodEndDate ?? this.periodEndDate,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      isAnomaly: isAnomaly ?? this.isAnomaly,
    );
  }
}

@HiveType(typeId: 7)
class UserCycleProfile extends HiveObject {
  @HiveField(0)
  final int averageCycleLength;

  @HiveField(1)
  final int averagePeriodLength;

  @HiveField(2)
  final List<CycleData> historicalCycles;

  @HiveField(3)
  final DateTime? lastPeriodStart;

  UserCycleProfile({
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.historicalCycles = const [],
    this.lastPeriodStart,
  });

  UserCycleProfile copyWith({
    int? averageCycleLength,
    int? averagePeriodLength,
    List<CycleData>? historicalCycles,
    DateTime? lastPeriodStart,
  }) {
    return UserCycleProfile(
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
      historicalCycles: historicalCycles ?? this.historicalCycles,
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
    );
  }
}
