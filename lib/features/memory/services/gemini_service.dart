import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final geminiProvider = Provider<GeminiService>((ref) => GeminiService());

class MemoryExtractionResult {
  const MemoryExtractionResult({
    required this.type,
    required this.content,
    required this.datetimeRaw,
    required this.importance,
    required this.usedFallback,
    required this.shouldRetry,
  });

  final String type;
  final String content;
  final String? datetimeRaw;
  final int importance;
  final bool usedFallback;
  final bool shouldRetry;
}

class GeminiService {
  GeminiService();

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  String? get _apiKey => dotenv.env['GEMINI_API_KEY'];

  Future<MemoryExtractionResult> extractMemory(String transcript) async {
    final fallback = _fallbackFromTranscript(transcript, shouldRetry: true);

    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('GEMINI: No API key found in .env, using fallback');
      return fallback;
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        debugPrint('GEMINI: Attempt $attempt with transcript: ${transcript.substring(0, transcript.length > 50 ? 50 : transcript.length)}...');

        final response = await http
            .post(
              Uri.parse('$_baseUrl?key=$_apiKey'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(_buildBody(transcript)),
            )
            .timeout(const Duration(seconds: 18));

        debugPrint('GEMINI: Response status: ${response.statusCode}');

        if (response.statusCode == 400) {
          debugPrint('GEMINI: 400 Bad Request - trying with different model');
          if (attempt == 0) {
            continue;
          }
        }

        if (response.statusCode == 403) {
          debugPrint('GEMINI: 403 Forbidden - API key issue');
        }

        if (response.statusCode == 404) {
          debugPrint('GEMINI: 404 Not Found - model may not exist');
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (attempt == 2) {
            return fallback;
          }
          continue;
        }

        final decoded = jsonDecode(response.body);
        final text = _extractText(decoded);
        debugPrint('GEMINI: Extracted text: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');

        final parsed = _safeParseJson(text);
        if (parsed == null) {
          debugPrint('GEMINI: Failed to parse JSON response');
          if (attempt == 2) {
            return fallback;
          }
          continue;
        }

        debugPrint('GEMINI: Successfully parsed JSON');
        return MemoryExtractionResult(
          type: _normalizeType(parsed['type']?.toString()),
          content: (parsed['content']?.toString().trim().isNotEmpty ?? false)
              ? parsed['content'].toString().trim()
              : transcript.trim(),
          datetimeRaw: _normalizeDate(parsed['datetime_raw']?.toString()),
          importance: _normalizeImportance(parsed['importance']),
          usedFallback: false,
          shouldRetry: false,
        );
      } on SocketException {
        debugPrint('GEMINI: SocketException - network error');
        if (attempt == 2) {
          return fallback;
        }
      } on TimeoutException {
        debugPrint('GEMINI: TimeoutException');
        if (attempt == 2) {
          return fallback;
        }
      } on FormatException {
        debugPrint('GEMINI: FormatException');
        if (attempt == 2) {
          return fallback;
        }
      } catch (e) {
        debugPrint('GEMINI: Unexpected error: $e');
        if (attempt == 2) {
          return fallback;
        }
      }

      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }

