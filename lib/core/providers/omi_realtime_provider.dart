import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/api/omi_models.dart';
import '../services/omi/omi_endpoints.dart';
import '../services/omi/omi_sync_manager.dart';

class OmiRealtimeState {
  final List<OmiConversation> conversations;
  final List<OmiMemory> memories;
  final List<OmiActionItem> actionItems;
  final OmiDailySummary? dailySummary;
  final List<OmiReflection> reflections;
  final List<OmiGoal> goals;
  final OmiSettings settings;
  final OmiMcpConfig mcpConfig;
  final bool isLoading;
  final bool isOnline;
  final String? error;
  final DateTime? lastSync;

  OmiRealtimeState({
    this.conversations = const [],
    this.memories = const [],
    this.actionItems = const [],
    this.dailySummary,
    this.reflections = const [],
    this.goals = const [],
    OmiSettings? settings,
    OmiMcpConfig? mcpConfig,
    this.isLoading = false,
    this.isOnline = true,
    this.error,
    this.lastSync,
  })  : settings = settings ?? OmiSettings(),
        mcpConfig = mcpConfig ?? OmiMcpConfig();

  OmiRealtimeState copyWith({
    List<OmiConversation>? conversations,
    List<OmiMemory>? memories,
    List<OmiActionItem>? actionItems,
    OmiDailySummary? dailySummary,
    List<OmiReflection>? reflections,
    List<OmiGoal>? goals,
    OmiSettings? settings,
    OmiMcpConfig? mcpConfig,
    bool? isLoading,
    bool? isOnline,
    String? error,
    DateTime? lastSync,
  }) {
    return OmiRealtimeState(
      conversations: conversations ?? this.conversations,
      memories: memories ?? this.memories,
      actionItems: actionItems ?? this.actionItems,
      dailySummary: dailySummary ?? this.dailySummary,
      reflections: reflections ?? this.reflections,
      goals: goals ?? this.goals,
      settings: settings ?? this.settings,
      mcpConfig: mcpConfig ?? this.mcpConfig,
      isLoading: isLoading ?? this.isLoading,
      isOnline: isOnline ?? this.isOnline,
      error: error,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class OmiRealtimeNotifier extends Notifier<OmiRealtimeState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _disposed = false;

  @override
  OmiRealtimeState build() {
    _initConnectivity();
    _initSync();
    return OmiRealtimeState(isLoading: true);
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (_disposed) return;
      final isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (isOnline && !state.isOnline) {
        debugPrint('OmiRealtimeProvider: Back online, triggering sync');
        syncAll();
      }
      state = state.copyWith(isOnline: isOnline);
    });
  }

  void _initSync() {
    Future.microtask(() => syncAll());
    OmiSyncManager.instance.addListener(_onSyncManagerUpdate);
  }

  void _onSyncManagerUpdate() {
    if (!_disposed) {
      state = state.copyWith(lastSync: OmiSyncManager.instance.lastSyncTime);
    }
  }

  Future<void> syncAll() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    debugPrint('OmiRealtimeProvider: Starting full sync...');

