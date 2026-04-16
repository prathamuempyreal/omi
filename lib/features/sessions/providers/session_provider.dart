import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../../data/models/session_record.dart';

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionState {
  const SessionState({
    required this.sessions,
    required this.isLoading,
    this.errorMessage,
  });

  factory SessionState.initial() =>
      const SessionState(sessions: [], isLoading: false);

  final List<SessionRecord> sessions;
  final bool isLoading;
  final String? errorMessage;

  SessionState copyWith({
    List<SessionRecord>? sessions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  final _uuid = const Uuid();
  String? _currentSessionId;

  @override
  SessionState build() {
    Future.microtask(loadSessions);
    return SessionState.initial();
  }

  String? get currentSessionId => _currentSessionId;

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true);
    try {
      final sessions = await ref.read(appDatabaseProvider).getAllSessions();
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      state = state.copyWith(
        sessions: sessions,
        isLoading: false,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sessions could not be loaded right now.',
      );
    }
  }

  Future<String> startSession() async {
    final session = SessionRecord(
      id: _uuid.v4(),
      startedAt: DateTime.now(),
      endedAt: null,
      transcriptSnippet: null,
      memoryCount: 0,
      durationSeconds: null,
    );
    _currentSessionId = session.id;
    await ref.read(appDatabaseProvider).insertSession(session);
    print('SESSION START: ${session.id}');
    await loadSessions();
    return session.id;
  }

  Future<void> updateCurrentSession({
    String? transcriptSnippet,
    int? memoryCount,
  }) async {
    if (_currentSessionId == null) return;

    try {
      final database = ref.read(appDatabaseProvider);
      final existing = await database.getSessionById(_currentSessionId!);
      if (existing == null) return;

      String? newTranscript = existing.transcriptSnippet;
      if (transcriptSnippet != null && transcriptSnippet.isNotEmpty) {
        final combined = existing.transcriptSnippet == null
            ? transcriptSnippet
            : '${existing.transcriptSnippet} ${transcriptSnippet}';
        newTranscript = combined.length > 500 
            ? combined.substring(0, 500) 
            : combined;
      }

      final updated = existing.copyWith(
        transcriptSnippet: newTranscript,
        memoryCount: memoryCount ?? existing.memoryCount,
      );
      await database.updateSession(updated);
      await loadSessions();
    } catch (e) {
      print("Session update error: $e");
    }
  }

  Future<void> appendTranscript(String transcript) async {
    if (_currentSessionId == null) return;
    if (transcript.trim().isEmpty) return;

    final currentState = state;
    final currentSession = currentState.sessions.firstWhere(
      (s) => s.id == _currentSessionId,
      orElse: () => throw Exception('No active session'),
    );

    final combined = currentSession.transcriptSnippet == null
        ? transcript
        : '${currentSession.transcriptSnippet} ${transcript}';

    final snippet = combined.length > 500 
        ? combined.substring(0, 500) 
        : combined;

    print('SESSION TRANSCRIPT: $snippet');
    await updateCurrentSession(transcriptSnippet: snippet);
  }

  Future<void> incrementMemoryCount() async {
    if (_currentSessionId == null) return;

    final currentState = state;
    final currentSession = currentState.sessions.firstWhere(
      (s) => s.id == _currentSessionId,
      orElse: () => throw Exception('No active session'),
    );

    print('SESSION MEMORY COUNT++ (${currentSession.memoryCount} -> ${currentSession.memoryCount + 1})');
    await updateCurrentSession(
      memoryCount: currentSession.memoryCount + 1,
    );
  }

  Future<void> endSession(
    String sessionId, {
    String? transcriptSnippet,
    int? memoryCount,
  }) async {
    final database = ref.read(appDatabaseProvider);
    final existing = await database.getSessionById(sessionId);
    final endedAt = DateTime.now();
    final durationSeconds = existing == null
        ? 0
        : endedAt.difference(existing.startedAt).inSeconds.clamp(0, 864000);

    final transcript = transcriptSnippet?.trim().isEmpty ?? true
        ? existing?.transcriptSnippet
        : transcriptSnippet!.trim();

    final finalMemoryCount = memoryCount ?? existing?.memoryCount ?? 0;

    print('SESSION END: $sessionId (duration: ${durationSeconds}s, memories: $finalMemoryCount)');
    
    await database.endSession(
      sessionId,
      endedAt,
      transcriptSnippet: transcript,
      memoryCount: finalMemoryCount,
      durationSeconds: durationSeconds,
    );

    if (_currentSessionId == sessionId) {
      _currentSessionId = null;
    }

    await loadSessions();
  }
}
