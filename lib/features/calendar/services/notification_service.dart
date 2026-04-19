import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle_data.dart';
import 'package:yepsy/features/tasks/models/task.dart';
import '../utils/cycle_calculator.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/streak_service.dart';

// Top-level background handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // logic to handle action
  NotificationService().handleBackgroundAction(notificationResponse);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String actionSnooze = 'snooze_action';
  static const String actionComplete = 'complete_action';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Initialize notification service
  Future<void> initialize({Function(String?)? onNotificationClick}) async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == actionSnooze ||
            response.actionId == actionComplete) {
          handleBackgroundAction(response);
        } else {
          onNotificationClick?.call(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _initialized = true;
  }

  // Request permissions (Android & iOS)
  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted =
          await androidImplementation.requestNotificationsPermission();

      // Try to request exact alarm permission if available (Android 12+)
      await androidImplementation.requestExactAlarmsPermission();

      if (granted != null) {
        return granted;
      }
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted != null) {
        return granted;
      }
    }

    return true; // Use defaults/implicit permission for other cases
  }

  // Schedule period task
  Future<void> schedulePeriodTask(
    UserCycleProfile cycleProfile,
    int daysBeforePeriod,
  ) async {
    if (cycleProfile.lastPeriodStart == null) return;

    // Calculate next period date
    final nextPeriodDate = cycleProfile.lastPeriodStart!.add(
      Duration(days: cycleProfile.averageCycleLength),
    );

    // Calculate notification date
    final notificationDate = nextPeriodDate.subtract(
      Duration(days: daysBeforePeriod),
    );

    // Only schedule if in the future
    if (notificationDate.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(
      DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        9, // 9 AM
        0,
      ),
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'period_tasks',
      'Period Tasks',
      channelDescription: 'Notifications for upcoming period',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        0, // Notification ID
        'Period ActivityTask',
        'Your period is expected in $daysBeforePeriod ${daysBeforePeriod == 1 ? 'day' : 'days'}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'period_task',
      );
    } catch (e) {
      // Fallback to inexact if permission denied
      await _notifications.zonedSchedule(
        0,
        'Period ActivityTask',
        'Your period is expected in $daysBeforePeriod ${daysBeforePeriod == 1 ? 'day' : 'days'}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'period_task',
      );
    }
  }

  // Schedule ovulation task
  Future<void> scheduleOvulationTask(UserCycleProfile cycleProfile) async {
    if (cycleProfile.lastPeriodStart == null) return;

    // Calculate ovulation date
    final ovulationDay = CycleCalculator.getOvulationDay(
      cycleProfile.lastPeriodStart!,
      cycleProfile.averageCycleLength,
    );

    // Schedule notification 1 day before ovulation
    final notificationDate = ovulationDay.subtract(const Duration(days: 1));

    // Only schedule if in the future
    if (notificationDate.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(
      DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        9, // 9 AM
        0,
      ),
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'ovulation_tasks',
      'Ovulation Tasks',
      channelDescription: 'Notifications for fertile window',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        1, // Notification ID
        'Fertile Window',
        'You are entering your fertile window tomorrow',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'ovulation_task',
      );
    } catch (e) {
      await _notifications.zonedSchedule(
        1,
        'Fertile Window',
        'You are entering your fertile window tomorrow',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'ovulation_task',
      );
    }
  }

  // Schedule daily log task
  Future<void> scheduleDailyLogTask() async {
    final streakService = StreakService();
    final streak = await streakService.calculateCurrentStreak();

    // Check if user already logged today
    // Note: calculateCurrentStreak returns >= 1 if logged today
    // We want to remind at 8 PM if not logged yet.

    final now = DateTime.now();
    final scheduledDate = tz.TZDateTime.from(
      DateTime(now.year, now.month, now.day, 20, 0), // 8 PM
      tz.local,
    );

    // If 8 PM already passed today, schedule for tomorrow
    var finalScheduledDate = scheduledDate;
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      finalScheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_tasks',
      'Daily Tasks',
      channelDescription: 'ActivityTask to log your health data',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        2, // Notification ID
        streak > 0 ? 'Keep your streak alive!' : 'Daily Check-in',
        streak > 0
            ? 'You have a $streak day streak! Log your logs today to keep it going.'
            : 'Take a moment to log your mood, symptoms or tasks today.',
        finalScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: 'daily_log_task',
      );
    } catch (e) {
      await _notifications.zonedSchedule(
        2,
        streak > 0 ? 'Keep your streak alive!' : 'Daily Check-in',
        streak > 0
            ? 'You have a $streak day streak! Log your logs today to keep it going.'
            : 'Take a moment to log your mood, symptoms or tasks today.',
        finalScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_log_task',
      );
    }
  }

  // Check and notify streak milestone
  Future<void> checkAndNotifyStreakMilestone() async {
    final streakService = StreakService();
    final streak = await streakService.calculateCurrentStreak();

    final milestones = [3, 7, 14, 30, 50, 100];
    if (!milestones.contains(streak)) return;

    // Check if we already notified for this streak
    final prefs = await SharedPreferences.getInstance();
    final lastNotified = prefs.getInt('last_notified_streak') ?? 0;
    if (lastNotified == streak) return;

    const androidDetails = AndroidNotificationDetails(
      'milestone_notifications',
      'Milestone Notifications',
      channelDescription: 'Celebrations for reaching streak milestones',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      3, // Notification ID
      'Streak Milestone Reached!',
      'Incredible! You\'ve reached a $streak day streak on Yepsy! 🎉',
      details,
      payload: 'streak_milestone',
    );

    // Save that we notified for this milestone
    await prefs.setInt('last_notified_streak', streak);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Show immediate test notification
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Test Notification',
      'Notifications are working correctly!',
      details,
      payload: 'test',
    );
  }

  // Get notification preferences
  static Future<Map<String, dynamic>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'periodTasksEnabled':
          prefs.getBool('period_tasks_enabled') ?? false,
      'ovulationTasksEnabled':
          prefs.getBool('ovulation_tasks_enabled') ?? false,
      'taskDaysBefore': prefs.getInt('task_days_before') ?? 2,
    };
  }

  // Save notification preferences
  // Get notification ID from string UID (stable across restarts)
  int _getNotificationId(String id) {
    int hash = 0;
    for (int i = 0; i < id.length; i++) {
      hash = (31 * hash + id.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  // Schedule task task
  Future<void> scheduleTaskTask(ActivityTask task) async {
    if (task.taskTime == null) return;

    final now = DateTime.now();
    // Use the task time's hour and minute
    var scheduledDate = tz.TZDateTime.from(
      DateTime(
        now.year,
        now.month,
        now.day,
        task.taskTime!.hour,
        task.taskTime!.minute,
      ),
      tz.local,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'task_tasks',
      'ActivityTask Tasks',
      channelDescription: 'Tasks for your tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      actions: [
        AndroidNotificationAction(actionSnooze, 'Snooze 10m'),
        AndroidNotificationAction(actionComplete, 'Mark Completed'),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier:
          'task_actions', // Needs setup in AppDelegate for iOS actions usually
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use stable ID for unique notification ID
    final notificationId = _getNotificationId(task.id);

    try {
      await _notifications.zonedSchedule(
        notificationId,
        'Time for ${task.title}',
        task.description.isNotEmpty
            ? task.description
            : 'Don\'t forget your task!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: 'task_${task.id}',
      );
    } catch (e) {
      await _notifications.zonedSchedule(
        notificationId,
        'Time for ${task.title}',
        task.description.isNotEmpty
            ? task.description
            : 'Don\'t forget your task!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'task_${task.id}',
      );
    }
  }

  // Cancel task task
  Future<void> cancelTaskTask(String taskId) async {
    await _notifications.cancel(_getNotificationId(taskId));
  }

  static Future<void> savePreferences({
    bool? periodTasksEnabled,
    bool? ovulationTasksEnabled,
    int? taskDaysBefore,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (periodTasksEnabled != null) {
      await prefs.setBool('period_tasks_enabled', periodTasksEnabled);
    }

    if (ovulationTasksEnabled != null) {
      await prefs.setBool(
          'ovulation_tasks_enabled', ovulationTasksEnabled);
    }

    if (taskDaysBefore != null) {
      await prefs.setInt('task_days_before', taskDaysBefore);
    }
  }

  // Handle background actions
  Future<void> handleBackgroundAction(NotificationResponse response) async {
    try {
      debugPrint(
          '[Notification] Background Action received: ${response.actionId}');

      // Ensure timezones are initialized for this isolate
      tz.initializeTimeZones();

      // 1. IMPROVE RESPONSIVENESS: Handle notification dismissal/reschedule IMMEDIATELY
      if (response.id != null) {
        if (response.actionId == actionComplete) {
          debugPrint('[Notification] Immediate cancel for Completion');
          await _notifications.cancel(response.id!);
        } else if (response.actionId == actionSnooze) {
          debugPrint('[Notification] Immediate reschedule for Snooze');

          final now = tz.TZDateTime.now(tz.local);
          final scheduledDate = now.add(const Duration(minutes: 10));

          const androidDetails = AndroidNotificationDetails(
            'task_tasks',
            'ActivityTask Tasks',
            channelDescription: 'Tasks for your tasks',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            actions: [
              AndroidNotificationAction(actionSnooze, 'Snooze 10m'),
              AndroidNotificationAction(actionComplete, 'Mark Completed'),
            ],
          );
          const iosDetails = DarwinNotificationDetails();
          const details =
              NotificationDetails(android: androidDetails, iOS: iosDetails);

          await _notifications.zonedSchedule(
            response.id!,
            'ActivityTask ActivityTask (Snoozed)',
            'Time to complete your task!',
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: response.payload,
          );
        }
      }

      // 2. DATA WORK: Perform the actual logic in background
      if (response.payload == null) return;

      // Parse payload "task_ID"
      final payloadParts = response.payload!.split('_');
      if (payloadParts.length < 2 || payloadParts[0] != 'task') return;
      final taskId = payloadParts.sublist(1).join('_');

      if (response.actionId == actionComplete) {
        debugPrint('[Notification] Beginning Data Update isolate tasks');

        // Ensure plugin is initialized for this isolate if we need more plugin calls
        const androidSettings =
            AndroidInitializationSettings('@mipmap/launcher_icon');
        const iosSettings = DarwinInitializationSettings();
        const initSettings =
            InitializationSettings(android: androidSettings, iOS: iosSettings);
        await _notifications.initialize(initSettings);

        await _initializeMinimalDataLayer();
        await _markTaskComplete(taskId);
      }
    } catch (e, stack) {
      debugPrint('[Notification] ERROR in background action: $e\n$stack');
    }
  }

  Future<void> _initializeMinimalDataLayer() async {
    try {
      debugPrint('[Notification] Initializing Minimal Data Layer');
      WidgetsFlutterBinding.ensureInitialized();

      // Register adapters manually if needed for background isolate
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ActivityTaskAdapter());
      }

      await DatabaseService.initialize();
      debugPrint('[Notification] Data Layer Ready');
    } catch (e) {
      debugPrint('[Notification] Data Layer Initialization FAILED: $e');
    }
  }

  Future<void> _markTaskComplete(String taskId) async {
    try {
      final cipher = await DatabaseService.getEncryptionCipher();
      final box = await Hive.openBox<ActivityTask>('tasks', encryptionCipher: cipher);

      final task = box.get(taskId);
      if (task != null) {
        final now = DateTime.now();
        final normalizedDate = DateTime(now.year, now.month, now.day);

        // Check if already completed
        final isCompleted = task.completedDates.any((d) =>
            d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day);

        if (!isCompleted) {
          List<DateTime> newCompletedDates = List.from(task.completedDates);
          newCompletedDates.add(normalizedDate);

          final updatedTask =
              task.copyWith(completedDates: newCompletedDates);
          await box.put(taskId, updatedTask);
        }
      }
    } catch (e) {
      debugPrint('Error marking complete in background: $e');
    }
  }
}
