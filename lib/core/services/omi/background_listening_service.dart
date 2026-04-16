import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'omi_sync_service.dart';

class BackgroundListeningService {
  BackgroundListeningService._();

  static BackgroundListeningService? _instance;
  static BackgroundListeningService get instance =>
      _instance ??= BackgroundListeningService._();

  bool _isRunning = false;
  Timer? _periodicCommitTimer;
  Timer? _periodicHealthCheck;
  final List<String> _transcriptBuffer = [];
  DateTime? _lastCommitTime;
  String? _currentConversationId;
  String? _currentSessionId;

  static const Duration _commitInterval = Duration(minutes: 5);
  static const Duration _healthCheckInterval = Duration(minutes: 1);
  static const int _minBufferSize = 5;
  static const String _bufferKey = 'bg_transcript_buffer';
  static const String _sessionKey = 'bg_session_id';

  bool get isRunning => _isRunning;

  int get bufferSize => _transcriptBuffer.length;

  Duration? get timeSinceLastCommit {
    if (_lastCommitTime == null) return null;
    return DateTime.now().difference(_lastCommitTime!);
  }

  String? get currentConversationId => _currentConversationId;

  String? get currentSessionId => _currentSessionId;

  Future<void> initialize() async {
    debugPrint('BackgroundListeningService: Initializing...');

    final prefs = await SharedPreferences.getInstance();
    final existingSession = prefs.getString(_sessionKey);
    
    if (existingSession != null) {
      _currentSessionId = existingSession;
      debugPrint('BackgroundListeningService: Resuming existing session: $existingSession');
    } else {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_sessionKey, _currentSessionId!);
      debugPrint('BackgroundListeningService: Created new session: $_currentSessionId');
    }

    _loadBufferFromStorage();
    
