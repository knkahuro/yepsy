import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class OnboardingService {
  static const String _isFirstRunKey = 'is_first_run';
  static const String _tutorialCompletedKey = 'tutorial_completed';

  /// Check if this is the first time the app is running
  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if the key doesn't exist
    return prefs.getBool(_isFirstRunKey) ?? true;
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstRunKey, false);
  }

  /// Check if the interactive tutorial has been completed
  Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool(_tutorialCompletedKey) ?? false;
    debugPrint('📚 OnboardingService: isTutorialCompleted = $isCompleted');
    return isCompleted;
  }

  /// Mark the tutorial as completed
  Future<void> completeTutorial() async {
    debugPrint('📚 OnboardingService: Marking tutorial as completed');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  /// Reset tutorial state (to replay tutorial)
  Future<void> resetTutorial() async {
    debugPrint('📚 OnboardingService: Resetting tutorial state');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);
    debugPrint('📚 OnboardingService: Tutorial state reset complete');
  }

  /// Reset onboarding state (for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isFirstRunKey);
    await prefs.remove(_tutorialCompletedKey);
  }
}
