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

  Future<void> saveLogin(String userId, String email) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyLoggedInUserId, userId);
    await prefs.setString(_keyLoggedInUserEmail, email);
  }

  Future<String?> getLoggedUserId() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    return prefs.getString(_keyLoggedInUserId);
  }

  Future<String?> getLoggedUserEmail() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    return prefs.getString(_keyLoggedInUserEmail);
  }

  Future<bool> isLoggedIn() async {
    final userId = await getLoggedUserId();
    return userId != null && userId.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.remove(_keyLoggedInUserId);
    await prefs.remove(_keyLoggedInUserEmail);
  }
}