    debugPrint('BackgroundListeningService: Initialization complete (buffer size: ${_transcriptBuffer.length})');
  }

  Future<void> _loadBufferFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buffer = prefs.getStringList(_bufferKey);
      if (buffer != null && buffer.isNotEmpty) {
        _transcriptBuffer.addAll(buffer);
        debugPrint('BackgroundListeningService: Loaded ${buffer.length} chunks from storage');
      }
    } catch (e) {
      debugPrint('BackgroundListeningService: Error loading buffer: $e');
    }
  }

  Future<void> _saveBufferToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_bufferKey, _transcriptBuffer);
      debugPrint('BackgroundListeningService: Saved ${_transcriptBuffer.length} chunks to storage');
    } catch (e) {
      debugPrint('BackgroundListeningService: Error saving buffer: $e');
    }
  }

  Future<bool> startListening() async {
    if (_isRunning) {
      debugPrint('BackgroundListeningService: Already running');
      return true;
    }

    debugPrint('BackgroundListeningService: Starting background listening...');

    try {
      await initialize();

      _isRunning = true;
      _lastCommitTime = DateTime.now();

      _startPeriodicCommit();
      _startHealthCheck();

      debugPrint('BackgroundListeningService: Background listening started successfully');
      return true;
    } catch (e) {
      debugPrint('BackgroundListeningService: Error starting: $e');
      _isRunning = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_isRunning) {
      debugPrint('BackgroundListeningService: Not running');
      return;
    }

    debugPrint('BackgroundListeningService: Stopping background listening...');

    _stopPeriodicCommit();
    _stopHealthCheck();

    await _flushBuffer();

    _isRunning = false;
    debugPrint('BackgroundListeningService: Background listening stopped');
  }

  void _startPeriodicCommit() {
    _periodicCommitTimer?.cancel();
    _periodicCommitTimer = Timer.periodic(_commitInterval, (_) {
      _scheduleCommit();
    });
    debugPrint('BackgroundListeningService: Periodic commit started (every ${_commitInterval.inMinutes} minutes)');
  }

  void _stopPeriodicCommit() {
    _periodicCommitTimer?.cancel();
    _periodicCommitTimer = null;
    debugPrint('BackgroundListeningService: Periodic commit stopped');
  }

  void _startHealthCheck() {
    _periodicHealthCheck?.cancel();
    _periodicHealthCheck = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
    debugPrint('BackgroundListeningService: Health check started');
  }

  void _stopHealthCheck() {
    _periodicHealthCheck?.cancel();
    _periodicHealthCheck = null;
  }

  void _performHealthCheck() {
    if (!_isRunning) return;
    
    debugPrint(
      'BackgroundListeningService: Health check - '
      'Running: $_isRunning, '
      'Buffer: ${_transcriptBuffer.length}, '
      'Session: $_currentSessionId, '
      'Last commit: ${_lastCommitTime?.toIso8601String() ?? "never"}',
    );

    if (_transcriptBuffer.length >= _minBufferSize) {
      debugPrint('BackgroundListeningService: Buffer size exceeded minimum, scheduling commit');
      _scheduleCommit();
    }
  }

  void addTranscriptChunk(String text) {
    if (!_isRunning) {
      debugPrint('BackgroundListeningService: Not running, ignoring transcript chunk');
      return;
    }

    if (text.trim().isEmpty) return;

    _transcriptBuffer.add(text);
    debugPrint('BackgroundListeningService: Added chunk to buffer (${_transcriptBuffer.length} total, ${text.length} chars)');

    _saveBufferToStorage();

    if (_transcriptBuffer.length >= _minBufferSize) {
      _scheduleCommit();
    }
  }

  Timer? _commitDebounceTimer;

  void _scheduleCommit() {
    _commitDebounceTimer?.cancel();
    _commitDebounceTimer = Timer(const Duration(seconds: 2), () {
      _commitBuffer();
    });
  }

  Future<void> _commitBuffer() async {
    if (_transcriptBuffer.isEmpty) {
      debugPrint('BackgroundListeningService: Buffer empty, skipping commit');
      return;
    }

    final transcript = _transcriptBuffer.join(' ');
    _transcriptBuffer.clear();
    await _saveBufferToStorage();
    _lastCommitTime = DateTime.now();

    debugPrint('BackgroundListeningService: Committing buffer (${transcript.length} chars)');

    try {
      final omiSyncService = OmiSyncService.instance;
      final result = await omiSyncService.processTranscript(transcript);

      if (result.success) {
        debugPrint(
          'BackgroundListeningService: Commit successful - '
          'Conversation: ${result.conversationId}, '
          'Memory: ${result.memoryId}, '
          'Action Items: ${result.actionItemIds.length}',
        );
        _currentConversationId = result.conversationId;
      } else {
        debugPrint('BackgroundListeningService: Commit failed');
      }
    } catch (e) {
      debugPrint('BackgroundListeningService: Error committing buffer: $e');
    }
  }

  Future<void> _flushBuffer() async {
    if (_transcriptBuffer.isEmpty) {
      debugPrint('BackgroundListeningService: Buffer empty, nothing to flush');
      return;
    }

    debugPrint('BackgroundListeningService: Flushing buffer (${_transcriptBuffer.length} chunks)');
    await _commitBuffer();
  }

  Future<Map<String, dynamic>> getStatus() async {
    return {
      'is_running': _isRunning,
      'buffer_size': _transcriptBuffer.length,
      'last_commit': _lastCommitTime?.toIso8601String(),
      'time_since_last_commit': timeSinceLastCommit?.inSeconds,
      'session_id': _currentSessionId,
      'conversation_id': _currentConversationId,
    };
  }

  Future<void> clearSession() async {
    debugPrint('BackgroundListeningService: Clearing session...');
    
    await stopListening();
    _transcriptBuffer.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bufferKey);
    await prefs.remove(_sessionKey);
    
    _currentSessionId = null;
    _currentConversationId = null;
    _lastCommitTime = null;
    
    debugPrint('BackgroundListeningService: Session cleared');
  }
}

class BackgroundListeningState {
  final bool isEnabled;
  final bool isRunning;
  final int bufferSize;
  final DateTime? lastCommitTime;
  final Duration? timeSinceLastCommit;
  final String? currentConversationId;
  final String? sessionId;

  const BackgroundListeningState({
    this.isEnabled = false,
    this.isRunning = false,
    this.bufferSize = 0,
    this.lastCommitTime,
    this.timeSinceLastCommit,
    this.currentConversationId,
    this.sessionId,
  });

  BackgroundListeningState copyWith({
    bool? isEnabled,
    bool? isRunning,
    int? bufferSize,
    DateTime? lastCommitTime,
    Duration? timeSinceLastCommit,
    String? currentConversationId,
    String? sessionId,
  }) {
    return BackgroundListeningState(
      isEnabled: isEnabled ?? this.isEnabled,
      isRunning: isRunning ?? this.isRunning,
      bufferSize: bufferSize ?? this.bufferSize,
      lastCommitTime: lastCommitTime ?? this.lastCommitTime,
      timeSinceLastCommit: timeSinceLastCommit ?? this.timeSinceLastCommit,
      currentConversationId: currentConversationId ?? this.currentConversationId,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

final backgroundListeningServiceProvider = Provider<BackgroundListeningService>((ref) {
  return BackgroundListeningService.instance;
});
