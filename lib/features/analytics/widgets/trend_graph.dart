import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrendGraph extends StatelessWidget {
  final Map<DateTime, num> history;
  final int days;
  final Color? color;

  const TrendGraph({
    super.key,
    required this.history,
    this.days = 7,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final themeColor = color ?? Theme.of(context).colorScheme.primary;

    // Sort dates or generate range to ensure order
    final List<DateTime> dateRange = List.generate(days, (index) {
      final d = now.subtract(Duration(days: days - 1 - index));
      return DateTime(d.year, d.month, d.day);
    });

    // Determine max Y for scaling
    double maxVal = 0;
    for (var count in history.values) {
      if (count.toDouble() > maxVal) maxVal = count.toDouble();
    }
    // Min height of 5 or max + padding
    final maxY = maxVal < 5 ? 5.0 : maxVal + (maxVal * 0.2);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dateRange.map((date) {
              final count = (history[date] ?? 0).toDouble();
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              // Normalized height
              final normalizedHeight = (count / maxY).clamp(0.0, 1.0);

              // Format value text (int for whole numbers, 1 decimal for others)
              String valueText = count % 1 == 0
                  ? count.toInt().toString()
                  : count.toStringAsFixed(1);

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Count Label
                    if (count > 0)
                      Text(
                        valueText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 6),

                    // Bar
                    Container(
                      width: 16,
                      height: 150 * normalizedHeight + 4, // Min height visual
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            themeColor,
                            themeColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Day Label
                    Text(
                      DateFormat('E').format(date)[0],
                      style: TextStyle(
                        color: isToday ? themeColor : Colors.grey,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
