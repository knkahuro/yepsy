import '../models/cycle_data.dart';
import '../models/symptom_log.dart';
import '../utils/cycle_calculator.dart';

class CycleLearningService {
  /// Detect if a symptom log indicates period start
  bool isPeriodStart(SymptomLog symptom) {
    return symptom.flowIntensity != null && symptom.flowIntensity! > 0;
  }

  /// Check if we should create a new cycle entry
  /// Returns true if this is a new period start and enough time has passed since last period
  bool shouldCreateNewCycle(
    SymptomLog symptom,
    UserCycleProfile profile,
  ) {
    if (!isPeriodStart(symptom)) return false;

    // If no last period, this is the first one
    if (profile.lastPeriodStart == null) return true;

    // Check if at least 20 days have passed (minimum cycle length)
    final daysSinceLastPeriod =
        symptom.date.difference(profile.lastPeriodStart!).inDays;
    return daysSinceLastPeriod >= 20;
  }

  /// Create a new cycle data entry
  CycleData createCycleData(
    DateTime periodStart,
    DateTime? periodEnd,
    UserCycleProfile profile,
  ) {
    // Calculate cycle length if we have a previous period
    int cycleLength = profile.averageCycleLength;
    if (profile.lastPeriodStart != null) {
      cycleLength = periodStart.difference(profile.lastPeriodStart!).inDays;
    }

    // Calculate period length if we have end date
    int periodLength = profile.averagePeriodLength;
    if (periodEnd != null) {
      periodLength = periodEnd.difference(periodStart).inDays + 1;
    }

    // Detect anomaly if it deviates significantly from average
    final isAnomaly = profile.historicalCycles.isNotEmpty &&
        ((cycleLength - profile.averageCycleLength).abs() > 10 ||
            (periodLength - profile.averagePeriodLength).abs() > 4);

    return CycleData(
      periodStartDate: periodStart,
      periodEndDate: periodEnd,
      cycleLength: cycleLength,
      periodLength: periodLength,
      isAnomaly: isAnomaly,
    );
  }

  /// Update cycle profile with new cycle data and recalculate averages
  UserCycleProfile updateProfileWithNewCycle(
    UserCycleProfile profile,
    CycleData newCycle,
  ) {
    final updatedCycles = [...profile.historicalCycles, newCycle];

    // Calculate new averages
    final newAverageCycleLength =
        CycleCalculator.calculateAverageCycleLength(updatedCycles);
    final newAveragePeriodLength =
        CycleCalculator.calculateAveragePeriodLength(updatedCycles);

    return profile.copyWith(
      historicalCycles: updatedCycles,
      lastPeriodStart: newCycle.periodStartDate,
      averageCycleLength: newAverageCycleLength,
      averagePeriodLength: newAveragePeriodLength,
    );
  }

  /// Detect period end from symptoms
  /// Returns the last date with flow intensity > 0 before a gap of 2+ days
  DateTime? detectPeriodEnd(
    DateTime periodStart,
    List<SymptomLog> allSymptoms,
  ) {
    // Get symptoms after period start, sorted by date
    final periodSymptoms = allSymptoms
        .where((s) =>
            s.date.isAfter(periodStart) || s.date.isAtSameMomentAs(periodStart))
        .where((s) => s.flowIntensity != null && s.flowIntensity! > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (periodSymptoms.isEmpty) return null;

    // Find the last consecutive day with flow
    DateTime? lastFlowDate;
    DateTime? previousDate;

    for (final symptom in periodSymptoms) {
      if (previousDate != null) {
        final gap = symptom.date.difference(previousDate).inDays;
        if (gap > 2) {
          // Gap detected, period ended at previousDate
          return lastFlowDate;
        }
      }
      lastFlowDate = symptom.date;
      previousDate = symptom.date;
    }

    // If we're within 2 days of the last flow, period might still be ongoing
    if (lastFlowDate != null) {
      final daysSinceLastFlow = DateTime.now().difference(lastFlowDate).inDays;
      if (daysSinceLastFlow > 2) {
        return lastFlowDate;
      }
    }

    return null; // Period still ongoing
  }

  /// Process a new symptom log and update cycle data if needed
  UserCycleProfile processSymptomLog(
    SymptomLog symptom,
    UserCycleProfile profile,
    List<SymptomLog> allSymptoms,
  ) {
    // Check if this is a new period start
    if (shouldCreateNewCycle(symptom, profile)) {
      // Try to detect end of previous period
      DateTime? previousPeriodEnd;
      if (profile.lastPeriodStart != null) {
        previousPeriodEnd =
            detectPeriodEnd(profile.lastPeriodStart!, allSymptoms);

        // Update the last cycle in history with end date if detected
        if (previousPeriodEnd != null && profile.historicalCycles.isNotEmpty) {
          final updatedCycles = [...profile.historicalCycles];
          final lastCycleIndex = updatedCycles.length - 1;
          // Recalculate anomaly status now that we have final period length
          final lastCycle = updatedCycles[lastCycleIndex];
          final finalPeriodLength =
              previousPeriodEnd.difference(lastCycle.periodStartDate).inDays +
                  1;
          final isStillAnomaly =
              (lastCycle.cycleLength - profile.averageCycleLength).abs() > 10 ||
                  (finalPeriodLength - profile.averagePeriodLength).abs() > 4;

          updatedCycles[lastCycleIndex] = lastCycle.copyWith(
            periodEndDate: previousPeriodEnd,
            periodLength: finalPeriodLength,
            isAnomaly: isStillAnomaly,
          );

          profile = profile.copyWith(historicalCycles: updatedCycles);
        }
      }

      // Create new cycle
      final newCycle = createCycleData(symptom.date, null, profile);
      return updateProfileWithNewCycle(profile, newCycle);
    }

    return profile;
  }
}
