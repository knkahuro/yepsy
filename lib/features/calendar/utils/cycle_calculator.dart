import 'package:flutter/material.dart';
import '../models/cycle_data.dart';

class CycleCalculator {
  /// Calculate the current cycle day based on last period start
  static int getCurrentCycleDay(DateTime lastPeriodStart, DateTime today) {
    return today.difference(lastPeriodStart).inDays + 1;
  }

  /// Predict the next period start date
  static DateTime predictNextPeriod(
      DateTime lastPeriodStart, int averageCycleLength) {
    return lastPeriodStart.add(Duration(days: averageCycleLength));
  }

  /// Calculate fertile window (ovulation ± 5 days)
  /// Ovulation typically occurs 14 days before next period
  static DateTimeRange calculateFertileWindow(
      DateTime lastPeriodStart, int averageCycleLength) {
    final ovulationDay =
        lastPeriodStart.add(Duration(days: averageCycleLength - 14));

    return DateTimeRange(
      start: ovulationDay.subtract(const Duration(days: 5)),
      end: ovulationDay.add(const Duration(days: 1)),
    );
  }

  /// Get ovulation day
  static DateTime getOvulationDay(
      DateTime lastPeriodStart, int averageCycleLength) {
    return lastPeriodStart.add(Duration(days: averageCycleLength - 14));
  }

  /// Determine cycle phase for a given day
  static CyclePhase getCyclePhase(
      DateTime day, DateTime lastPeriodStart, int averageCycleLength) {
    final cycleDay = getCurrentCycleDay(lastPeriodStart, day);

    if (cycleDay <= 5) return CyclePhase.menstrual;
    if (cycleDay <= averageCycleLength - 16) return CyclePhase.follicular;
    if (cycleDay <= averageCycleLength - 12) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }

  /// Check if a day is within the fertile window
  static bool isInFertileWindow(
      DateTime day, DateTime lastPeriodStart, int averageCycleLength) {
    final fertileWindow =
        calculateFertileWindow(lastPeriodStart, averageCycleLength);
    return (day.isAfter(fertileWindow.start) ||
            day.isAtSameMomentAs(fertileWindow.start)) &&
        (day.isBefore(fertileWindow.end) ||
            day.isAtSameMomentAs(fertileWindow.end));
  }

  /// Check if a day is predicted period day
  static bool isPredictedPeriodDay(DateTime day, DateTime lastPeriodStart,
      int averageCycleLength, int averagePeriodLength) {
    final nextPeriodStart =
        predictNextPeriod(lastPeriodStart, averageCycleLength);
    final periodEnd =
        nextPeriodStart.add(Duration(days: averagePeriodLength - 1));

    return (day.isAfter(nextPeriodStart) ||
            day.isAtSameMomentAs(nextPeriodStart)) &&
        (day.isBefore(periodEnd) || day.isAtSameMomentAs(periodEnd));
  }

  /// Update average cycle length based on historical data with weighted stability
  /// and robust outlier detection.
  static int calculateAverageCycleLength(List<CycleData> historicalCycles) {
    if (historicalCycles.length < 2) return 28; // Default

    final cycleLengths = <int>[];
    for (int i = 1; i < historicalCycles.length; i++) {
      final length = historicalCycles[i]
          .periodStartDate
          .difference(historicalCycles[i - 1].periodStartDate)
          .inDays;
      cycleLengths.add(length);
    }

    if (cycleLengths.isEmpty) return 28;

    // Filter out anomalies using Standard Deviation
    final filteredLengths = _filterOutliers(cycleLengths);

    return _calculateWeightedAverage(filteredLengths, defaultVal: 28);
  }

  /// Update average period length based on historical data with weighted stability
  static int calculateAveragePeriodLength(List<CycleData> historicalCycles) {
    if (historicalCycles.isEmpty) return 5; // Default

    final periodLengths = historicalCycles
        .where((cycle) => cycle.periodEndDate != null)
        .map((cycle) =>
            cycle.periodEndDate!.difference(cycle.periodStartDate).inDays + 1)
        .toList();

    if (periodLengths.isEmpty) return 5;

    // Filter out anomalies
    final filteredLengths = _filterOutliers(periodLengths);

    return _calculateWeightedAverage(filteredLengths, defaultVal: 5);
  }

  /// Calculates a weighted average that prioritizes recent data.
  ///
  /// Biological rationale: Body cycles change over time due to age and lifestyle.
  /// We give 60% weight to the most recent 3 cycles (Recent Trend) and 40%
  /// weight to the remaining historical data (Baseline Anchor).
  /// This ensures responsiveness without losing long-term context.
  static int _calculateWeightedAverage(List<int> values,
      {required int defaultVal}) {
    if (values.isEmpty) return defaultVal;
    if (values.length <= 3) {
      return (values.reduce((a, b) => a + b) / values.length).round();
    }

    final int count = values.length;
    const recentCount = 3;
    final olderCount = count - recentCount;

    final recentSublist = values.sublist(count - recentCount);
    final olderSublist = values.sublist(0, count - recentCount);

    final recentAvg = recentSublist.reduce((a, b) => a + b) / recentCount;
    final olderAvg = olderSublist.reduce((a, b) => a + b) / olderCount;

    // 60% weight to recent 3, 40% to older
    return (recentAvg * 0.6 + olderAvg * 0.4).round();
  }

  /// Filters out statistical anomalies using the Standard Deviation method.
  ///
  /// We use a 2-Sigma (2 Standard Deviations) threshold. In a normal distribution,
  /// 95.4% of data falls within this range. Any value outside is considered
  /// an outlier (e.g., due to illness or extreme stress) and is excluded
  /// from the predictive models to prevent skewing future period dates.
  static List<int> _filterOutliers(List<int> values) {
    if (values.length < 4) return values; // Not enough data for robust SD

    final double mean = values.reduce((a, b) => a + b) / values.length;
    final double variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    final double stdDev =
        variance > 0 ? (variance > 1 ? _sqrt(variance) : 1) : 0;

    if (stdDev == 0) return values;

    // 2 SD filter (standard for health anomaly detection)
    return values.where((v) => (v - mean).abs() <= 2 * stdDev).toList();
  }

  /// Simple square root implementation since dart:math might not be preferred
  /// in custom lightweight utils or to avoid extra imports if possible,
  /// but we'll use a basic hero's method or just import dart:math.
  /// Actually, it's better to just import dart:math at the top.
  static double _sqrt(double n) {
    if (n < 0) return 0;
    if (n == 0) return 0;
    double x = n;
    double y = 1;
    const double e = 0.000001;
    while (x - y > e) {
      x = (x + y) / 2;
      y = n / x;
    }
    return x;
  }
}

enum CyclePhase {
  menstrual,
  follicular,
  ovulation,
  luteal,
}
