import 'package:flutter/material.dart';

import '../../../../theme/typography.dart';

class SleepInsightsWidget extends StatelessWidget {
  final Map<String, dynamic> insights;

  const SleepInsightsWidget({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final avgQuality = insights['avgQuality'] as double? ?? 0.0;
    final totalLogs = insights['totalLogs'] as int? ?? 0;
    final bestSleep = insights['bestSleepDuration'] as double? ?? 0.0;

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
                'Sleep Insights',
                style: AppTypography.displayTextTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            Icons.star,
            'Average Sleep Quality',
            '${avgQuality.toStringAsFixed(1)} / 5',
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            Icons.list_alt,
            'Total Logs',
            '$totalLogs entries',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            Icons.emoji_events,
            'Best Night Sleep',
            '${bestSleep.toStringAsFixed(1)} hours',
            Colors.purple,
          ),
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
}
