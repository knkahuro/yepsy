import 'package:flutter/material.dart';

import '../../../theme/typography.dart';
import '../models/calendar_event.dart';
import '../models/symptom_log.dart';

class DayDetailsPage extends StatelessWidget {
  final DateTime selectedDay;
  final List<CalendarEvent> events;
  final List<SymptomLog> symptoms;
  final VoidCallback onAddEvent;
  final VoidCallback onAddSymptom;
  final Function(CalendarEvent) onEditEvent;
  final Function(SymptomLog) onEditSymptom;
  final Function(CalendarEvent) onDeleteEvent;
  final Function(SymptomLog) onDeleteSymptom;

  const DayDetailsPage({
    super.key,
    required this.selectedDay,
    required this.events,
    required this.symptoms,
    required this.onAddEvent,
    required this.onAddSymptom,
    required this.onEditEvent,
    required this.onEditSymptom,
    required this.onDeleteEvent,
    required this.onDeleteSymptom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _formatDate(selectedDay),
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Events Section
            if (events.isNotEmpty) ...[
              _buildSectionHeader(
                  'Events', Icons.event, Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              ...events.map((event) => _buildEventCard(context, event)),
              const SizedBox(height: 24),
            ],

            // Symptoms Section
            if (symptoms.isNotEmpty) ...[
              _buildSectionHeader('Symptoms', Icons.water_drop,
                  Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 12),
              ...symptoms.map((symptom) => _buildSymptomCard(context, symptom)),
              const SizedBox(height: 24),
            ],

            // Empty State
            if (events.isEmpty && symptoms.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events or symptoms logged',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the icons above to add',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Data'),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.event,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Add Event'),
              onTap: () {
                Navigator.pop(context);
                onAddEvent();
              },
            ),
            ListTile(
              leading: Icon(Icons.water_drop,
                  color: Theme.of(context).colorScheme.secondary),
              title: const Text('Log Symptoms'),
              onTap: () {
                Navigator.pop(context);
                onAddSymptom();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTypography.displayTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => onEditEvent(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (event.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (event.category != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.category!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(
                  context,
                  'Delete Event',
                  'Are you sure you want to delete this event?',
                  () => onDeleteEvent(event),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomCard(BuildContext context, SymptomLog symptom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => onEditSymptom(symptom),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: symptom.symptoms.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatSymptom(s),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (symptom.painLevel != null ||
                        symptom.flowIntensity != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (symptom.painLevel != null)
                            _buildIndicator(
                                'Pain', symptom.painLevel!, Colors.orange),
                          if (symptom.painLevel != null &&
                              symptom.flowIntensity != null)
                            const SizedBox(width: 12),
                          if (symptom.flowIntensity != null)
                            _buildIndicator('Flow', symptom.flowIntensity!,
                                Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ],
                    if (symptom.notes != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        symptom.notes!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(
                  context,
                  'Delete Symptom',
                  'Are you sure you want to delete this symptom log?',
                  () => onDeleteSymptom(symptom),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(String label, int level, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        ...List.generate(5, (index) {
          return Icon(
            index < level ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: index < level ? color : Colors.grey[300],
          );
        }),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
              Navigator.pop(context); // Close day details page
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
