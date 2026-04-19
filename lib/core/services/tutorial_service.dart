import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  static const String _calendarTutorialKey = 'calendar_tutorial_shown';
  static const String _tasksTutorialKey = 'tasks_tutorial_shown';
  static const String _notesTutorialKey = 'notes_tutorial_shown';

  Future<bool> shouldShowCalendarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_calendarTutorialKey) ?? false);
  }

  Future<void> markCalendarTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_calendarTutorialKey, true);
  }

  void showCalendarTutorial({
    required BuildContext context,
    required GlobalKey calendarKey,
    required GlobalKey switchKey,
    required GlobalKey messageKey,
    required GlobalKey legendKey,
    VoidCallback? onFinish,
  }) {
    final targets = [
      TargetFocus(
        identify: "calendar_message",
        keyTarget: messageKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Meet your guide!",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                   Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "I'll give you quick tips and insights about your health here.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "calendar_table",
        keyTarget: calendarKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Your Health Hub",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                   Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Tap any day to log symptoms or events. Double-tap for a detailed daily view.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "calendar_switch",
        keyTarget: switchKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Toggle View",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                   Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Switch between month and 2-week view to focus on what matters.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "calendar_legend",
        keyTarget: legendKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Smart Filters",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                   Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Toggle these to show or hide periods, symptoms, and fertile windows on your calendar.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Theme.of(context).colorScheme.primary,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        markCalendarTutorialShown();
        onFinish?.call();
      },
      onSkip: () {
        markCalendarTutorialShown();
        return true;
      },
    ).show(context: context);
  }

  Future<bool> shouldShowTasksTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_tasksTutorialKey) ?? false);
  }

  Future<void> markTasksTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tasksTutorialKey, true);
  }

  void showTasksTutorial({
    required BuildContext context,
    required GlobalKey addKey,
    required GlobalKey categoryKey,
    VoidCallback? onFinish,
  }) {
    final targets = [
      TargetFocus(
        identify: "tasks_add",
        keyTarget: addKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Create your first task!",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                   Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Tap here to add a daily ritual, a work task, or a health goal.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "tasks_categories",
        keyTarget: categoryKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Stay Organized",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                   Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Filter your tasks by category to focus on specific areas of your life.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Theme.of(context).colorScheme.primary,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        markTasksTutorialShown();
        onFinish?.call();
      },
      onSkip: () {
        markTasksTutorialShown();
        return true;
      },
    ).show(context: context);
  }

  Future<bool> shouldShowNotesTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_notesTutorialKey) ?? false);
  }

  Future<void> markNotesTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notesTutorialKey, true);
  }

  void showNotesTutorial({
    required BuildContext context,
    required GlobalKey addKey,
    required GlobalKey moodKey,
    VoidCallback? onFinish,
  }) {
    final targets = [
      TargetFocus(
        identify: "notes_add",
        keyTarget: addKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Capture your thoughts",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                   Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Use notes to keep track of how you feel, your symptoms, or just daily reflections.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "notes_moods",
        keyTarget: moodKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Filter by Mood",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20),
                  ),
                   Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Quickly find notes from days where you felt a specific way.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Theme.of(context).colorScheme.primary,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        markNotesTutorialShown();
        onFinish?.call();
      },
      onSkip: () {
        markNotesTutorialShown();
        return true;
      },
    ).show(context: context);
  }
}
