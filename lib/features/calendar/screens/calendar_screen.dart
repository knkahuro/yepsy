import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../core/services/onboarding_service.dart';

import '../../../../theme/typography.dart';
import '../../../shared/widgets/message_bubble.dart';
import '../models/calendar_event.dart';
import '../models/symptom_log.dart';
import '../models/cycle_data.dart';
import '../widgets/add_event_form.dart';
import '../widgets/add_symptom_form.dart';
import '../widgets/cycle_insights_card.dart';
import '../utils/cycle_calculator.dart';
import '../services/calendar_data_service.dart';
import '../services/cycle_learning_service.dart';

import '../../../shared/widgets/skeleton_loader.dart';

// Global key for accessing CalendarScreen state from anywhere
final GlobalKey<State<CalendarScreen>> calendarScreenKey =
    GlobalKey<State<CalendarScreen>>();

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  // Public static method to force tutorial check
  static void forceTutorialCheck() {
    final state = calendarScreenKey.currentState;
    if (state is _CalendarScreenState) {
      state.forceTutorialCheck();
    }
  }

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Services
  final CalendarDataService _dataService = CalendarDataService();
  final CycleLearningService _learningService = CycleLearningService();

  // Data storage
  List<CalendarEvent> _events = [];
  List<SymptomLog> _symptoms = [];
  UserCycleProfile _cycleProfile = UserCycleProfile();
  bool _isLoading = true;

  // Tutorial Keys
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _legendKey = GlobalKey();
  final OnboardingService _onboardingService = OnboardingService();
  late TutorialCoachMark tutorialCoachMark;

  bool _showPeriods = false;
  bool _showSymptoms = false;
  bool _showFertileWindow = false;
  bool _showOvulation = false;

  // Track last tutorial check to avoid redundant checks
  DateTime? _lastTutorialCheck;

  bool get _allTogglesOff =>
      !_showPeriods && !_showSymptoms && !_showFertileWindow && !_showOvulation;

  @override
  void initState() {
    super.initState();
    _loadFilterStates();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check tutorial every time the widget becomes visible, but throttle to once per 2 seconds
    final now = DateTime.now();
    if (_lastTutorialCheck == null ||
        now.difference(_lastTutorialCheck!).inSeconds > 2) {
      _lastTutorialCheck = now;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkTutorial();
      });
    }
  }

  Future<void> _checkTutorial() async {
    debugPrint('🎓 CalendarScreen: Checking tutorial status...');
    final isCompleted = await _onboardingService.isTutorialCompleted();
    debugPrint('🎓 CalendarScreen: Tutorial completed = $isCompleted');
    if (!isCompleted) {
      debugPrint('🎓 CalendarScreen: Showing tutorial...');
      _showTutorial();
    } else {
      debugPrint('🎓 CalendarScreen: Tutorial already completed, skipping');
    }
  }

  void _showTutorial() {
    debugPrint('🎓 CalendarScreen: Creating tutorial coach mark...');
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Theme.of(context).colorScheme.primary,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        debugPrint('🎓 CalendarScreen: Tutorial finished');
        _onboardingService.completeTutorial();
      },
      onSkip: () {
        debugPrint('🎓 CalendarScreen: Tutorial skipped');
        _onboardingService.completeTutorial();
        return true;
      },
    );
    debugPrint('🎓 CalendarScreen: Showing tutorial coach mark...');
    tutorialCoachMark.show(context: context);
  }

  // Public method to force tutorial check (can be called from anywhere)
  void forceTutorialCheck() {
    debugPrint('🎓 CalendarScreen: Force tutorial check requested');
    _checkTutorial();
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];

    targets.add(
      TargetFocus(
        identify: "calendar",
        keyTarget: _calendarKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Cycle View",
                    style: AppTypography.displayTextTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "The calendar shows your tracked data. Tap on any day to see details or add new entries.",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "legend",
        keyTarget: _legendKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Filters & Legend",
                    style: AppTypography.displayTextTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Toggle filters to show or hide symbols on the calendar. This helps you focus on specific patterns.",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }

  // Load filter states from shared preferences
  Future<void> _loadFilterStates() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user has ever manually set preferences
    final hasSetPreferences =
        prefs.getBool('has_set_filter_preferences') ?? false;

    if (hasSetPreferences) {
      // User has manually toggled filters, use their saved preferences
      if (mounted) {
        setState(() {
          _showPeriods = prefs.getBool('show_periods') ?? false;
          _showSymptoms = prefs.getBool('show_symptoms') ?? false;
          _showFertileWindow = prefs.getBool('show_fertile_window') ?? false;
          _showOvulation = prefs.getBool('show_ovulation') ?? false;
        });
      }
    } else {
      // First time or no manual toggles - auto-enable if cycle data exists
      if (mounted) {
        setState(() {
          _showPeriods = false;
          _showSymptoms = false;
          _showFertileWindow = false;
          _showOvulation = false;
        });
      }
    }
  }

  // Save filter state
  Future<void> _saveFilterState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    // Mark that user has manually set preferences
    await prefs.setBool('has_set_filter_preferences', true);
  }

  Future<void> _loadData() async {
    try {
      await _dataService.init();
      final events = await _dataService.getAllEvents();
      final symptoms = await _dataService.getAllSymptoms();
      final cycleProfile = await _dataService.getOrCreateCycleProfile();

      if (mounted) {
        setState(() {
          _events = events;
          _symptoms = symptoms;
          _cycleProfile = cycleProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load calendar data: $e')),
        );
      }
    }

    // Load filter states after cycle data is available
    await _loadFilterStates();
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
            'Calendar',
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
              // Mascot Skeleton
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader.square(size: 120),
                  const SizedBox(width: 16),
                  Expanded(child: SkeletonLoader.text(height: 100)),
                ],
              ),
              const SizedBox(height: 20),
              // Calendar Skeleton (Table)
              Container(
                height: 380,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLoader.circle(size: 30),
                        SkeletonLoader.text(width: 150, height: 20),
                        SkeletonLoader.circle(size: 30),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                        child: SkeletonLoader.text(height: double.infinity)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Insights Skeleton
              const SkeletonCard(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Calendar',
          style: AppTypography.displayTextTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_calendarFormat == CalendarFormat.month) {
                  _calendarFormat = CalendarFormat.twoWeeks;
                } else {
                  _calendarFormat = CalendarFormat.month;
                }
              });
            },
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.calendar_view_day
                  : Icons.calendar_view_month,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Mascot Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/raincheck.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: MessageBubble(
                      message: 'Raincheck..1,2,3',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Calendar
              Container(
                key: _calendarKey,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  calendarFormat:
                      _allTogglesOff ? CalendarFormat.month : _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _showAddOptions(selectedDay);
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: (day) {
                    return [
                      ..._getEventsForDay(day),
                      ..._getSymptomsForDay(day)
                    ];
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      return _buildDayMarkers(day, events);
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      final cell = _buildDayCell(day);
                      return GestureDetector(
                        onDoubleTap: () => _openDayDetailsPage(day),
                        child: cell,
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final cell = _buildDayCell(day, isToday: true);
                      return GestureDetector(
                        onDoubleTap: () => _openDayDetailsPage(day),
                        child: cell,
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      final cell = _buildDayCell(day);
                      return GestureDetector(
                        onDoubleTap: () => _openDayDetailsPage(day),
                        child: cell,
                      );
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2),
                        bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2),
                        left: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2),
                        right: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Interactive Legend
              Wrap(
                key: _legendKey,
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildLegendItem(
                      'Period', Theme.of(context).colorScheme.primary),
                  _buildLegendItem(
                      'Symptoms', Theme.of(context).colorScheme.secondary),
                  _buildLegendItem('Fertile Window', Colors.blue.shade100),
                  _buildLegendItem('Ovulation', Colors.purple),
                ],
              ),
              const SizedBox(height: 16),
              // Cycle Insights Card
              if (!_allTogglesOff)
                CycleInsightsCard(cycleProfile: _cycleProfile),
            ],
          ),
        ),
      ),
    );
  }

  // Handle pull to refresh
  Future<void> _handleRefresh() async {
    final updatedProfile = await _dataService.getOrCreateCycleProfile();
    if (mounted) {
      setState(() {
        _cycleProfile = updatedProfile;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Open day details page
  void _openDayDetailsPage(DateTime day) {
    context.go('/calendar/details', extra: {
      'selectedDay': day,
      'events': _getEventsForDay(day),
      'symptoms': _getSymptomsForDay(day),
      'onAddEvent': () {
        context.pop(); // Close details
        _showAddEventForm(day);
      },
      'onAddSymptom': () {
        context.pop(); // Close details
        _showAddSymptomForm(day);
      },
      'onEditEvent': (CalendarEvent event) {
        context.pop(); // Close details
        _showAddEventForm(day, event: event);
      },
      'onEditSymptom': (SymptomLog symptom) {
        context.pop(); // Close details
        _showAddSymptomForm(day, symptom: symptom);
      },
      'onDeleteEvent': (CalendarEvent event) => _deleteEvent(event),
      'onDeleteSymptom': (SymptomLog symptom) => _deleteSymptom(symptom),
    });
  }

  // Get events for a specific day
  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) => isSameDay(event.date, day)).toList();
  }

  // Get symptoms for a specific day
  List<SymptomLog> _getSymptomsForDay(DateTime day) {
    return _symptoms.where((symptom) => isSameDay(symptom.date, day)).toList();
  }

  // Show add event form
  void _showAddEventForm(DateTime date, {CalendarEvent? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddEventForm(
        selectedDate: date,
        eventToEdit: event,
        onSave: (newEvent) async {
          if (event != null) {
            final index = _events.indexWhere((e) => e.id == event.id);
            if (index != -1) {
              _events[index] = newEvent;
            }
          } else {
            _events.add(newEvent);
          }
          await _dataService.saveEvent(newEvent);
          // Flip calendar to event date
          setState(() {
            _focusedDay = newEvent.date;
            _selectedDay = newEvent.date;
          });
        },
      ),
    );
  }

  // Show add symptom form
  void _showAddSymptomForm(DateTime date, {SymptomLog? symptom}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddSymptomForm(
        selectedDate: date,
        symptomToEdit: symptom,
        onSave: (newSymptom) async {
          if (symptom != null) {
            final index = _symptoms.indexWhere((s) => s.id == symptom.id);
            if (index != -1) {
              _symptoms[index] = newSymptom;
            }
          } else {
            _symptoms.add(newSymptom);
          }
          await _dataService.saveSymptom(newSymptom);

          // Trigger adaptive learning
          final updatedProfile = _learningService.processSymptomLog(
            newSymptom,
            _cycleProfile,
            _symptoms,
          );
          if (updatedProfile != _cycleProfile) {
            _cycleProfile = updatedProfile;
            await _dataService.saveCycleProfile(_cycleProfile);
          }

          setState(() {});
        },
      ),
    );
  }

  // Delete event
  void _deleteEvent(CalendarEvent event) async {
    _events.removeWhere((e) => e.id == event.id);
    await _dataService.deleteEvent(event.id);
    if (mounted) setState(() {});
  }

  // Delete symptom
  void _deleteSymptom(SymptomLog symptom) async {
    _symptoms.removeWhere((s) => s.id == symptom.id);
    await _dataService.deleteSymptom(symptom.id);
    if (mounted) setState(() {});
  }

  // Build custom day cell with period tracking colors
  Widget? _buildDayCell(DateTime day, {bool isToday = false}) {
    final isPeriodDay = _isPeriodDay(day);
    final isFertileDay = _isFertileDay(day);
    final isPredictedPeriod = _isPredictedPeriodDay(day);

    Color? backgroundColor;
    Color? textColor;
    BoxBorder? border;

    // Apply period/fertile colors only if filters are enabled
    if (_showPeriods) {
      if (isPeriodDay) {
        backgroundColor =
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
        textColor = Theme.of(context).colorScheme.primary;
      } else if (isPredictedPeriod) {
        backgroundColor =
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
        textColor =
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);
      }
    }

    if (_showFertileWindow &&
        isFertileDay &&
        !isPeriodDay &&
        !isPredictedPeriod) {
      backgroundColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue.shade700;
    }

    // Add border for today's date
    if (isToday) {
      border = Border(
        top: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        bottom:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        left:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        right:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      );
    }

    // Fade out past dates
    if (textColor == null &&
        day.isBefore(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
      textColor = Colors.grey.withValues(alpha: 0.5);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: border,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Build day markers for events and symptoms
  Widget _buildDayMarkers(DateTime day, List<dynamic> events) {
    final hasEvents = events.any((e) => e is CalendarEvent);
    final hasSymptoms = events.any((e) => e is SymptomLog);

    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasEvents)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          if (hasSymptoms && _showSymptoms)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  // Check if day is a period day
  bool _isPeriodDay(DateTime day) {
    if (_cycleProfile.lastPeriodStart == null) return false;

    final daysSinceLastPeriod =
        day.difference(_cycleProfile.lastPeriodStart!).inDays;
    return daysSinceLastPeriod >= 0 &&
        daysSinceLastPeriod < _cycleProfile.averagePeriodLength;
  }

  // Check if day is in fertile window
  bool _isFertileDay(DateTime day) {
    if (_cycleProfile.lastPeriodStart == null) return false;

    return CycleCalculator.isInFertileWindow(
      day,
      _cycleProfile.lastPeriodStart!,
      _cycleProfile.averageCycleLength,
    );
  }

  // Check if day is predicted period
  bool _isPredictedPeriodDay(DateTime day) {
    if (_cycleProfile.lastPeriodStart == null) return false;

    return CycleCalculator.isPredictedPeriodDay(
      day,
      _cycleProfile.lastPeriodStart!,
      _cycleProfile.averageCycleLength,
      _cycleProfile.averagePeriodLength,
    );
  }

  // Build interactive legend item
  Widget _buildLegendItem(String label, Color color) {
    bool isActive = true;
    VoidCallback? onTap;

    if (label == 'Period') {
      isActive = _showPeriods;
      onTap = () {
        setState(() => _showPeriods = !_showPeriods);
        _saveFilterState('show_periods', _showPeriods);
      };
    } else if (label == 'Symptoms') {
      isActive = _showSymptoms;
      onTap = () {
        setState(() => _showSymptoms = !_showSymptoms);
        _saveFilterState('show_symptoms', _showSymptoms);
      };
    } else if (label == 'Fertile Window') {
      isActive = _showFertileWindow;
      onTap = () {
        setState(() => _showFertileWindow = !_showFertileWindow);
        _saveFilterState('show_fertile_window', _showFertileWindow);
      };
    } else if (label == 'Ovulation') {
      isActive = _showOvulation;
      onTap = () {
        setState(() => _showOvulation = !_showOvulation);
        _saveFilterState('show_ovulation', _showOvulation);
      };
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onTap != null)
                Icon(
                  isActive ? Icons.visibility : Icons.visibility_off,
                  size: 14,
                  color: isActive ? color : Colors.grey,
                ),
              if (onTap != null) const SizedBox(width: 6),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions(DateTime date) {
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
                _showAddEventForm(date);
              },
            ),
            ListTile(
              leading: Icon(Icons.water_drop,
                  color: Theme.of(context).colorScheme.secondary),
              title: const Text('Log Symptoms'),
              onTap: () {
                Navigator.pop(context);
                _showAddSymptomForm(date);
              },
            ),
          ],
        ),
      ),
    );
  }
}
