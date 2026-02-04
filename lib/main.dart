import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'router/app_router.dart';

import 'theme/theme_service.dart';
import 'features/calendar/models/calendar_event.dart';
import 'features/calendar/models/symptom_log.dart';
import 'features/calendar/models/cycle_data.dart';
import 'features/calendar/services/notification_service.dart';
import 'core/database/database_service.dart';
import 'core/services/biometric_service.dart';
import 'features/auth/screens/lock_screen.dart';
import 'features/notes/models/note.dart';
import 'features/meals/models/meal.dart';
import 'features/sleep_tracking/models/sleep_log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database with optimizations and migrations
  await DatabaseService.initialize();

  // Register Hive adapters
  Hive.registerAdapter(CalendarEventAdapter());
  Hive.registerAdapter(SymptomLogAdapter());
  Hive.registerAdapter(CycleDataAdapter());
  Hive.registerAdapter(UserCycleProfileAdapter());

  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(MoodAdapter());
  Hive.registerAdapter(MealAdapter());
  Hive.registerAdapter(SleepLogAdapter());

  MenstrualCycleWidget.init(
    secretKey: 'yepsy_secret_key_value_for_encryption',
    ivKey: 'yepsy_iv_key_val',
  );

  // Load saved theme
  final themeColor = await ThemeService.loadThemeColor(); // Use service

  // Initialize notifications
  await NotificationService().initialize(
    onNotificationClick: (payload) {
      if (payload == 'period_reminder' ||
          payload == 'ovulation_reminder' ||
          payload == 'test') {
        appRouter.go('/calendar');
      }
    },
  );

  runApp(YepsyApp(seedColor: themeColor));
}

class YepsyApp extends StatefulWidget {
  final Color seedColor;

  const YepsyApp({super.key, required this.seedColor});

  @override
  State<YepsyApp> createState() => _YepsyAppState();
}

class _YepsyAppState extends State<YepsyApp> with WidgetsBindingObserver {
  final BiometricService _biometricService = BiometricService();
  bool _isLocked = false;
  bool _shouldShowLock = false;
  DateTime? _backgroundTimestamp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLockState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialLockState() async {
    final biometricEnabled = await _biometricService.isBiometricEnabled();
    if (biometricEnabled) {
      setState(() {
        _shouldShowLock = true;
        _isLocked = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // App went to background - record timestamp
      _backgroundTimestamp = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground - check if grace period exceeded
      if (_backgroundTimestamp != null) {
        final elapsed = DateTime.now().difference(_backgroundTimestamp!);
        if (elapsed > const Duration(seconds: 30)) {
          _lockApp();
        }
        _backgroundTimestamp = null;
      }
    }
  }

  void _lockApp() {
    _biometricService.isBiometricEnabled().then((enabled) {
      if (enabled && mounted) {
        setState(() {
          _shouldShowLock = true;
          _isLocked = true;
        });
      }
    });
  }

  void _unlockApp() {
    setState(() {
      _isLocked = false;
      _shouldShowLock = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show lock screen if locked
    if (_isLocked && _shouldShowLock) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: widget.seedColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: LockScreen(onAuthenticated: _unlockApp),
      );
    }

    return MaterialApp.router(
      title: 'Yepsy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: widget.seedColor),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
