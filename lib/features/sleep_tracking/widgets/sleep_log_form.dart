import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/typography.dart';

class SleepLogForm extends StatefulWidget {
  final Function(DateTime bedtime, DateTime wakeTime, int quality) onSave;

  const SleepLogForm({
    super.key,
    required this.onSave,
  });

  @override
  State<SleepLogForm> createState() => _SleepLogFormState();
}

class _SleepLogFormState extends State<SleepLogForm> {
  late DateTime bedtime;
  late DateTime wakeTime;
  late int quality;

  @override
  void initState() {
    super.initState();
    bedtime = DateTime.now().subtract(const Duration(hours: 8));
    wakeTime = DateTime.now();
    quality = 3;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Log Sleep',
            style: AppTypography.displayTextTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Bedtime Picker
          ListTile(
            title: const Text('Bedtime'),
            trailing: Text(DateFormat('h:mm a').format(bedtime)),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(bedtime),
              );
              if (time != null) {
                setState(() {
                  bedtime = DateTime(
                    bedtime.year,
                    bedtime.month,
                    bedtime.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            },
          ),

          // Wake Time Picker
          ListTile(
            title: const Text('Wake Time'),
            trailing: Text(DateFormat('h:mm a').format(wakeTime)),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(wakeTime),
              );
              if (time != null) {
                setState(() {
                  wakeTime = DateTime(
                    wakeTime.year,
                    wakeTime.month,
                    wakeTime.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            },
          ),

          const SizedBox(height: 16),
          const Text('Quality'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = rating <= quality;
              return IconButton(
                onPressed: () => setState(() => quality = rating),
                icon: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await widget.onSave(bedtime, wakeTime, quality);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Log'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