    return fallback;
  }

  Map<String, dynamic> _buildBody(String transcript) {
    return {
      'contents': [
        {
          'parts': [
            {
              'text':
                  '''
You are a memory extraction engine for a voice assistant.
Return only JSON matching the provided schema.

Classify the transcript using this priority (check in order, use first match):

1. FACT: Personal information or preferences. Match: "my favourite", "my favorite", "my passport", "my phone number", "my address", "my birthday", "my age", "my email"

2. EVENT: Meetings, appointments, interviews, classes, trips, parties, or future date/time phrases. Match: "meeting", "appointment", "interview", "class", "trip", "party", "tomorrow at", "next monday", or phrases like "at 5 pm"

3. TASK: Things the user needs to do. Match: "I need to", "I have to", "I must", "finish", "complete", "submit", "create", "buy"

4. REMINDER: Only when explicitly asking for a reminder. Match: "remind me", "set a reminder", "wake me up", "remind me after"

5. NOTE: Everything else

IMPORTANT: Do NOT classify as reminder just because text contains "remember". "Remember my favourite colour is red" = fact

Examples:
- "my favourite colour is red" -> fact
- "remember my favourite colour is red" -> fact
- "I have a meeting with John tomorrow at 5 pm" -> event
- "I need to finish my project tomorrow" -> task
- "remind me to drink water after 1 minute" -> reminder
- "set a reminder to call mom" -> reminder

Rules:
- type must be one of: fact, event, task, reminder, note
- content should be concise but preserve meaning
- datetime_raw should be ISO-8601 when a clear date/time is present, otherwise null
- importance must be an integer between 1 and 5

Transcript:
$transcript
''',
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
        'responseJsonSchema': {
          'type': 'object',
          'properties': {
            'type': {
              'type': 'string',
              'enum': ['fact', 'event', 'task', 'reminder', 'note'],
            },
            'content': {'type': 'string'},
            'datetime_raw': {
              'type': ['string', 'null'],
            },
            'importance': {'type': 'integer'},
          },
          'required': ['type', 'content', 'datetime_raw', 'importance'],
        },
      },
    };
  }

  String _extractText(dynamic decoded) {
    final candidates = decoded is Map<String, dynamic>
        ? decoded['candidates'] as List<dynamic>?
        : null;
    final firstCandidate = candidates?.isNotEmpty == true
        ? candidates!.first
        : null;
    final content = firstCandidate is Map<String, dynamic>
        ? firstCandidate['content'] as Map<String, dynamic>?
        : null;
    final parts = content?['parts'] as List<dynamic>?;
    final firstPart = parts?.isNotEmpty == true ? parts!.first : null;
    return firstPart is Map<String, dynamic>
        ? '${firstPart['text'] ?? ''}'
        : '';
  }

  Map<String, dynamic>? _safeParseJson(String text) {
    final sanitized = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    if (sanitized.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(sanitized) as Map<String, dynamic>;
    } catch (_) {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(sanitized);
      if (match == null) {
        return null;
      }
      try {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
  }

  MemoryExtractionResult _fallbackFromTranscript(
    String transcript, {
    required bool shouldRetry,
  }) {
    final lower = transcript.toLowerCase();

    String type = 'note';

    if (_isFact(lower)) {
      type = 'fact';
    } else if (_isEvent(lower)) {
      type = 'event';
    } else if (_isTask(lower)) {
      type = 'task';
    } else if (_isReminder(lower)) {
      type = 'reminder';
    }

    final importance = lower.contains('urgent') || lower.contains('important')
        ? 5
        : lower.contains('tomorrow') || lower.contains('today')
        ? 4
        : 3;

    return MemoryExtractionResult(
      type: type,
      content: transcript.trim(),
      datetimeRaw: _extractFallbackDate(lower),
      importance: importance,
      usedFallback: true,
      shouldRetry: shouldRetry,
    );
  }

  bool _isFact(String text) {
    return text.contains('my favourite') ||
        text.contains('my favorite') ||
        text.contains('my passport') ||
        text.contains('my phone number') ||
        text.contains('my address') ||
        text.contains('my birthday') ||
        text.contains('my age') ||
        text.contains('my email');
  }

  bool _isEvent(String text) {
    return text.contains('meeting') ||
        text.contains('appointment') ||
        text.contains('interview') ||
        text.contains('class ') ||
        text.contains('trip') ||
        text.contains('party');
  }

  bool _hasDayOfWeek(String text) {
    final days = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
      'next monday', 'next tuesday', 'next wednesday', 'next thursday', 'next friday',
      'next saturday', 'next sunday',
    ];
    for (final day in days) {
      if (text.contains(day)) return true;
    }
    return false;
  }

  bool _hasTimePattern(String text) {
    final timePattern = RegExp(r'\bat\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?', caseSensitive: false);
    return timePattern.hasMatch(text);
  }

  bool _isTask(String text) {
    return text.contains('i need to') ||
        text.contains('i have to') ||
        text.contains('i must') ||
        text.contains('finish') ||
        text.contains('complete') ||
        text.contains('submit') ||
        text.contains('create ') ||
        text.contains('buy ');
  }
  bool _isReminder(String text) {
    return text.contains('remind me') ||
        text.contains('set a reminder') ||
        text.contains('wake me up') ||
        text.contains('remind me after');
  }

  String? _extractFallbackDate(String transcript) {
    final now = DateTime.now();
    final timeMatch = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s?(am|pm)',
    ).firstMatch(transcript);

    String buildWith(DateTime date) {
      if (timeMatch == null) {
        return DateTime(date.year, date.month, date.day, 9).toIso8601String();
      }

      var hour = int.parse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final suffix = timeMatch.group(3);
      if (suffix == 'pm' && hour < 12) {
        hour += 12;
      }
      if (suffix == 'am' && hour == 12) {
        hour = 0;
      }

      return DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      ).toIso8601String();
    }

    if (transcript.contains('tomorrow')) {
      return buildWith(now.add(const Duration(days: 1)));
    }

    if (transcript.contains('today') || timeMatch != null) {
      return buildWith(now);
    }

    return null;
  }

  int _normalizeImportance(dynamic value) {
    final parsed = int.tryParse('$value') ?? 3;
    if (parsed < 1) {
      return 1;
    }
    if (parsed > 5) {
      return 5;
    }
    return parsed;
  }

  String _normalizeType(String? value) {
    const allowed = {'reminder', 'task', 'fact', 'note', 'event'};
    if (value != null && allowed.contains(value.toLowerCase())) {
      return value.toLowerCase();
    }
    return 'note';
  }

  String? _normalizeDate(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == 'null') {
      return null;
    }
    return value.trim();
  }
}
