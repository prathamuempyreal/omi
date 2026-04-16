import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/omi_realtime_provider.dart';
import '../../../core/services/notifications_services.dart';
import '../../../core/services/permission_services.dart';

const onboardingCompletedPrefKey = 'onboarding_complete';
const themeModePrefKey = 'theme_mode';
const notificationsEnabledPrefKey = 'notifications_enabled';
const offlineRetryEnabledPrefKey = 'offline_retry_enabled';
const pcmAssistEnabledPrefKey = 'pcm_assist_enabled';

const overviewEventsPrefKey = 'overview_events';
const realtimeTranscriptPrefKey = 'realtime_transcript';
const audioBytesPrefKey = 'audio_bytes';
const daySummaryPrefKey = 'day_summary';
const transcriptDiagnosticsPrefKey = 'transcript_diagnostics';
const autoSaveSpeakersPrefKey = 'auto_save_speakers';
const relationshipInferencePrefKey = 'relationship_inference';
const goalTrackingPrefKey = 'goal_tracking';
const dailyReflectionPrefKey = 'daily_reflection';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.');
});

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

class SettingsState {
  final bool onboardingCompleted;
  final bool microphoneGranted;
  final bool notificationsGranted;
  final bool notificationsEnabled;
  final bool offlineRetryEnabled;
  final bool pcmAssistEnabled;
  final ThemeMode themeMode;
  final bool isLoading;
  final bool isReady;
  final bool overviewEvents;
  final bool realtimeTranscript;
  final bool audioBytes;
  final bool daySummary;
  final bool transcriptDiagnostics;
  final bool autoSaveSpeakers;
  final bool relationshipInference;
  final bool goalTracking;
  final bool dailyReflection;

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
    this.overviewEvents = true,
    this.realtimeTranscript = true,
    this.audioBytes = false,
    this.daySummary = true,
    this.transcriptDiagnostics = false,
    this.autoSaveSpeakers = true,
    this.relationshipInference = true,
    this.goalTracking = true,
    this.dailyReflection = true,
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
    bool? overviewEvents,
    bool? realtimeTranscript,
    bool? audioBytes,
    bool? daySummary,
    bool? transcriptDiagnostics,
    bool? autoSaveSpeakers,
    bool? relationshipInference,
    bool? goalTracking,
    bool? dailyReflection,
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
      overviewEvents: overviewEvents ?? this.overviewEvents,
      realtimeTranscript: realtimeTranscript ?? this.realtimeTranscript,
      audioBytes: audioBytes ?? this.audioBytes,
      daySummary: daySummary ?? this.daySummary,
      transcriptDiagnostics: transcriptDiagnostics ?? this.transcriptDiagnostics,
      autoSaveSpeakers: autoSaveSpeakers ?? this.autoSaveSpeakers,
      relationshipInference: relationshipInference ?? this.relationshipInference,
      goalTracking: goalTracking ?? this.goalTracking,
      dailyReflection: dailyReflection ?? this.dailyReflection,
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

    final omiState = ref.read(omiRealtimeProvider);

    state = state.copyWith(
      onboardingCompleted: prefs.getBool(onboardingCompletedPrefKey) ?? false,
      microphoneGranted: mic,
      notificationsGranted: notifications,
      notificationsEnabled: prefs.getBool(notificationsEnabledPrefKey) ?? true,
      offlineRetryEnabled: prefs.getBool(offlineRetryEnabledPrefKey) ?? true,
      pcmAssistEnabled: prefs.getBool(pcmAssistEnabledPrefKey) ?? true,
      themeMode: _themeModeFromName(prefs.getString(themeModePrefKey)),
      overviewEvents: omiState.settings.overviewEvents,
      realtimeTranscript: omiState.settings.realtimeTranscript,
      audioBytes: omiState.settings.audioBytes,
      daySummary: omiState.settings.daySummary,
      transcriptDiagnostics: omiState.settings.transcriptDiagnostics,
      autoSaveSpeakers: omiState.settings.autoSaveSpeakers,
      relationshipInference: omiState.settings.relationshipInference,
      goalTracking: omiState.settings.goalTracking,
      dailyReflection: omiState.settings.dailyReflection,
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

  Future<void> setOverviewEvents(bool value) async {
    await ref.read(omiRealtimeProvider.notifier).updateSetting('overview_events', value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(overviewEventsPrefKey, value);
    state = state.copyWith(overviewEvents: value);
  }

  Future<void> setRealtimeTranscript(bool value) async {
    await ref.read(omiRealtimeProvider.notifier).updateSetting('realtime_transcript', value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(realtimeTranscriptPrefKey, value);
    state = state.copyWith(realtimeTranscript: value);
  }

  Future<void> setAudioBytes(bool value) async {
    await ref.read(omiRealtimeProvider.notifier).updateSetting('audio_bytes', value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(audioBytesPrefKey, value);
    state = state.copyWith(audioBytes: value);
  }

  Future<void> setDaySummary(bool value) async {
    await ref.read(omiRealtimeProvider.notifier).updateSetting('day_summary', value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(daySummaryPrefKey, value);
    state = state.copyWith(daySummary: value);
  }

  Future<void> setTranscriptDiagnostics(bool value) async {
    await ref.read(omiRealtimeProvider.notifier).updateSetting('transcript_diagnostics', value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(transcriptDiagnosticsPrefKey, value);
    state = state.copyWith(transcriptDiagnostics: value);
  }

  Future<void> setAutoSaveSpeakers(bool value) async {
    await ref.read(omiRealtimeProvider.notifier).updateSetting('auto_save_speakers', value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(autoSaveSpeakersPrefKey, value);
    state = state.copyWith(autoSaveSpeakers: value);
  }

  Future<void> setRelationshipInference(bool value) async {
    await ref.read(omiRealtimeProvider.notifier).updateSetting('relationship_inference', value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(relationshipInferencePrefKey, value);
    state = state.copyWith(relationshipInference: value);
  }

  Future<void> setGoalTracking(bool value) async {
    await ref.read(omiRealtimeProvider.notifier).updateSetting('goal_tracking', value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(goalTrackingPrefKey, value);
    state = state.copyWith(goalTracking: value);
  }

  Future<void> setDailyReflection(bool value) async {
    await ref.read(omiRealtimeProvider.notifier).updateSetting('daily_reflection', value);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(dailyReflectionPrefKey, value);
    state = state.copyWith(dailyReflection: value);
  }

  ThemeMode _themeModeFromName(String? name) {
    return switch (name) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }
}
