import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/alarm_manager.dart';
import 'core/services/alarm_service.dart';
import 'core/services/notifications_services.dart';
import 'features/settings/providers/settings_provider.dart';

const MethodChannel _alarmPlatform = MethodChannel(
  'com.example.omi/alarm_service',
);

Future<void> _stopNativeAlarm() async {
  try {
    await _alarmPlatform.invokeMethod<void>('stopAlarm');
  } catch (e) {
    debugPrint('Failed to stop native alarm playback: $e');
  }
}

void _openAlarmRoute() {
  final context = appNavigatorKey.currentContext;
  if (context != null) {
    GoRouter.of(context).go('/alarm');
  }
}

Future<void> _handleNotificationTap(NotificationResponse response) async {
  debugPrint('Notification response received: action=${response.actionId}, payload=${response.payload}');
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  if (response.actionId == 'stop') {
    debugPrint('STOP action received - stopping alarm');
    await _stopNativeAlarm();
    final notificationId = response.id;
    if (notificationId != null) {
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    }
    return;
  }
  
  if (response.actionId == 'snooze_5' || response.actionId == 'snooze_10') {
    debugPrint('SNOOZE action received - stopping alarm');
    await _stopNativeAlarm();
    await AlarmService.snooze(const Duration(minutes: 5));
    NotificationService.instance.cancelAllReminders();
    return;
  }
  
  if (response.actionId == 'dismiss') {
    debugPrint('DISMISS action received - stopping alarm');
    await _stopNativeAlarm();
    NotificationService.instance.cancelAllReminders();
    return;
  }

  debugPrint('Notification tapped -> opening /alarm');
  _openAlarmRoute();

  final pendingPayload = PendingNotification.instance.payload;
  debugPrint('Pending notification payload: $pendingPayload');
}

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await dotenv.load(fileName: '.env');

      final preferences = await SharedPreferences.getInstance();
      
      await AlarmManager.instance.initialize();
      await NotificationService.instance.init();
      await NotificationService.instance.requestPermissions();
      
      NotificationService.instance.responses.listen(_handleNotificationTap);

      runApp(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const OmiApp(),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('Unhandled app error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}
