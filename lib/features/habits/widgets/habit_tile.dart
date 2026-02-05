import 'package:flutter/material.dart';

import '../../../../theme/typography.dart';
import '../models/habit.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final Function(bool?)? onToggleCompletion;
  final bool isCompleted;

  const HabitTile({
    super.key,
    required this.habit,
    required this.onEdit,
    this.onDelete,
    this.onToggleCompletion,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor =
        isCompleted ? primaryColor.withValues(alpha: 0.1) : primaryColor;
    final titleColor = isCompleted ? primaryColor : Colors.white;
    final descriptionColor = isCompleted
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.9);
    final iconColor =
        isCompleted ? primaryColor.withValues(alpha: 0.7) : Colors.white;
    final chipBackgroundColor = isCompleted
        ? primaryColor.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.2);
    final chipTextColor = isCompleted ? primaryColor : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Habit Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              habit.title,
                              style:
                                  AppTypography.textTheme.titleMedium?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Category Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: chipBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              habit.category,
                              style: TextStyle(
                                color: chipTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        color: iconColor,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  habit.description,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: descriptionColor,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Footer: Reminder + Rating
                Row(
                  children: [
                    if (habit.reminderTime != null) ...[
                      Icon(Icons.access_alarm,
                          size: 14, color: descriptionColor),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.reminderTime!.hour.toString().padLeft(2, '0')}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: descriptionColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Frequency
                    if (habit.frequency.isNotEmpty) ...[
                      Icon(Icons.repeat, size: 14, color: descriptionColor),
                      const SizedBox(width: 4),
                      Text(
                        _getFrequencyText(habit.frequency),
                        style: TextStyle(
                          color: descriptionColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Completion Checkbox
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: isCompleted,
              onChanged: onToggleCompletion,
              shape: const CircleBorder(),
              side: BorderSide(
                color: isCompleted ? primaryColor : Colors.white,
                width: 2,
              ),
              checkColor: isCompleted ? Colors.white : primaryColor,
              activeColor: isCompleted ? primaryColor : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyText(List<int> frequency) {
    if (frequency.length == 7) return 'Every day';
    if (frequency.isEmpty) return 'No days selected';
    if (frequency.length == 2 &&
        frequency.contains(6) &&
        frequency.contains(7)) {
      return 'Weekends';
    }
    if (frequency.length == 5 &&
        !frequency.contains(6) &&
        !frequency.contains(7)) {
      return 'Weekdays';
    }

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // frequency is 1-based (Mon=1, Sun=7)
    final selectedDays = frequency
        .where((day) => day >= 1 && day <= 7)
        .map((day) => weekdays[day - 1])
        .toList();

    return selectedDays.join(', ');
  }
}
