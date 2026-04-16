import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/omi_realtime_provider.dart';
import '../../../data/models/api/omi_models.dart';

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionState {
  final List<OmiConversation> sessions;
  final bool isLoading;
  final String? errorMessage;
  final String? languageFilter;

  const SessionState({
    this.sessions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.languageFilter,
  });

  SessionState copyWith({
    List<OmiConversation>? sessions,
    bool? isLoading,
    String? errorMessage,
    String? languageFilter,
  }) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      languageFilter: languageFilter ?? this.languageFilter,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  String? _currentSessionId;

  @override
  SessionState build() {
    Future.microtask(loadConversations);
    return const SessionState();
  }

  String? get currentSessionId => _currentSessionId;

  Future<void> loadConversations({String? languageFilter}) async {
    state = state.copyWith(isLoading: true, languageFilter: languageFilter);
    try {
      await ref.read(omiRealtimeProvider.notifier).refreshConversations();
      final omiState = ref.read(omiRealtimeProvider);
      var conversations = List<OmiConversation>.from(omiState.conversations);
      
      if (languageFilter != null && languageFilter != 'all') {
        conversations = conversations.where((c) => c.language == languageFilter).toList();
      }
      
      conversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('SessionsProvider: Loaded conversations: ${conversations.length}');
      debugPrint('SessionsProvider: Language filter: ${languageFilter ?? "all"}');
      
      state = state.copyWith(
        sessions: conversations,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('SessionsProvider: Error loading conversations: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sessions could not be loaded right now.',
      );
    }
  }

  Future<void> loadSessions() async {
    await loadConversations(languageFilter: state.languageFilter);
  }

  Future<String> startSession() async {
    final conversation = OmiConversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
    _currentSessionId = conversation.id;
    state = state.copyWith(
      sessions: [conversation, ...state.sessions],
    );
    return conversation.id;
  }

  Future<void> updateCurrentSession({
    String? transcriptSnippet,
    int? memoryCount,
  }) async {
    if (_currentSessionId == null) return;

    final index = state.sessions.indexWhere((s) => s.id == _currentSessionId);
    if (index == -1) return;

    final existing = state.sessions[index];
    String? newTranscript = existing.transcript;
    if (transcriptSnippet != null && transcriptSnippet.isNotEmpty) {
      final combined = existing.transcript == null
          ? transcriptSnippet
          : '${existing.transcript} ${transcriptSnippet}';
      newTranscript = combined.length > 500 
          ? combined.substring(0, 500) 
          : combined;
    }

    final updated = OmiConversation(
      id: existing.id,
      title: existing.title,
      transcript: newTranscript,
      summary: existing.summary,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      messages: existing.messages,
      language: existing.language,
      metadata: existing.metadata,
    );

    final newSessions = List<OmiConversation>.from(state.sessions);
    newSessions[index] = updated;
    state = state.copyWith(sessions: newSessions);
  }

  Future<void> appendTranscript(String transcript) async {
    if (_currentSessionId == null) return;
    if (transcript.trim().isEmpty) return;

    await updateCurrentSession(transcriptSnippet: transcript);
  }

  Future<void> incrementMemoryCount() async {
    // Memory count is managed through OmiRealtimeProvider
  }

  Future<void> endSession(
    String sessionId, {
    String? transcriptSnippet,
    int? memoryCount,
  }) async {
    final index = state.sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final existing = state.sessions[index];
    final updated = OmiConversation(
      id: existing.id,
      title: existing.title,
      transcript: transcriptSnippet ?? existing.transcript,
      summary: existing.summary,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      messages: existing.messages,
      language: existing.language,
      metadata: {
        ...?existing.metadata,
        'endedAt': DateTime.now().toIso8601String(),
        'memoryCount': memoryCount ?? 0,
      },
    );

    final newSessions = List<OmiConversation>.from(state.sessions);
    newSessions[index] = updated;
    state = state.copyWith(sessions: newSessions);

    if (_currentSessionId == sessionId) {
      _currentSessionId = null;
    }
  }
}