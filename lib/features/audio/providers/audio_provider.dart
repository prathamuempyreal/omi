import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/permission_services.dart';
import '../../memory/providers/memory_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../sessions/providers/session_provider.dart';
import '../../transcription/providers/transcription_provider.dart';
import '../services/audio_services.dart';

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

final audioProvider = NotifierProvider<AudioController, AudioState>(
  AudioController.new,
);

const _audioUnset = Object();

class AudioState {
  const AudioState({
    required this.isRecording,
    required this.isBusy,
    required this.hasMicrophonePermission,
    required this.currentSessionId,
    required this.isPcmStreaming,
    required this.memoryCountBaseline,
    this.errorMessage,
  });

  factory AudioState.initial() => const AudioState(
    isRecording: false,
    isBusy: false,
    hasMicrophonePermission: false,
    currentSessionId: null,
    isPcmStreaming: false,
    memoryCountBaseline: 0,
    errorMessage: null,
  );

  final bool isRecording;
  final bool isBusy;
  final bool hasMicrophonePermission;
  final String? currentSessionId;
  final bool isPcmStreaming;
  final int memoryCountBaseline;
  final String? errorMessage;

  AudioState copyWith({
    bool? isRecording,
    bool? isBusy,
    bool? hasMicrophonePermission,
    Object? currentSessionId = _audioUnset,
    bool? isPcmStreaming,
    int? memoryCountBaseline,
    String? errorMessage,
  }) {
    return AudioState(
      isRecording: isRecording ?? this.isRecording,
      isBusy: isBusy ?? this.isBusy,
      hasMicrophonePermission:
          hasMicrophonePermission ?? this.hasMicrophonePermission,
      currentSessionId: currentSessionId == _audioUnset
          ? this.currentSessionId
          : currentSessionId as String?,
      isPcmStreaming: isPcmStreaming ?? this.isPcmStreaming,
      memoryCountBaseline: memoryCountBaseline ?? this.memoryCountBaseline,
      errorMessage: errorMessage,
    );
  }
}

class AudioController extends Notifier<AudioState> {
  @override
  AudioState build() {
    Future.microtask(_refreshPermissionStatus);
    return AudioState.initial();
  }

  Future<void> _refreshPermissionStatus() async {
    final granted = await PermissionService.isMicGranted();
    state = state.copyWith(
      hasMicrophonePermission: granted,
      errorMessage: null,
    );
  }

  Future<void> startRecording() async {
    if (state.isRecording || state.isBusy) {
      return;
    }

    state = state.copyWith(isBusy: true, errorMessage: null);

    String? sessionId;
    try {
      final granted = await PermissionService.requestMicPermission();
      if (!granted) {
        state = state.copyWith(
          isBusy: false,
          hasMicrophonePermission: false,
          errorMessage:
              'Microphone permission is required to capture voice memories.',
        );
        return;
      }

      final transcriptController = ref.read(transcriptProvider.notifier);
      final startedListening = await transcriptController.startListening();
      if (!startedListening) {
        state = state.copyWith(
          isBusy: false,
          hasMicrophonePermission: true,
          errorMessage:
              'Speech recognition could not start. Please try again in a quieter environment.',
        );
        return;
      }

      print('AUDIO: Starting recording...');
      sessionId = await ref.read(sessionProvider.notifier).startSession();
      print('AUDIO: Session $sessionId started');
      
      var pcmStreaming = false;
      // DISABLED: PCM recorder conflicts with speech_to_text microphone access
      // PCM streaming will be re-enabled after speech recognition ends
      // For now, use fake chunk counting for UI
      /*
      if (ref.read(settingsProvider).pcmAssistEnabled) {
        pcmStreaming = await ref
            .read(audioServiceProvider)
            .startRecording(
              onAudioChunk: transcriptController.processAudioChunk,
            );
      }
      */
      transcriptController.beginAudioStream(active: false);

      // Start fake chunk counter for UI feedback (since PCM is disabled)
      _startFakeChunkCounter(transcriptController);

      final baseline = ref.read(memoryProvider).memories.length;
      state = state.copyWith(
        isBusy: false,
        isRecording: true,
        hasMicrophonePermission: true,
        currentSessionId: sessionId,
        isPcmStreaming: pcmStreaming,
        memoryCountBaseline: baseline,
        errorMessage: null,
      );
      
      print('AUDIO: Recording started with session $sessionId, memory baseline: $baseline');
    } catch (_) {
      if (sessionId != null) {
        await ref
            .read(sessionProvider.notifier)
            .endSession(sessionId, transcriptSnippet: null, memoryCount: 0);
      }
      await ref.read(transcriptProvider.notifier).stopListening();
      state = state.copyWith(
        isBusy: false,
        isRecording: false,
        currentSessionId: null,
        isPcmStreaming: false,
        memoryCountBaseline: 0,
        errorMessage: 'Recording failed to start. Please try again.',
      );
    }
  }

  Future<void> stopRecording() async {
    if (!state.isRecording && !state.isBusy) {
      return;
    }

    state = state.copyWith(isBusy: true, errorMessage: null);

    try {
      await ref.read(audioServiceProvider).stopRecording();
      final transcriptSnapshot = ref.read(transcriptProvider);
      await ref.read(transcriptProvider.notifier).stopListening();
      ref.read(transcriptProvider.notifier).finishAudioStream();

      final sessionId = state.currentSessionId;
      if (sessionId != null) {
        final transcriptText =
            transcriptSnapshot.lastCommittedTranscript ??
            transcriptSnapshot.liveTranscript;

        final memoryCount = transcriptSnapshot.lastCommittedTranscript != null
            ? ref.read(memoryProvider).memories.length - state.memoryCountBaseline
            : 0;

        print('AUDIO: Stopping session $sessionId');
        await ref
            .read(sessionProvider.notifier)
            .endSession(
              sessionId,
              transcriptSnippet: transcriptText,
              memoryCount: memoryCount,
            );
        print('AUDIO: Session ended successfully');
      }

      state = state.copyWith(
        isBusy: false,
        isRecording: false,
        currentSessionId: null,
        isPcmStreaming: false,
        memoryCountBaseline: 0,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isBusy: false,
        isRecording: false,
        currentSessionId: null,
        isPcmStreaming: false,
        memoryCountBaseline: 0,
        errorMessage: 'Recording stopped with a recoverable error.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void _startFakeChunkCounter(TranscriptController transcriptController) {
    int chunkCount = 0;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!state.isRecording) {
        timer.cancel();
        return;
      }
      chunkCount++;
      // Simulate audio chunks for UI feedback
      final fakeData = List<int>.filled(1024, 128);
      transcriptController.processAudioChunk(fakeData);
    });
  }
}
