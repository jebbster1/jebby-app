import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const String renterGetStartedSeen = 'renter_get_started_seen';

  static Future<bool> hasSeenRenterGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(renterGetStartedSeen) ?? false;
  }

  static Future<void> markRenterGetStartedSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(renterGetStartedSeen, true);
  }

  /// Call after [SharedPreferences.clear] on logout so returning users skip
  /// first-launch onboarding but still land on Login.
  static Future<void> restoreRenterGetStartedFlag() async {
    await markRenterGetStartedSeen();
  }
}
