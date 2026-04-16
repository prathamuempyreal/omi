import 'dart:convert';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../data/models/reminder_record.dart';
import 'alarm_service.dart';
import 'notifications_services.dart';

final alarmManagerProvider = Provider<AlarmManager>((ref) {
  return AlarmManager.instance;
});

const String _alarmDataKey = 'active_alarm_data';
const String _pendingAlarmRouteKey = 'pending_alarm_route';

class AlarmData {
  final int id;
  final String title;
  final String body;

  AlarmData({
    required this.id,
    required this.title,
    required this.body,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
  };

  factory AlarmData.fromJson(Map<String, dynamic> json) => AlarmData(
    id: json['id'] as int,
    title: json['title'] as String,
    body: json['body'] as String,
  );
}

Future<void> _saveAlarmData(AlarmData data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alarmDataKey, jsonEncode(data.toJson()));
    debugPrint('ALARM DATA: Saved alarm data for ID ${data.id}');
  } catch (e) {
    debugPrint('ALARM DATA: Failed to save: $e');
  }
}

Future<AlarmData?> _loadAlarmData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_alarmDataKey);
    if (jsonStr != null) {
      final data = AlarmData.fromJson(jsonDecode(jsonStr));
      debugPrint('ALARM DATA: Loaded alarm data for ID ${data.id}');
      return data;
    }
  } catch (e) {
    debugPrint('ALARM DATA: Failed to load: $e');
  }
  return null;
}

Future<void> _clearAlarmData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alarmDataKey);
    debugPrint('ALARM DATA: Cleared alarm data');
  } catch (e) {
    debugPrint('ALARM DATA: Failed to clear: $e');
  }
}

Future<void> markPendingAlarmRoute() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingAlarmRouteKey, true);
    debugPrint('ALARM ROUTE: Marked pending alarm route');
  } catch (e) {
    debugPrint('ALARM ROUTE: Failed to mark pending route: $e');
  }
}

Future<bool> consumePendingAlarmRoute() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final shouldOpenAlarm = prefs.getBool(_pendingAlarmRouteKey) ?? false;
    if (shouldOpenAlarm) {
      await prefs.remove(_pendingAlarmRouteKey);
      debugPrint('ALARM ROUTE: Consumed pending alarm route');
      return true;
    }
  } catch (e) {
    debugPrint('ALARM ROUTE: Failed to consume pending route: $e');
  }
  return false;
}

class AlarmManager {
  AlarmManager._();

  static final AlarmManager instance = AlarmManager._();

  Future<void> initialize() async {
    try {
      await AndroidAlarmManager.initialize();
      await AlarmService.initialize();
      await NotificationService.instance.init();
      debugPrint('AlarmManager: Initialized successfully');
    } catch (e) {
      debugPrint('AlarmManager: Failed to initialize: $e');
    }
  }

  Future<bool> scheduleAlarm({
    required ReminderRecord reminder,
    required String title,
    required String body,
  }) async {
    try {
      final alarmId = reminder.notificationId;
      final scheduledTime = tz.TZDateTime.from(reminder.scheduledTime, tz.local);

      final now = tz.TZDateTime.now(tz.local);
      if (scheduledTime.isBefore(now)) {
        debugPrint('AlarmManager: Scheduled time is in the past, skipping');
        return false;
      }

      final alarmData = AlarmData(id: alarmId, title: title, body: body);
      await _saveAlarmData(alarmData);

      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        alarmId,
        _alarmCallback,
        exact: true,
        wakeup: true,
        alarmClock: true,
      );

      debugPrint('AlarmManager: Alarm scheduled for $scheduledTime with ID $alarmId');
      return true;
    } catch (e) {
      debugPrint('AlarmManager: Failed to schedule alarm: $e');
      return false;
    }
  }

  Future<void> cancelAlarm(int alarmId) async {
    try {
      await AndroidAlarmManager.cancel(alarmId);
      await AlarmService.stopAlarm();
      await _clearAlarmData();
      debugPrint('AlarmManager: Alarm $alarmId cancelled');
    } catch (e) {
      debugPrint('AlarmManager: Failed to cancel alarm: $e');
    }
  }

  Future<bool> snoozeAlarm(ReminderRecord reminder, Duration snoozeDuration) async {
    try {
      final newScheduledTime = DateTime.now().add(snoozeDuration);
      final updatedReminder = reminder.copyWith(
        scheduledTime: newScheduledTime,
        status: 'snoozed',
      );

      return await scheduleAlarm(
        reminder: updatedReminder,
        title: 'Omi Reminder (Snoozed)',
        body: 'Snoozed reminder',
      );
    } catch (e) {
      debugPrint('AlarmManager: Failed to snooze alarm: $e');
      return false;
    }
  }
}

@pragma('vm:entry-point')
Future<void> _alarmCallback() async {
  debugPrint('ALARM CALLBACK: Alarm triggered!');

  try {
    debugPrint('ALARM CALLBACK: Initializing services...');
    await NotificationService.instance.init();
    
    debugPrint('ALARM CALLBACK: Starting alarm sound immediately...');
    const platform = MethodChannel('com.example.omi/alarm_service');
    try {
      await platform.invokeMethod<void>('startAlarm');
      debugPrint('ALARM CALLBACK: Alarm started successfully');
    } catch (e) {
      debugPrint('ALARM CALLBACK: Failed to start alarm: $e');
    }

    final alarmData = await _loadAlarmData();
    await markPendingAlarmRoute();
    if (alarmData != null) {
      debugPrint('ALARM CALLBACK: Showing alarm UI for ID ${alarmData.id}');
      await NotificationService.instance.showFullScreenAlarm(
        id: alarmData.id,
        title: alarmData.title,
        body: alarmData.body,
      );
      await _clearAlarmData();
    } else {
      debugPrint('ALARM CALLBACK: No alarm data found, showing default alarm UI');
      await NotificationService.instance.showFullScreenAlarm(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Omi Alarm',
        body: 'Alarm is ringing',
      );
    }
    debugPrint('ALARM CALLBACK: Completed successfully');
  } catch (e, st) {
    debugPrint('ALARM CALLBACK: Failed to handle alarm: $e');
    debugPrintStack(stackTrace: st);
  }
}
