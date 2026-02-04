import 'package:flutter/material.dart';

import '../../../theme/typography.dart';
import '../models/symptom_log.dart';

class AddSymptomForm extends StatefulWidget {
  final DateTime selectedDate;
  final SymptomLog? symptomToEdit;
  final Function(SymptomLog) onSave;

  const AddSymptomForm({
    super.key,
    required this.selectedDate,
    this.symptomToEdit,
    required this.onSave,
  });

  @override
  State<AddSymptomForm> createState() => _AddSymptomFormState();
}

class _AddSymptomFormState extends State<AddSymptomForm> {
  late TextEditingController _notesController;
  final Set<String> _selectedSymptoms = {};
  int _painLevel = 1;
  int? _flowIntensity;

  final List<String> _availableSymptoms = [
    'cramps',
    'headache',
    'bloating',
    'mood_swings',
    'fatigue',
    'nausea',
    'back_pain',
    'breast_tenderness',
    'acne',
    'insomnia',
  ];

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.symptomToEdit?.notes ?? '');
    if (widget.symptomToEdit != null) {
      _selectedSymptoms.addAll(widget.symptomToEdit!.symptoms);
      _painLevel = widget.symptomToEdit!.painLevel ?? 1;
      _flowIntensity = widget.symptomToEdit!.flowIntensity;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom')),
      );
      return;
    }

    final symptomLog = SymptomLog(
      id: widget.symptomToEdit?.id ?? DateTime.now().toString(),
      date: widget.selectedDate,
      symptoms: _selectedSymptoms.toList(),
      painLevel: _painLevel,
      flowIntensity: _flowIntensity,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onSave(symptomLog);
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
              widget.symptomToEdit == null ? 'Log Symptoms' : 'Edit Symptoms',
              style: AppTypography.displayTextTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text('Symptoms:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableSymptoms.map((symptom) {
                return FilterChip(
                  label: Text(_formatSymptom(symptom)),
                  selected: _selectedSymptoms.contains(symptom),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).colorScheme.secondary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Pain Level: $_painLevel',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _painLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _painLevel.toString(),
              onChanged: (value) {
                setState(() {
                  _painLevel = value.toInt();
                });
              },
              activeColor: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Flow Intensity (Optional):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (_flowIntensity != null)
                  Text('$_flowIntensity',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            Slider(
              value: (_flowIntensity ?? 0).toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              label: _flowIntensity == null || _flowIntensity == 0
                  ? 'None'
                  : _flowIntensity.toString(),
              onChanged: (value) {
                setState(() {
                  _flowIntensity = value.toInt() == 0 ? null : value.toInt();
                });
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.symptomToEdit == null
                  ? 'Log Symptoms'
                  : 'Update Symptoms'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatSymptom(String symptom) {
    return symptom
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
