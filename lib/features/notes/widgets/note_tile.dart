import 'package:flutter/material.dart';

import '../../../../theme/typography.dart';
import '../models/note.dart';

class NoteTile extends StatelessWidget {
  final Note note;

  const NoteTile({
    super.key,
    required this.note,
    required this.onPinTap,
  });

  final VoidCallback onPinTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: note.isPinned
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              note.title,
                              style:
                                  AppTypography.textTheme.titleMedium?.copyWith(
                                color: note.isPinned
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (note.mood != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: note.isPinned
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getMoodEmoji(note.mood!),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note.message,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: note.isPinned
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 30), // Space for pin icon
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onPinTap,
                  child: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: note.isPinned
                        ? Colors.white
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodEmoji(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return '😊';
      case Mood.sad:
        return '😢';
      case Mood.neutral:
        return '😐';
      case Mood.excited:
        return '🤩';
      case Mood.tired:
        return '😴';
    }
  }
}
