// storage_helper.dart
// SLIMMED DOWN — most functionality moved to Firebase services
//
// Previously: handled auth, user profiles, requests, availability
// Now: only handles local preferences (non-critical stuff)
//
// WHY KEEP IT?
// SharedPreferences is still useful for local settings like:
// - Theme preference (dark/light)
// - First-time tutorial flag
// - Cache preferences
// We keep it minimal so existing code that may reference it
// doesn't break, but all critical data is now in Firebase.

import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {

  // ── CHECK FIRST TIME LAUNCH ────────────────────────────────────
  // Used to show tutorial/onboarding on first app launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('firstLaunch') ?? true;
  }

  static Future<void> setFirstLaunchDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstLaunch', false);
  }

  // ── CLEAR ALL LOCAL DATA ───────────────────────────────────────
  // Called on logout to clean up any cached data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}