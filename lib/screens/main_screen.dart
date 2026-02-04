import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/streak_service.dart';
import '../features/calendar/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentStreak = 0;
  final StreakService _streakService = StreakService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final streak = await _streakService.calculateCurrentStreak();
    if (mounted) {
      setState(() {
        _currentStreak = streak;
      });

      // Check for milestones and schedule reminders
      await _notificationService.checkAndNotifyStreakMilestone();
      await _notificationService.scheduleDailyLogReminder();
    }
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    // Refresh streak when switching tabs to ensure accuracy
    _loadStreak();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yepsy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_currentStreak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '$_currentStreak',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: widget.navigationShell.currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _goBranch,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Notes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fastfood_outlined), label: 'Meals'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bedtime_outlined), label: 'Sleep'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
