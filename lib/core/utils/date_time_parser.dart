import 'package:intl/intl.dart';

class DateParseResult {
  const DateParseResult({required this.scheduledAt, required this.wasAdjusted});

  final DateTime? scheduledAt;
  final bool wasAdjusted;
}

class ScheduleParser {
  static DateParseResult parse(String? raw, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (raw == null || raw.trim().isEmpty) {
      return const DateParseResult(scheduledAt: null, wasAdjusted: false);
    }

    final value = raw.trim();
    DateTime? parsed = DateTime.tryParse(value)?.toLocal();

    parsed ??= _tryRelativeExpressions(value, current);
    parsed ??= _tryWeekdayPatterns(value, current);
    parsed ??= _tryKnownFormats(value, current);

    if (parsed == null) {
      return const DateParseResult(scheduledAt: null, wasAdjusted: false);
    }

    if (parsed.isBefore(current.add(const Duration(minutes: 1)))) {
      return DateParseResult(
        scheduledAt: current.add(const Duration(minutes: 10)),
        wasAdjusted: true,
      );
    }

    return DateParseResult(scheduledAt: parsed, wasAdjusted: false);
  }

  static DateTime? _tryRelativeExpressions(String value, DateTime now) {
    final lower = value.toLowerCase();
    final time = _extractTime(lower);

    final minuteMatch = RegExp(
      r'after\s+(\d+)\s*(minute|min|m)s?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (minuteMatch != null) {
      final minutes = int.tryParse(minuteMatch.group(1)!) ?? 0;
      return now.add(Duration(minutes: minutes));
    }

    final hourMatch = RegExp(
      r'in\s+(\d+)\s*(hour|hr|h)s?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (hourMatch != null) {
      final hours = int.tryParse(hourMatch.group(1)!) ?? 0;
      return now.add(Duration(hours: hours));
    }

    final dayMatch = RegExp(
      r'in\s+(\d+)\s*(day|d)s?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (dayMatch != null) {
      final days = int.tryParse(dayMatch.group(1)!) ?? 0;
      return now.add(Duration(days: days));
    }

    if (lower.contains('tomorrow')) {
      final base = now.add(const Duration(days: 1));
      return DateTime(
        base.year,
        base.month,
        base.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    }

    if (lower.contains('today')) {
      return DateTime(
        now.year,
        now.month,
        now.day,
        time?.hour ?? now.hour,
        time?.minute ?? now.minute,
      );
    }

    if (time != null && time.hour > 0) {
      if (time.hour >= 1 && time.hour <= 12 && time.minute == 0) {
        return DateTime(now.year, now.month, now.day, time.hour, 0);
      }
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    }

    return null;
  }

  static DateTime? _tryWeekdayPatterns(String value, DateTime now) {
    final lower = value.toLowerCase();
    final time = _extractTime(lower);

    const weekdays = {
      'sunday': DateTime.sunday,
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
    };

    for (final entry in weekdays.entries) {
      if (!lower.contains(entry.key) && !lower.contains('next ${entry.key}')) {
        continue;
      }

      var targetDay = entry.value;
      var daysToAdd = targetDay - now.weekday;

      if (lower.contains('next ') || daysToAdd <= 0) {
        if (daysToAdd <= 0) {
          daysToAdd += 7;
        }
      }

      final base = now.add(Duration(days: daysToAdd));
      return DateTime(
        base.year,
        base.month,
        base.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    }

    return null;
  }

  static DateTime? _tryKnownFormats(String value, DateTime current) {
    const formats = [
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-ddTHH:mm',
      'yyyy-MM-dd',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy',
      'MMM d, yyyy h:mm a',
      'MMM d yyyy h:mm a',
      'MMMM d, yyyy h:mm a',
      'h:mm a',
      'HH:mm',
    ];

    for (final format in formats) {
      try {
        final parsed = DateFormat(format).parseLoose(value);
        if (format == 'h:mm a' || format == 'HH:mm') {
          return DateTime(
            current.year,
            current.month,
            current.day,
            parsed.hour,
            parsed.minute,
          );
        }
        return parsed;
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static DateTime? _extractTime(String value) {
    final match = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }

    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final meridiem = match.group(3);

    if (hour == null) {
      return null;
    }

    if (meridiem == 'pm' && hour < 12) {
      hour += 12;
    } else if (meridiem == 'am' && hour == 12) {
      hour = 0;
    }

    return DateTime(0, 1, 1, hour, minute);
  }
}

class DateTimeParser {
  static DateParseResult parse(String? raw, {DateTime? now}) {
    return ScheduleParser.parse(raw, now: now);
  }

  static DateTime? parseFromText(String text) {
    final now = DateTime.now();
    final lower = text.toLowerCase();

    final afterMinutesMatch = RegExp(
      r'after\s+(\d+)\s*(minute|min|m)s?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (afterMinutesMatch != null) {
      final minutes = int.tryParse(afterMinutesMatch.group(1)!) ?? 1;
      print("🔍 PARSER: Extracted 'after $minutes minutes'");
      return now.add(Duration(minutes: minutes));
    }

    final inMinutesMatch = RegExp(
      r'in\s+(\d+)\s*(minute|min|m)s?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (inMinutesMatch != null) {
      final minutes = int.tryParse(inMinutesMatch.group(1)!) ?? 1;
      print("🔍 PARSER: Extracted 'in $minutes minutes'");
      return now.add(Duration(minutes: minutes));
    }

    final afterHoursMatch = RegExp(
      r'after\s+(\d+)\s*(hour|hr|h)s?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (afterHoursMatch != null) {
      final hours = int.tryParse(afterHoursMatch.group(1)!) ?? 1;
      print("🔍 PARSER: Extracted 'after $hours hours'");
      return now.add(Duration(hours: hours));
    }

    final inHoursMatch = RegExp(
      r'in\s+(\d+)\s*(hour|hr|h)s?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (inHoursMatch != null) {
      final hours = int.tryParse(inHoursMatch.group(1)!) ?? 1;
      print("🔍 PARSER: Extracted 'in $hours hours'");
      return now.add(Duration(hours: hours));
    }

    final inDaysMatch = RegExp(
      r'in\s+(\d+)\s*(day|d)s?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (inDaysMatch != null) {
      final days = int.tryParse(inDaysMatch.group(1)!) ?? 1;
      print("🔍 PARSER: Extracted 'in $days days'");
      return now.add(Duration(days: days));
    }

    final timeMatch = RegExp(
      r'(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    ).firstMatch(lower);
    
    if (lower.contains('tomorrow') && timeMatch != null) {
      final base = now.add(const Duration(days: 1));
      var hour = int.tryParse(timeMatch.group(1)!) ?? 9;
      final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final meridiem = timeMatch.group(3);
      if (meridiem == 'pm' && hour < 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
      print("🔍 PARSER: Extracted 'tomorrow at $hour:$minute'");
      return DateTime(base.year, base.month, base.day, hour, minute);
    }

    if (timeMatch != null && !lower.contains('tomorrow') && !lower.contains('today')) {
      var hour = int.tryParse(timeMatch.group(1)!) ?? 9;
      final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final meridiem = timeMatch.group(3);
      if (meridiem == 'pm' && hour < 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
      print("🔍 PARSER: Extracted time '$hour:$minute'");
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    print("🔍 PARSER: No datetime pattern found in text");
    return null;
  }

  static DateTime? _tryKnownFormats(String value, DateTime current) {
    return ScheduleParser.parse(value, now: current).scheduledAt;
  }

  static DateTime? _tryRelativePatterns(String value, DateTime now) {
    return ScheduleParser.parse(value, now: now).scheduledAt;
  }

  static DateTime? _extractTime(String value) {
    return ScheduleParser.parse(value, now: DateTime.now()).scheduledAt;
  }
}
