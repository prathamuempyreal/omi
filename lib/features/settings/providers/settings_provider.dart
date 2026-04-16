import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notifications_services.dart';
import '../../../core/services/permission_services.dart';

const onboardingCompletedPrefKey = 'onboarding_complete';
const themeModePrefKey = 'theme_mode';
const notificationsEnabledPrefKey = 'notifications_enabled';
const offlineRetryEnabledPrefKey = 'offline_retry_enabled';
const pcmAssistEnabledPrefKey = 'pcm_assist_enabled';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.');
});

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

class SettingsState {
  const SettingsState({
    required this.onboardingCompleted,
    required this.microphoneGranted,
    required this.notificationsGranted,
    required this.notificationsEnabled,
    required this.offlineRetryEnabled,
    required this.pcmAssistEnabled,
    required this.themeMode,
    required this.isLoading,
    required this.isReady,
  });

  factory SettingsState.initial() => const SettingsState(
    onboardingCompleted: false,
    microphoneGranted: false,
    notificationsGranted: false,
    notificationsEnabled: true,
    offlineRetryEnabled: true,
    pcmAssistEnabled: true,
    themeMode: ThemeMode.dark,
    isLoading: false,
    isReady: false,
  );

  final bool onboardingCompleted;
  final bool microphoneGranted;
  final bool notificationsGranted;
  final bool notificationsEnabled;
  final bool offlineRetryEnabled;
  final bool pcmAssistEnabled;
  final ThemeMode themeMode;
  final bool isLoading;
  final bool isReady;

  SettingsState copyWith({
    bool? onboardingCompleted,
    bool? microphoneGranted,
    bool? notificationsGranted,
    bool? notificationsEnabled,
    bool? offlineRetryEnabled,
    bool? pcmAssistEnabled,
    ThemeMode? themeMode,
    bool? isLoading,
    bool? isReady,
  }) {
    return SettingsState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      microphoneGranted: microphoneGranted ?? this.microphoneGranted,
      notificationsGranted: notificationsGranted ?? this.notificationsGranted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      offlineRetryEnabled: offlineRetryEnabled ?? this.offlineRetryEnabled,
      pcmAssistEnabled: pcmAssistEnabled ?? this.pcmAssistEnabled,
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
      isReady: isReady ?? this.isReady,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    Future.microtask(_bootstrap);
    return SettingsState.initial();
  }

  Future<void> _bootstrap() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final mic = await PermissionService.isMicGranted();
    final notifications = await PermissionService.isNotificationGranted();
    state = state.copyWith(
      onboardingCompleted: prefs.getBool(onboardingCompletedPrefKey) ?? false,
      microphoneGranted: mic,
      notificationsGranted: notifications,
      notificationsEnabled: prefs.getBool(notificationsEnabledPrefKey) ?? true,
      offlineRetryEnabled: prefs.getBool(offlineRetryEnabledPrefKey) ?? true,
      pcmAssistEnabled: prefs.getBool(pcmAssistEnabledPrefKey) ?? true,
      themeMode: _themeModeFromName(prefs.getString(themeModePrefKey)),
      isLoading: false,
      isReady: true,
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(onboardingCompletedPrefKey, true);
    await refreshPermissions();
    state = state.copyWith(onboardingCompleted: true);
  }

  Future<void> resetOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(onboardingCompletedPrefKey, false);
    state = state.copyWith(onboardingCompleted: false);
  }

  Future<void> requestPermissions() async {
    state = state.copyWith(isLoading: true);
    try {
      await PermissionService.requestMicPermission();
      await PermissionService.requestNotificationPermission();
      await NotificationService.instance.requestPermissions();
    } finally {
      await refreshPermissions();
    }
  }

  Future<void> refreshPermissions() async {
    final mic = await PermissionService.isMicGranted();
    final notifications = await PermissionService.isNotificationGranted();
    state = state.copyWith(
      microphoneGranted: mic,
      notificationsGranted: notifications,
      isLoading: false,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(notificationsEnabledPrefKey, value);
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> setOfflineRetryEnabled(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(offlineRetryEnabledPrefKey, value);
    state = state.copyWith(offlineRetryEnabled: value);
  }

  Future<void> setPcmAssistEnabled(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(pcmAssistEnabledPrefKey, value);
    state = state.copyWith(pcmAssistEnabled: value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(themeModePrefKey, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  ThemeMode _themeModeFromName(String? name) {
    return switch (name) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }
}
