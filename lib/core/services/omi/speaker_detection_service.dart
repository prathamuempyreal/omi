import 'package:flutter/foundation.dart';

class SpeakerDetectionService {
  SpeakerDetectionService._();

  static SpeakerDetectionService? _instance;
  static SpeakerDetectionService get instance =>
      _instance ??= SpeakerDetectionService._();

  final Map<String, SpeakerInfo> _speakers = {};

  static const String defaultUserSpeaker = 'User';
  static const String defaultOtherSpeaker = 'Other';

  List<SpeakerSegment> detectSpeakers(String transcript) {
    debugPrint('SpeakerDetection: Analyzing transcript for speakers');

    final segments = <SpeakerSegment>[];

    final speakerPatterns = [
      RegExp(r'^([A-Za-z]+):\s*(.+)$', multiLine: true),
      RegExp(r'([A-Za-z]+)\s+says?[:\s]+"?([^"]+)"?', multiLine: true),
      RegExp(r'([A-Za-z]+)\s+(?:said|told|asked)[:\s]+"?([^"]+)"?', multiLine: true),
    ];

    final lines = transcript.split(RegExp(r'[\n\r]+'));

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      bool matched = false;
      for (final pattern in speakerPatterns) {
        final match = pattern.firstMatch(trimmed);
        if (match != null) {
          final speaker = match.group(1)!;
          final content = match.group(2) ?? '';

          if (_isValidSpeaker(speaker)) {
            segments.add(SpeakerSegment(
              speaker: _normalizeSpeakerName(speaker),
              text: content.trim(),
              timestamp: DateTime.now(),
            ));
            _updateSpeakerInfo(speaker);
            matched = true;
            break;
          }
        }
      }

      if (!matched && trimmed.isNotEmpty) {
        if (segments.isNotEmpty) {
          final lastSpeaker = segments.last.speaker;
          final updatedText = '${segments.last.text} $trimmed';
          segments[segments.length - 1] = SpeakerSegment(
            speaker: lastSpeaker,
            text: updatedText.trim(),
            timestamp: segments.last.timestamp,
          );
        } else {
          segments.add(SpeakerSegment(
            speaker: defaultUserSpeaker,
            text: trimmed,
            timestamp: DateTime.now(),
          ));
        }
      }
    }

    _identifyDistinctSpeakers(segments);

    debugPrint('SpeakerDetection: Found ${_speakers.length} speakers');
    for (final entry in _speakers.entries) {
      debugPrint('  - ${entry.key}: ${entry.value.utteranceCount} utterances');
    }

    return segments;
  }

  bool _isValidSpeaker(String speaker) {
    if (speaker.length < 2 || speaker.length > 20) return false;

    final invalidSpeakers = {
      'said', 'says', 'tell', 'tells', 'asked',
      'hello', 'hey', 'thanks', 'please',
      'okay', 'ok', 'yes', 'no', 'yeah',
      'the', 'and', 'but', 'for', 'with',
      'what', 'when', 'where', 'why', 'how',
    };

    return !invalidSpeakers.contains(speaker.toLowerCase());
  }

  String _normalizeSpeakerName(String speaker) {
    final lower = speaker.toLowerCase();

    if (lower == 'me' || lower == 'i' || lower == 'myself') {
      return defaultUserSpeaker;
    }

    if (lower.contains('client') || lower.contains('customer')) {
      return 'Client';
    }

    if (lower.contains('manager') || lower.contains('boss')) {
      return 'Manager';
    }

    if (lower.contains('friend') || lower.contains('mom') || lower.contains('dad') ||
        lower.contains('sister') || lower.contains('brother')) {
      return 'Family/Friend';
    }

    return speaker[0].toUpperCase() + speaker.substring(1).toLowerCase();
  }

  void _updateSpeakerInfo(String speaker) {
    final normalized = _normalizeSpeakerName(speaker);

    _speakers.putIfAbsent(normalized, () => SpeakerInfo(name: normalized));
    _speakers[normalized]!.utteranceCount++;
  }

  void _identifyDistinctSpeakers(List<SpeakerSegment> segments) {
    final speakerNames = segments.map((s) => s.speaker).toSet();

    debugPrint('SpeakerDetection: Distinct speakers: $speakerNames');

    if (speakerNames.length >= 2) {
      final speakerCounts = <String, int>{};
      for (final segment in segments) {
        speakerCounts[segment.speaker] = (speakerCounts[segment.speaker] ?? 0) + 1;
      }

      final sortedSpeakers = speakerCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedSpeakers.isNotEmpty) {
        final primarySpeaker = sortedSpeakers.first.key;
        _speakers[primarySpeaker]?.isPrimary = true;
        debugPrint('SpeakerDetection: Primary speaker identified as: $primarySpeaker');
      }
    }
  }

  SpeakerInfo? getSpeakerInfo(String name) {
    return _speakers[name];
  }

  List<SpeakerInfo> getAllSpeakers() {
    return _speakers.values.toList()
      ..sort((a, b) => b.utteranceCount.compareTo(a.utteranceCount));
  }

  void clearSpeakers() {
    _speakers.clear();
    debugPrint('SpeakerDetection: Cleared all speaker info');
  }

  List<SpeakerSegment> mergeContinuousSegments(List<SpeakerSegment> segments) {
    if (segments.isEmpty) return [];

    final merged = <SpeakerSegment>[];
    SpeakerSegment? current;

    for (final segment in segments) {
      if (current == null || current.speaker != segment.speaker) {
        if (current != null) merged.add(current);
        current = segment;
      } else {
        current = SpeakerSegment(
          speaker: current.speaker,
          text: '${current.text} ${segment.text}',
          timestamp: current.timestamp,
        );
      }
    }

    if (current != null) merged.add(current);

    return merged;
  }
}

class SpeakerSegment {
  final String speaker;
  final String text;
  final DateTime timestamp;

  SpeakerSegment({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'speaker': speaker,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };
}

class SpeakerInfo {
  final String name;
  int utteranceCount;
  bool isPrimary;
  String? inferredRole;

  SpeakerInfo({
    required this.name,
    this.utteranceCount = 0,
    this.isPrimary = false,
    this.inferredRole,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'utterance_count': utteranceCount,
    'is_primary': isPrimary,
    'inferred_role': inferredRole,
  };
}
