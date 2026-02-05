import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/notes/screens/notes_screen.dart';
import '../features/meals/screens/meals_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/sleep_tracking/screens/sleep_tracking_screen.dart';

import '../features/profile/screens/profile_screen.dart';
import '../features/calendar/screens/day_details_page.dart';
import '../features/calendar/models/calendar_event.dart';
import '../features/calendar/models/symptom_log.dart';
import '../screens/main_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../core/services/onboarding_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/calendar',
  redirect: (context, state) async {
    final onboardingService = OnboardingService();
    final isFirstRun = await onboardingService.isFirstRun();

    // If it's the first run and we're not on onboarding, go there
    if (isFirstRun && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }

    // If it's NOT the first run and we're on onboarding, go to calendar
    if (!isFirstRun && state.matchedLocation == '/onboarding') {
      return '/calendar';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScreen(navigationShell: navigationShell);
      },
      branches: [
        // Notes Tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notes',
              builder: (context, state) => const NotesScreen(),
            ),
          ],
        ),
        // Meals Tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/meals',
              builder: (context, state) => const MealsScreen(),
            ),
          ],
        ),
        // Calendar Tab
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
                routes: [
                  GoRoute(
                    path: 'details',
                    parentNavigatorKey: _rootNavigatorKey, // Open full screen
                    builder: (context, state) {
                      // Retrieve extras passed during navigation
                      final extras = state.extra as Map<String, dynamic>;
                      return DayDetailsPage(
                        selectedDay: extras['selectedDay'] as DateTime,
                        events: extras['events'] as List<CalendarEvent>,
                        symptoms: extras['symptoms'] as List<SymptomLog>,
                        onAddEvent: extras['onAddEvent'] as VoidCallback,
                        onAddSymptom: extras['onAddSymptom'] as VoidCallback,
                        onEditEvent:
                            extras['onEditEvent'] as Function(CalendarEvent),
                        onEditSymptom:
                            extras['onEditSymptom'] as Function(SymptomLog),
                        onDeleteEvent:
                            extras['onDeleteEvent'] as Function(CalendarEvent),
                        onDeleteSymptom:
                            extras['onDeleteSymptom'] as Function(SymptomLog),
                      );
                    },
                  ),
                ]),
          ],
        ),
        // Sleep Tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/sleep',
              builder: (context, state) => const SleepTrackingScreen(),
            ),
          ],
        ),
        // Profile Tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
