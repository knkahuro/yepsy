import 'package:flutter/material.dart';

import '../../../../theme/typography.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../../tasks/services/task_service.dart';
import '../../notes/services/notes_data_service.dart';
import '../../calendar/services/calendar_data_service.dart';
import '../widgets/trend_graph.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

enum AnalyticsMetric { tasks, mood, symptoms }

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final TaskService _taskService = TaskService();
  final NotesDataService _notesService = NotesDataService();
  final CalendarDataService _calendarService = CalendarDataService();

  Map<DateTime, double> _taskHistory = {}; // Changed to double
  Map<DateTime, double> _moodHistory = {};
  Map<DateTime, double> _symptomHistory = {};

  bool _isLoading = true;
  AnalyticsMetric _selectedMetric = AnalyticsMetric.tasks;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _taskService.init();
      await _notesService.init();
      await _calendarService.init();

      final taskHistory =
          await _taskService.getCompletionRateHistory(7); // Use rate history
      final moodHistory = await _notesService.getMoodHistory(7);
      final symptomHistory = await _calendarService.getSymptomHistory(7);

      if (mounted) {
        setState(() {
          _taskHistory = taskHistory;
          _moodHistory = moodHistory;
          _symptomHistory = symptomHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Non-intrusive error handling
      }
    }
  }

  // --- UI Helpers ---

  String get _currentMessage {
    return 'Mhhh....What do we have here?';
  }

  Map<DateTime, num> get _currentHistory {
    switch (_selectedMetric) {
      case AnalyticsMetric.tasks:
        return _taskHistory;
      case AnalyticsMetric.mood:
        return _moodHistory;
      case AnalyticsMetric.symptoms:
        return _symptomHistory;
    }
  }

  Color get _currentColor {
    // Unified Theme: Always return primary color
    return Theme.of(context).colorScheme.primary;
  }

  String get _metricTitle {
    switch (_selectedMetric) {
      case AnalyticsMetric.tasks:
        return 'ActivityTask Score';
      case AnalyticsMetric.mood:
        return 'Mood Score';
      case AnalyticsMetric.symptoms:
        return 'Health Score';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          title: Text(
            'Analytics',
            style: AppTypography.displayTextTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonLoader.text(height: 120, width: double.infinity),
              const SizedBox(height: 24),
              SkeletonLoader.text(height: 250, width: double.infinity),
            ],
          ),
        ),
      );
    }

    // Calculate Summary logic
    // Tasks: Total count
    // Mood: Average
    // Symptoms: Average non-zero
    String summaryValue = '';

    if (_selectedMetric == AnalyticsMetric.tasks) {
      final values = _taskHistory.values;
      if (values.isEmpty) {
        summaryValue = '0%';
      } else {
        // Calculate average percentage
        final avg = values.reduce((a, b) => a + b) / values.length;
        summaryValue = '${avg.toInt()}%';
      }
    } else if (_selectedMetric == AnalyticsMetric.mood) {
      final values = _moodHistory.values.where((v) => v > 0);
      if (values.isEmpty) {
        summaryValue = '-';
      } else {
        final avg = values.reduce((a, b) => a + b) / values.length;
        summaryValue = '${avg.round()}%'; // Rounded Percentage
      }
    } else {
      // Health Score
      final values = _symptomHistory.values;
      if (values.isEmpty) {
        summaryValue = '100%'; // Default to perfect health
      } else {
        final avg = values.reduce((a, b) => a + b) / values.length;
        summaryValue = '${avg.round()}%'; // Rounded Percentage
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Analytics',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Mascot Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/graph.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MessageBubble(
                    message: _currentMessage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<AnalyticsMetric>(
                segments: const [
                  ButtonSegment(
                    value: AnalyticsMetric.tasks,
                    label: Text('Tasks'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: AnalyticsMetric.mood,
                    label: Text('Mood'),
                    icon: Icon(Icons.mood),
                  ),
                  ButtonSegment(
                    value: AnalyticsMetric.symptoms,
                    label: Text('Health'),
                    icon: Icon(Icons.favorite_border),
                  ),
                ],
                selected: {_selectedMetric},
                onSelectionChanged: (Set<AnalyticsMetric> newSelection) {
                  setState(() {
                    _selectedMetric = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return _currentColor.withValues(alpha: 0.2);
                      }
                      return null;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return _currentColor; // Text color when selected
                      }
                      return Colors.grey[700];
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Trend Graph Card
            Container(
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
                        'Weekly Trend',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Last 7 Days',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TrendGraph(
                    history: _currentHistory,
                    color: _currentColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Summary Card
            // Summary Card (Compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _metricTitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      summaryValue,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
