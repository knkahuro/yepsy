import 'dart:math';
import 'package:flutter/material.dart';

import '../../../theme/typography.dart';
import '../models/cycle_data.dart';
import '../utils/cycle_calculator.dart';

class CycleInsightsCard extends StatelessWidget {
  final UserCycleProfile cycleProfile;

  const CycleInsightsCard({
    super.key,
    required this.cycleProfile,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _calculateInsights();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cycle Insights',
                style: AppTypography.displayTextTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            Icons.calendar_today,
            'Next Period',
            insights['nextPeriod'] ?? 'Not enough data',
            Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            Icons.timeline,
            'Average Cycle',
            '${cycleProfile.averageCycleLength} days',
            Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            Icons.favorite,
            'Cycle Regularity',
            insights['regularity'] ?? 'Building data...',
            _getRegularityColor(insights['regularityScore'] as int? ?? 0),
          ),
          if (insights['confidence'] != null) ...[
            const SizedBox(height: 12),
            _buildConfidenceIndicator(insights['confidence'] as String),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator(String confidence) {
    Color color;
    IconData icon;

    switch (confidence.toLowerCase()) {
      case 'high':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.info;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$confidence Prediction Confidence',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateInsights() {
    final insights = <String, dynamic>{};

    // Calculate next period
    if (cycleProfile.lastPeriodStart != null) {
      final nextPeriod = CycleCalculator.predictNextPeriod(
        cycleProfile.lastPeriodStart!,
        cycleProfile.averageCycleLength,
      );
      final daysUntil = nextPeriod.difference(DateTime.now()).inDays;

      if (daysUntil > 0) {
        insights['nextPeriod'] = 'In $daysUntil days';
      } else if (daysUntil == 0) {
        insights['nextPeriod'] = 'Today';
      } else {
        insights['nextPeriod'] = '${daysUntil.abs()} days overdue';
      }
    }

    // Calculate regularity
    if (cycleProfile.historicalCycles.length >= 3) {
      final cycleLengths = <int>[];
      for (int i = 1; i < cycleProfile.historicalCycles.length; i++) {
        final length = cycleProfile.historicalCycles[i].periodStartDate
            .difference(cycleProfile.historicalCycles[i - 1].periodStartDate)
            .inDays;
        cycleLengths.add(length);
      }

      final avg = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
      final variance = cycleLengths
              .map((l) => (l - avg) * (l - avg))
              .reduce((a, b) => a + b) /
          cycleLengths.length;
      final stdDev = sqrt(variance);

      int regularityScore;
      String regularityText;

      if (stdDev < 2) {
        regularityScore = 3;
        regularityText = 'Very Regular';
      } else if (stdDev < 4) {
        regularityScore = 2;
        regularityText = 'Regular';
      } else if (stdDev < 7) {
        regularityScore = 1;
        regularityText = 'Somewhat Irregular';
      } else {
        regularityScore = 0;
        regularityText = 'Irregular';
      }

      insights['regularity'] = regularityText;
      insights['regularityScore'] = regularityScore;
    }

    // Calculate confidence
    final cycleCount = cycleProfile.historicalCycles.length;
    if (cycleCount >= 6) {
      insights['confidence'] = 'High';
    } else if (cycleCount >= 3) {
      insights['confidence'] = 'Medium';
    } else if (cycleCount >= 1) {
      insights['confidence'] = 'Low';
    }

    return insights;
  }

  Color _getRegularityColor(int score) {
    switch (score) {
      case 3:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 1:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
