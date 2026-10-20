import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the intro has been shown, so it only appears once.
class OnboardingStore {
  static const _key = 'onboarding_seen_v1';

  static Future<bool> hasSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Not fatal: the intro would just show again next launch.
    }
  }
}
