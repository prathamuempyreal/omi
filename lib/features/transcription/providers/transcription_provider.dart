import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/omi/omi_sync_service.dart';
import '../../audio/providers/audio_provider.dart';
import '../../memory/providers/memory_provider.dart';
import '../../reminder/providers/reminder_provider.dart';
import '../../sessions/providers/session_provider.dart';
import '../services/transcription_service.dart';

final transcriptionServiceProvider = Provider<TranscriptionService>(
  (ref) => TranscriptionService(),
);

final transcriptProvider =
    NotifierProvider<TranscriptController, TranscriptState>(
      TranscriptController.new,
    );

class TranscriptState {
  const TranscriptState({
    required this.liveTranscript,
    required this.isListening,
    required this.isProcessing,
    required this.audioChunkCount,
    required this.audioLevel,
    required this.isPcmStreaming,
    this.errorMessage,
    this.lastCommittedTranscript,
  });

  factory TranscriptState.initial() => const TranscriptState(
    liveTranscript: '',
    isListening: false,
    isProcessing: false,
    audioChunkCount: 0,
    audioLevel: 0,
    isPcmStreaming: false,
  );

  final String liveTranscript;
  final bool isListening;
  final bool isProcessing;
  final int audioChunkCount;
  final double audioLevel;
  final bool isPcmStreaming;
  final String? errorMessage;
  final String? lastCommittedTranscript;

  TranscriptState copyWith({
    String? liveTranscript,
    bool? isListening,
    bool? isProcessing,
    int? audioChunkCount,
    double? audioLevel,
    bool? isPcmStreaming,
    String? errorMessage,
    String? lastCommittedTranscript,
  }) {
    return TranscriptState(
      liveTranscript: liveTranscript ?? this.liveTranscript,
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      audioChunkCount: audioChunkCount ?? this.audioChunkCount,
      audioLevel: audioLevel ?? this.audioLevel,
      isPcmStreaming: isPcmStreaming ?? this.isPcmStreaming,
      errorMessage: errorMessage,
      lastCommittedTranscript:
          lastCommittedTranscript ?? this.lastCommittedTranscript,
    );
  }
}

class TranscriptController extends Notifier<TranscriptState> {
  Timer? _statusDebounce;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _resultSubscription;
  StreamSubscription? _errorSubscription;

  @override
  TranscriptState build() {
    final service = ref.read(transcriptionServiceProvider);

    service.setCallbacks(
      onStatus: _handleStatus,
      onError: _handleError,
      onResult: _handleResult,
    );

    _statusSubscription = service.statusStream.listen((status) {
      if (status == TranscriptionStatus.listening) {
        state = state.copyWith(isListening: true);
      } else if (status == TranscriptionStatus.idle) {
        state = state.copyWith(isListening: false);
      }
    });

    ref.onDispose(() {
      _statusDebounce?.cancel();
      _statusSubscription?.cancel();
      _resultSubscription?.cancel();
      _errorSubscription?.cancel();
    });

    return TranscriptState.initial();
  }

  Future<bool> startListening() async {
    state = TranscriptState.initial().copyWith(isListening: true);

    final started = await ref
        .read(transcriptionServiceProvider)
        .startListening();

    if (!started) {
      state = state.copyWith(
        isListening: false,
        errorMessage:
            ref.read(transcriptionServiceProvider).lastError ??
            'Speech recognition was not available on this device.',
      );
    }

    return started;
  }

  Future<void> stopListening() async {
    await _commitPendingTranscriptIfNeeded();
    await ref.read(transcriptionServiceProvider).stopListening();
    state = state.copyWith(isListening: false, isPcmStreaming: false);
  }

  void beginAudioStream({required bool active}) {
    state = state.copyWith(
      isPcmStreaming: active,
      audioChunkCount: active ? 0 : state.audioChunkCount,
      audioLevel: 0,
    );
  }

  void finishAudioStream() {
    state = state.copyWith(isPcmStreaming: false, audioLevel: 0);
  }

