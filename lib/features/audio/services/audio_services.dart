import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class AudioService {
  AudioService();

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _streamSubscription;
  bool _isStreaming = false;

  bool get isStreaming => _isStreaming;

  Future<bool> startRecording({
    required void Function(List<int> data) onAudioChunk,
  }) async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        return false;
      }

      if (_isStreaming) {
        await stopRecording();
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      await _streamSubscription?.cancel();
      _streamSubscription = stream.listen(
        onAudioChunk,
        onError: (_) {},
        cancelOnError: false,
      );
      _isStreaming = true;
      return true;
    } catch (_) {
      _isStreaming = false;
      return false;
    }
  }

  Future<void> stopRecording() async {
    try {
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      if (_isStreaming) {
        await _recorder.stop();
      }
    } finally {
      _isStreaming = false;
    }
  }
}
