import 'package:flutter/material.dart';

import '../../../theme/typography.dart';
import '../models/calendar_event.dart';

class AddEventForm extends StatefulWidget {
  final DateTime selectedDate;
  final CalendarEvent? eventToEdit;
  final Function(CalendarEvent) onSave;

  const AddEventForm({
    super.key,
    required this.selectedDate,
    this.eventToEdit,
    required this.onSave,
  });

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _selectedCategory = 'appointment';

  final List<String> _categories = [
    'appointment',
    'task',
    'medication',
    'exercise',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.eventToEdit?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.eventToEdit?.description ?? '');
    _selectedCategory = widget.eventToEdit?.category ?? 'appointment';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final event = CalendarEvent(
      id: widget.eventToEdit?.id ?? DateTime.now().toString(),
      date: widget.selectedDate,
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      category: _selectedCategory,
    );

    widget.onSave(event);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.eventToEdit == null ? 'Add Event' : 'Edit Event',
              style: AppTypography.displayTextTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const Text('Category:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.map((category) {
                return ChoiceChip(
                  label: Text(_formatCategory(category)),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                  widget.eventToEdit == null ? 'Add Event' : 'Update Event'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatCategory(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }
}
