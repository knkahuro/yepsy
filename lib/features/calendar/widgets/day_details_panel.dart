import 'package:flutter/material.dart';

import '../../../theme/typography.dart';
import '../models/calendar_event.dart';
import '../models/symptom_log.dart';

class DayDetailsPanel extends StatelessWidget {
  final DateTime selectedDay;
  final List<CalendarEvent> events;
  final List<SymptomLog> symptoms;
  final VoidCallback? onAddEvent;
  final VoidCallback? onAddSymptom;
  final Function(CalendarEvent)? onEditEvent;
  final Function(SymptomLog)? onEditSymptom;
  final Function(CalendarEvent)? onDeleteEvent;
  final Function(SymptomLog)? onDeleteSymptom;

  const DayDetailsPanel({
    super.key,
    required this.selectedDay,
    required this.events,
    required this.symptoms,
    this.onAddEvent,
    this.onAddSymptom,
    this.onEditEvent,
    this.onEditSymptom,
    this.onDeleteEvent,
    this.onDeleteSymptom,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = events.isNotEmpty || symptoms.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(selectedDay),
                style: AppTypography.displayTextTheme.titleMedium,
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary),
                    onPressed: onAddEvent,
                    tooltip: 'Add Event',
                  ),
                  IconButton(
                    icon: Icon(Icons.water_drop_outlined,
                        color: Theme.of(context).colorScheme.secondary),
                    onPressed: onAddSymptom,
                    tooltip: 'Log Symptoms',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No events or symptoms logged for this day',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
            if (events.isNotEmpty) ...[
              _buildSectionHeader(context, 'Events', Icons.event),
              const SizedBox(height: 8),
              ...events.map((event) => _buildEventCard(context, event)),
              const SizedBox(height: 12),
            ],
            if (symptoms.isNotEmpty) ...[
              _buildSectionHeader(context, 'Symptoms', Icons.health_and_safety),
              const SizedBox(height: 8),
              ...symptoms.map((symptom) => _buildSymptomCard(context, symptom)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(_getEventIcon(event.category),
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(event.title),
        subtitle: event.description != null ? Text(event.description!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEditEvent != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => onEditEvent!(event),
              ),
            if (onDeleteEvent != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => onDeleteEvent!(event),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomCard(BuildContext context, SymptomLog symptom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          child: Icon(Icons.health_and_safety,
              color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(symptom.symptoms.map(_formatSymptom).join(', ')),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pain Level: ${symptom.painLevel ?? 'N/A'}'),
            if (symptom.flowIntensity != null)
              Text('Flow: ${symptom.flowIntensity}'),
            if (symptom.notes != null) Text(symptom.notes!),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEditSymptom != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => onEditSymptom!(symptom),
              ),
            if (onDeleteSymptom != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => onDeleteSymptom!(symptom),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(String? category) {
    switch (category) {
      case 'appointment':
        return Icons.event;
      case 'task':
        return Icons.notifications;
      case 'medication':
        return Icons.medication;
      case 'exercise':
        return Icons.fitness_center;
      default:
        return Icons.event_note;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatSymptom(String symptom) {
    return symptom
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
