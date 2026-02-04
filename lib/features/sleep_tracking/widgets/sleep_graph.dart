import 'package:flutter/material.dart';

import '../models/sleep_log.dart';
import 'package:intl/intl.dart';

class SleepGraph extends StatelessWidget {
  final List<SleepLog> recentLogs;
  final double goalHours;

  const SleepGraph({
    super.key,
    required this.recentLogs,
    this.goalHours = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    // Generate last 7 days
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });

    const maxDuration = 12.0;

    return Column(
      children: [
        // Graph Area
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: last7Days.map((date) {
              final log = _getLogForDate(date);
              final duration = log?.durationHours ?? 0;
              final isToday = date.day == now.day && date.month == now.month;

              // Normalize height (cap at maxDuration)
              final normalizedHeight = (duration / maxDuration).clamp(0.0, 1.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Label for duration if > 0
                  if (duration > 0)
                    Text(
                      '${duration.toStringAsFixed(1)}h',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),

                  // Bar
                  Container(
                    width: 12,
                    height: 150 * normalizedHeight + 4, // Min height of 4
                    decoration: BoxDecoration(
                      color: duration >= goalHours
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Day Label
                  Text(
                    DateFormat('E').format(date)[0], // M, T, W...
                    style: TextStyle(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),
        // Goal Line Legend or similar could go here
      ],
    );
  }

  SleepLog? _getLogForDate(DateTime date) {
    try {
      // Find log where wakeTime falls on this date
      return recentLogs.firstWhere((log) {
        // Checking wakeTime seems appropriate for "sleep recorded for that day"
        return log.wakeTime.year == date.year &&
            log.wakeTime.month == date.month &&
            log.wakeTime.day == date.day;
      });
    } catch (_) {
      return null;
    }
  }
}
