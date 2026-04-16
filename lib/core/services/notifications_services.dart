import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/reminder_record.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  try {
    debugPrint('NOTIFICATION BACKGROUND TAP: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      PendingNotification.instance.payload = response.payload;
    }
  } catch (e, st) {
    debugPrint('Notification background callback error: $e');
    debugPrintStack(stackTrace: st);
  }
}

class PendingNotification {
  PendingNotification._();
  static final PendingNotification instance = PendingNotification._();
  String? payload;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String reminderChannelId = 'omi_reminders';
  static const String reminderChannelName = 'Omi Reminders';
  static const String alarmChannelId = 'omi_alarms';
  static const String alarmChannelName = 'Omi Alarms';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationResponse> _responses =
      StreamController<NotificationResponse>.broadcast();
  bool _initialized = false;
  bool _timezoneInitialized = false;

  Stream<NotificationResponse> get responses => _responses.stream;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    await _initializeTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _responses.add,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createNotificationChannels();
    _initialized = true;
  }

  Future<void> _initializeTimezone() async {
    if (_timezoneInitialized) return;
    
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
      _timezoneInitialized = true;
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
      _timezoneInitialized = true;
    }
  }

  Future<void> _createNotificationChannels() async {
    const androidChannel = AndroidNotificationChannel(
      reminderChannelId,
      reminderChannelName,
      description: 'Reminder notifications for saved memories',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const alarmChannel = AndroidNotificationChannel(
      alarmChannelId,
      alarmChannelName,
      description: 'High-priority alarm notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.createNotificationChannel(alarmChannel);
  }

  void handleBackgroundResponse(NotificationResponse response) {
    debugPrint('Notification tapped: action=${response.actionId}, payload=${response.payload}');
    if (!_responses.isClosed) {
      _responses.add(response);
    }
  }

  Future<void> showNotification({required String title, required String body}) async {
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        _details(),
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  Future<void> showFullScreenAlarm({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    
    try {
      await _plugin.show(
        id,
        title,
        body,
        _alarmDetails(
          fullScreen: true,
          actions: const [
            AndroidNotificationAction(
              'snooze_5',
              'Snooze 5m',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'stop',
              'Stop',
              showsUserInterface: true,
            ),
          ],
        ),
      );
      debugPrint('Full-screen alarm shown with id: $id');
    } catch (e) {
      debugPrint('Failed to show full-screen alarm: $e');
    }
  }

  Future<bool> scheduleReminder(ReminderRecord reminder, String content) async {
    await _ensureInitialized();
    
    try {
      DateTime scheduledBase;
      
      final now = DateTime.now();
      if (reminder.scheduledTime.isBefore(now.add(const Duration(seconds: 30)))) {
        scheduledBase = now.add(const Duration(minutes: 1));
      } else {
        scheduledBase = reminder.scheduledTime;
      }

      final scheduledAt = tz.TZDateTime.from(scheduledBase, tz.local);
      
      final payload = jsonEncode({
        'reminderId': reminder.id,
        'memoryId': reminder.memoryId,
      });

      await _plugin.cancel(reminder.notificationId);

      await _plugin.zonedSchedule(
        reminder.notificationId,
        'Omi Reminder',
        content,
        scheduledAt,
        _alarmDetails(
          actions: const [
            AndroidNotificationAction(
              'snooze_10',
              'Snooze 10m',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              showsUserInterface: true,
            ),
          ],
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      return true;
    } catch (e) {
      debugPrint('Failed to schedule reminder: $e');
      return false;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_timezoneInitialized) {
      await _initializeTimezone();
    }
  }

  Future<bool> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _ensureInitialized();
    
    try {
      final scheduledAt = tz.TZDateTime.from(scheduledTime, tz.local);
      
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledAt,
        _alarmDetails(
          fullScreen: true,
          actions: const [
            AndroidNotificationAction(
              'snooze_10',
              'Snooze',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              showsUserInterface: true,
            ),
          ],
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to schedule alarm: $e');
      return false;
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    try {
      await _plugin.cancel(reminderId.hashCode);
    } catch (e) {
      debugPrint('Failed to cancel reminder: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all reminders: $e');
    }
  }

  Future<void> requestPermissions() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
      
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      final macOSPlugin = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      await macOSPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Failed to request permissions: $e');
    }
  }

  NotificationDetails _details({
    List<AndroidNotificationAction> actions = const [],
    bool fullScreen = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        reminderChannelId,
        reminderChannelName,
        channelDescription: 'Scheduled reminders from Omi',
        importance: Importance.max,
        priority: Priority.high,
        actions: actions,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: fullScreen,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  NotificationDetails _alarmDetails({
    List<AndroidNotificationAction> actions = const [],
    bool fullScreen = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        alarmChannelId,
        alarmChannelName,
        channelDescription: 'High-priority alarm notifications from Omi',
        importance: Importance.max,
        priority: Priority.max,
        actions: actions,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        enableLights: true,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: fullScreen,
        ticker: 'Omi Reminder',
        visibility: NotificationVisibility.public,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
