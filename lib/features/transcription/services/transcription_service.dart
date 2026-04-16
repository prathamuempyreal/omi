import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum TranscriptionStatus { idle, initializing, listening, error }

class TranscriptionService {
  TranscriptionService();

  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isIntentionalStop = false;

  String? _lastError;
  String? _lastStatus;
  String? _selectedLocale;

  List<LocaleName> _availableLocales = [];

  final _statusController = StreamController<TranscriptionStatus>.broadcast();
  final _resultController =
      StreamController<SpeechRecognitionResult>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  void Function(String status)? _onStatusCallback;
  void Function(String error)? _onErrorCallback;
  void Function(String text, bool isFinal)? _onResultCallback;

  Stream<TranscriptionStatus> get statusStream => _statusController.stream;
  Stream<SpeechRecognitionResult> get resultStream => _resultController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  String? get selectedLocale => _selectedLocale;
  List<LocaleName> get availableLocales => _availableLocales;

  void setCallbacks({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
    void Function(String text, bool isFinal)? onResult,
  }) {
    _onStatusCallback = onStatus;
    _onErrorCallback = onError;
    _onResultCallback = onResult;
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _statusController.add(TranscriptionStatus.initializing);

    final available = await _speech.initialize(
      onStatus: _handleStatus,
      onError: _handleError,
      debugLogging: true,
    );

    _isInitialized = available;

    if (!available) {
      _lastError = 'Speech not available';
      _errorController.add(_lastError!);
      _statusController.add(TranscriptionStatus.error);
      return false;
    }

    await _loadAvailableLocales();
    _selectBestLocale();

    _statusController.add(TranscriptionStatus.idle);
    return true;
  }

  Future<void> _loadAvailableLocales() async {
    try {
      _availableLocales = await _speech.locales();
      print("🔥 LOCALES: ${_availableLocales.map((l) => l.name).join(', ')}");
    } catch (e) {
      print("🔥 Failed to load locales: $e");
    }
  }

  void _selectBestLocale() async {
    if (_availableLocales.isEmpty) {
      print("🔥 No locales available, using system default");
      _selectedLocale = null;
      return;
    }

    LocaleName? systemLocale;
    try {
      systemLocale = await _speech.systemLocale();
    } catch (e) {
      print("🔥 systemLocale() error: $e");
    }

    print("🔥 System locale: ${systemLocale?.localeId}");

    _selectedLocale = systemLocale?.localeId;

    if (_selectedLocale == null) {
      const preferredLocales = ['en_US', 'en_GB', 'en_IN', 'hi_IN', 'en'];

      for (final preferred in preferredLocales) {
        final match = _availableLocales.where(
          (l) =>
              l.localeId.startsWith(preferred) ||
              l.localeId.toLowerCase() == preferred.toLowerCase(),
        );
        if (match.isNotEmpty) {
          _selectedLocale = match.first.localeId;
          print("🔥 Selected locale: $_selectedLocale");
          return;
        }
      }

      _selectedLocale = _availableLocales.first.localeId;
      print("🔥 Fallback to first locale: $_selectedLocale");
    }
  }

  Future<bool> startListening() async {
    if (_isListening) return true;

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    _isIntentionalStop = false;
    _lastError = null;

    try {
      _isListening = true;
      _statusController.add(TranscriptionStatus.listening);

      await _speech.listen(
        onResult: _handleResult,
        localeId: _selectedLocale,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: (level) {
          print("🎤 SOUND LEVEL: $level");
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );

      print("🔥 Listening started with locale: $_selectedLocale");
      return true;
    } catch (e) {
      _lastError = e.toString();
      _errorController.add(_lastError!);
      _isListening = false;
      _statusController.add(TranscriptionStatus.error);
      return false;
    }
  }

  Future<void> stopListening() async {
    _isIntentionalStop = true;

    if (!_isListening) return;

    _isListening = false;

    await _speech.stop();
    _statusController.add(TranscriptionStatus.idle);

    print("🔥 Stopped");
  }

  void cancelListening() {
    _isIntentionalStop = true;
    _isListening = false;
    _speech.cancel();
    _statusController.add(TranscriptionStatus.idle);
  }

  void _handleStatus(String status) {
    _lastStatus = status;
    print("🔥 STATUS: $status");

    _onStatusCallback?.call(status);

    if (status == "listening") {
      _isListening = true;
      _statusController.add(TranscriptionStatus.listening);
    } else if (status == "notListening" || status == "done") {
      if (!_isIntentionalStop) {
        _isListening = false;
        _statusController.add(TranscriptionStatus.idle);
      }
    }
  }

  void _handleError(SpeechRecognitionError error) {
    final errorMsg = error.errorMsg.toString();

    print("🔥 ERROR: $errorMsg");

    final msg = errorMsg.toLowerCase();
    if (msg.contains('language_unavailable')) {
      print("🔥 Language unavailable - will retry with system locale");
    }

    _onErrorCallback?.call(errorMsg);
    _errorController.add(errorMsg);

    _isListening = false;
    _statusController.add(TranscriptionStatus.idle);
  }

  void _handleResult(SpeechRecognitionResult result) {
    print("🔥 SERVICE RAW: '${result.recognizedWords}' (final: ${result.finalResult})");
    print("🔥 SERVICE RESULT: '${result.recognizedWords}' (final: ${result.finalResult})");

    _resultController.add(result);
    _onResultCallback?.call(result.recognizedWords, result.finalResult);
  }

  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _availableLocales;
  }

  void dispose() {
    _speech.cancel();
    _statusController.close();
    _resultController.close();
    _errorController.close();
  }
}
