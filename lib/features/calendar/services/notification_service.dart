import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle_data.dart';
import '../utils/cycle_calculator.dart';
import '../../../core/services/streak_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
        onNotificationClick?.call(response.payload);
      },
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

  // Schedule period reminder
  Future<void> schedulePeriodReminder(
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
      'period_reminders',
      'Period Reminders',
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
        'Period Reminder',
        'Your period is expected in $daysBeforePeriod ${daysBeforePeriod == 1 ? 'day' : 'days'}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'period_reminder',
      );
    } catch (e) {
      // Fallback to inexact if permission denied
      await _notifications.zonedSchedule(
        0,
        'Period Reminder',
        'Your period is expected in $daysBeforePeriod ${daysBeforePeriod == 1 ? 'day' : 'days'}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'period_reminder',
      );
    }
  }

  // Schedule ovulation reminder
  Future<void> scheduleOvulationReminder(UserCycleProfile cycleProfile) async {
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
      'ovulation_reminders',
      'Ovulation Reminders',
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
        payload: 'ovulation_reminder',
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
        payload: 'ovulation_reminder',
      );
    }
  }

  // Schedule daily log reminder
  Future<void> scheduleDailyLogReminder() async {
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
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Reminder to log your health data',
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
            : 'Take a moment to log your mood, symptoms or meals today.',
        finalScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: 'daily_log_reminder',
      );
    } catch (e) {
      await _notifications.zonedSchedule(
        2,
        streak > 0 ? 'Keep your streak alive!' : 'Daily Check-in',
        streak > 0
            ? 'You have a $streak day streak! Log your logs today to keep it going.'
            : 'Take a moment to log your mood, symptoms or meals today.',
        finalScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_log_reminder',
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
      'periodRemindersEnabled':
          prefs.getBool('period_reminders_enabled') ?? false,
      'ovulationRemindersEnabled':
          prefs.getBool('ovulation_reminders_enabled') ?? false,
      'reminderDaysBefore': prefs.getInt('reminder_days_before') ?? 2,
    };
  }

  // Save notification preferences
  static Future<void> savePreferences({
    bool? periodRemindersEnabled,
    bool? ovulationRemindersEnabled,
    int? reminderDaysBefore,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (periodRemindersEnabled != null) {
      await prefs.setBool('period_reminders_enabled', periodRemindersEnabled);
    }

    if (ovulationRemindersEnabled != null) {
      await prefs.setBool(
          'ovulation_reminders_enabled', ovulationRemindersEnabled);
    }

    if (reminderDaysBefore != null) {
      await prefs.setInt('reminder_days_before', reminderDaysBefore);
    }
  }
}
