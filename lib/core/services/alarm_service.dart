import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.omi/alarm_service',
  );
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;
  }

  static Future<void> playAlarm() async {
    await initialize();

    try {
      await _channel.invokeMethod<void>('startAlarm');
      debugPrint('Alarm started');
    } catch (e) {
      debugPrint('Failed to start alarm: $e');
    }
  }

  static Future<void> stopAlarm() async {
    try {
      debugPrint('AlarmService: stopAlarm called');
      await _channel.invokeMethod<void>('stopAlarm');
      debugPrint('Alarm stopped');
    } catch (e) {
      debugPrint('Failed to stop alarm: $e');
    }
  }

  static Future<void> snooze(Duration duration) async {
    await stopAlarm();
    debugPrint('AlarmService: Snoozed for ${duration.inMinutes} minutes');
  }
}