    try {
      final results = await Future.wait([
        OmiApi.getConversations(),
        OmiApi.getMemories(),
        OmiApi.getActionItems(),
        OmiApi.getSettings(),
        OmiApi.getMcpConfig(),
      ]);

      final conversationsResp = results[0];
      final memoriesResp = results[1];
      final actionItemsResp = results[2];
      final settingsResp = results[3];
      final mcpConfigResp = results[4];

      state = state.copyWith(
        conversations: conversationsResp.isSuccess 
            ? (conversationsResp.data as List<OmiConversation>?) ?? [] 
            : state.conversations,
        memories: memoriesResp.isSuccess 
            ? (memoriesResp.data as List<OmiMemory>?) ?? [] 
            : state.memories,
        actionItems: actionItemsResp.isSuccess 
            ? (actionItemsResp.data as List<OmiActionItem>?) ?? [] 
            : state.actionItems,
        settings: settingsResp.isSuccess 
            ? (settingsResp.data as OmiSettings?) ?? OmiSettings()
            : state.settings,
        mcpConfig: mcpConfigResp.isSuccess 
            ? (mcpConfigResp.data as OmiMcpConfig?) ?? OmiMcpConfig()
            : state.mcpConfig,
        isLoading: false,
        lastSync: DateTime.now(),
      );

      debugPrint('OmiRealtimeProvider: Sync complete');
    } catch (e) {
      debugPrint('OmiRealtimeProvider: Sync error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Sync failed: $e',
      );
    }
  }

  Future<void> refreshConversations() async {
    final response = await OmiApi.getConversations();
    if (response.isSuccess) {
      state = state.copyWith(
        conversations: (response.data as List<OmiConversation>?) ?? [],
      );
    }
  }

  Future<void> refreshMemories({String? type}) async {
    final response = await OmiApi.getMemories(type: type);
    if (response.isSuccess) {
      state = state.copyWith(
        memories: (response.data as List<OmiMemory>?) ?? [],
      );
    }
  }

  Future<void> refreshActionItems({bool? completed}) async {
    final response = await OmiApi.getActionItems(completed: completed);
    if (response.isSuccess) {
      state = state.copyWith(
        actionItems: (response.data as List<OmiActionItem>?) ?? [],
      );
    }
  }

  Future<void> loadDailySummary(DateTime date) async {
    final response = await OmiApi.getDailySummary(date);
    if (response.isSuccess) {
      state = state.copyWith(
        dailySummary: response.data as OmiDailySummary?,
      );
    }
  }

  Future<void> loadReflections({DateTime? date}) async {
    final response = await OmiApi.getReflections(date: date);
    if (response.isSuccess) {
      state = state.copyWith(
        reflections: (response.data as List<OmiReflection>?) ?? [],
      );
    }
  }

  Future<void> loadGoals({String? status}) async {
    final response = await OmiApi.getGoals(status: status);
    if (response.isSuccess) {
      state = state.copyWith(
        goals: (response.data as List<OmiGoal>?) ?? [],
      );
    }
  }

  Future<void> createMemory(OmiMemory memory) async {
    final response = await OmiApi.createMemory(memory);
    if (response.isSuccess) {
      await refreshMemories();
    }
  }

  Future<void> updateMemory(String id, Map<String, dynamic> data) async {
    final response = await OmiApi.updateMemory(id, data);
    if (response.isSuccess) {
      await refreshMemories();
    }
  }

  Future<void> deleteMemory(String id) async {
    final response = await OmiApi.deleteMemory(id);
    if (response.isSuccess) {
      await refreshMemories();
    }
  }

  Future<void> createActionItem(OmiActionItem item) async {
    final response = await OmiApi.createActionItem(item);
    if (response.isSuccess) {
      await refreshActionItems();
    }
  }

  Future<void> updateActionItem(String id, Map<String, dynamic> data) async {
    final response = await OmiApi.updateActionItem(id, data);
    if (response.isSuccess) {
      await refreshActionItems();
    }
  }

  Future<void> completeActionItem(String id) async {
    await updateActionItem(id, {'completed': true});
  }

  Future<void> deleteActionItem(String id) async {
    final response = await OmiApi.deleteActionItem(id);
    if (response.isSuccess) {
      await refreshActionItems();
    }
  }

  Future<void> updateSettings(OmiSettings settings) async {
    final response = await OmiApi.updateSettings(settings);
    if (response.isSuccess) {
      state = state.copyWith(settings: settings);
    }
  }

  Future<void> updateSetting(String key, bool value) async {
    final currentSettings = state.settings;
    OmiSettings newSettings;

    switch (key) {
      case 'overview_events':
        newSettings = currentSettings.copyWith(overviewEvents: value);
        break;
      case 'realtime_transcript':
        newSettings = currentSettings.copyWith(realtimeTranscript: value);
        break;
      case 'audio_bytes':
        newSettings = currentSettings.copyWith(audioBytes: value);
        break;
      case 'day_summary':
        newSettings = currentSettings.copyWith(daySummary: value);
        break;
      case 'transcript_diagnostics':
        newSettings = currentSettings.copyWith(transcriptDiagnostics: value);
        break;
      case 'auto_save_speakers':
        newSettings = currentSettings.copyWith(autoSaveSpeakers: value);
        break;
      case 'relationship_inference':
        newSettings = currentSettings.copyWith(relationshipInference: value);
        break;
      case 'goal_tracking':
        newSettings = currentSettings.copyWith(goalTracking: value);
        break;
      case 'daily_reflection':
        newSettings = currentSettings.copyWith(dailyReflection: value);
        break;
      default:
        return;
    }
    await updateSettings(newSettings);
  }

  Future<bool> testConnection() async {
    return await OmiApi.testConnection();
  }
}

final omiRealtimeProvider = NotifierProvider<OmiRealtimeNotifier, OmiRealtimeState>(
  OmiRealtimeNotifier.new,
);