  void processAudioChunk(List<int> data) {
    state = state.copyWith(
      audioChunkCount: state.audioChunkCount + 1,
      audioLevel: _estimateAudioLevel(data),
      errorMessage: null,
    );
  }

  void _handleStatus(String status) {
    print("🔥 PROVIDER STATUS: $status");
    _statusDebounce?.cancel();
    _statusDebounce = Timer(const Duration(milliseconds: 80), () {
      final listening = status.toLowerCase().contains('listening');
      if (listening != state.isListening) {
        state = state.copyWith(isListening: listening);
      }
    });
  }

  void _handleError(String errorMessage) {
    print("🔥 PROVIDER ERROR: $errorMessage");
    state = state.copyWith(isListening: false, errorMessage: errorMessage);
  }

  Future<void> _handleResult(String text, bool isFinal) async {
    print("🔥 PROVIDER RESULT: $text | final: $isFinal");

    if (text.isEmpty) {
      return;
    }

    final normalized = _normalizeTranscript(text);
    print("🔥 NORMALIZED: $normalized");

    if (normalized.isEmpty) return;

    state = state.copyWith(liveTranscript: normalized, errorMessage: null);

    if (!isFinal) {
      print("🔥 PARTIAL RESULT - showing only");
      return;
    }

    if (normalized.length < 3) {
      print("🔥 TOO SHORT, SKIPPING");
      return;
    }

    print("🔥 COMMITTING FINAL: $normalized");
    print("🔥 HANDLE RESULT: $normalized | final: true");
    await _commitTranscript(normalized);
  }

  void clear() {
    state = TranscriptState.initial();
  }

  Future<void> _commitPendingTranscriptIfNeeded() async {
    final candidate = _normalizeTranscript(state.liveTranscript);
    if (candidate.isEmpty || candidate.length < 3) {
      return;
    }
    if (state.lastCommittedTranscript == candidate) {
      print('🔥 SKIP DUPLICATE COMMIT (pending was already committed)');
      return;
    }
    await _commitTranscript(candidate);
  }

  Future<void> _commitTranscript(String normalized) async {
    print("🔥 FINAL COMMITTING: $normalized");

    state = state.copyWith(
      isProcessing: true,
      lastCommittedTranscript: normalized,
      liveTranscript: normalized,
    );

    try {
      final sessionController = ref.read(sessionProvider.notifier);
      await sessionController.appendTranscript(normalized);

      // Process transcript to create Conversation, Memory, and Action Items in Omi
      final omiSyncService = ref.read(omiSyncServiceProvider);
      final syncResult = await omiSyncService.processTranscript(normalized);
      
      debugPrint('Omi sync result - Conversation: ${syncResult.conversationId}, Memory: ${syncResult.memoryId}, Action Items: ${syncResult.actionItemIds.length}');

      // Also create memory locally for display
      await ref.read(memoryProvider.notifier).processTranscript(normalized);
      
      // Refresh reminders to pick up any action items created by OmiSyncService
      await ref.read(reminderProvider.notifier).loadReminders();

      await sessionController.incrementMemoryCount();

      state = state.copyWith(isProcessing: false);

      final audioController = ref.read(audioProvider.notifier);
      await audioController.stopRecording();
    } catch (e) {
      print("🔥 ERROR in _commitTranscript: $e");
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Transcript captured, but processing failed safely.',
      );
    }
  }

  String _normalizeTranscript(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  double _estimateAudioLevel(List<int> data) {
    if (data.length < 2) {
      return 0;
    }

    var peak = 0;
    for (var index = 0; index < data.length - 1; index += 2) {
      final sample = data[index] | (data[index + 1] << 8);
      final signed = sample > 32767 ? sample - 65536 : sample;
      final magnitude = signed.abs();
      if (magnitude > peak) {
        peak = magnitude;
      }
    }

    return (peak / 32767).clamp(0, 1);
  }
}
