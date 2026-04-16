import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/settings/providers/settings_provider.dart';

final sessionHelperProvider = Provider<SessionHelper>((ref) {
  return SessionHelper(ref);
});

class SessionHelper {
  final Ref _ref;

  static const _keyLoggedInUserId = 'logged_in_user_id';
  static const _keyLoggedInUserEmail = 'logged_in_user_email';

  SessionHelper(this._ref);

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('logged_in_user_id');
    final email = prefs.getString('logged_in_user_email');

    debugPrint('Session check: logged_in_user_id = $userId');
    debugPrint('Session check: logged_in_user_email = $email');

    final isValid = userId != null &&
        userId.isNotEmpty &&
        email != null &&
        email.isNotEmpty;

    debugPrint('Session check: isLoggedIn = $isValid');

    return isValid;
  }

  static Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('logged_in_user_id');
    final email = prefs.getString('logged_in_user_email');

    debugPrint('hasValidSession: userId = $userId, email = $email');

    return userId != null &&
        userId.isNotEmpty &&
        email != null &&
        email.isNotEmpty;
  }

  Future<void> saveLogin(String userId, String email) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyLoggedInUserId, userId);
    await prefs.setString(_keyLoggedInUserEmail, email);
    debugPrint('Session saved: userId = $userId, email = $email');
  }

  Future<String?> getLoggedUserId() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    return prefs.getString(_keyLoggedInUserId);
  }

  Future<String?> getLoggedUserEmail() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    return prefs.getString(_keyLoggedInUserEmail);
  }

  Future<void> logout() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.remove(_keyLoggedInUserId);
    await prefs.remove(_keyLoggedInUserEmail);
    debugPrint('Session cleared: logged out');
  }
}