import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/alarm_manager.dart';
import '../../../core/services/notifications_services.dart';
import '../../../core/utils/date_time_parser.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/memory_record.dart';
import '../../../data/models/reminder_record.dart';
import '../../settings/providers/settings_provider.dart';

final reminderManagerProvider = Provider<ReminderManager>((ref) {
  return ReminderManager(ref);
});

class ReminderManager {
  final Ref _ref;
  final _uuid = const Uuid();

  ReminderManager(this._ref);

  Future<void> initialize() async {
    await NotificationService.instance.init();
    await AlarmManager.instance.initialize();
    await rescheduleAllReminders();
  }

  Future<void> requestPermissions() async {
    await NotificationService.instance.requestPermissions();
  }

  Future<bool> processMemoryForReminder(MemoryRecord memory) async {
    debugPrint("🔔 REMINDER MANAGER: Processing reminder for memory type: ${memory.type}");
    
    if (!memory.type.contains('reminder')) {
      debugPrint("🔔 REMINDER MANAGER: Skipping - not a reminder type");
      return false;
    }

    DateTime? scheduledAt;
    bool wasAdjusted = false;

    if (memory.datetimeRaw != null && memory.datetimeRaw!.trim().isNotEmpty) {
      debugPrint("🔔 REMINDER MANAGER: Parsing datetimeRaw: ${memory.datetimeRaw}");
      final parsed = ScheduleParser.parse(memory.datetimeRaw);
      debugPrint("🔔 REMINDER MANAGER: Parsed result: scheduledAt=${parsed.scheduledAt}, wasAdjusted=${parsed.wasAdjusted}");
      scheduledAt = parsed.scheduledAt;
      wasAdjusted = parsed.wasAdjusted;
    } else {
      debugPrint("⚠️ REMINDER MANAGER: No datetimeRaw from AI, extracting manually from content...");
      debugPrint("🔔 REMINDER MANAGER: Content: ${memory.content}");
      scheduledAt = DateTimeParser.parseFromText(memory.content);
      if (scheduledAt != null) {
        debugPrint("✅ REMINDER MANAGER: Extracted datetime: $scheduledAt");
      } else {
        debugPrint("❌ REMINDER MANAGER: Failed to extract datetime from content");
      }
    }
    
    if (scheduledAt == null) {
      debugPrint("🔔 REMINDER MANAGER: Skipping - no valid scheduled time");
      return false;
    }

    try {
      final database = _ref.read(appDatabaseProvider);
      final existing = await database.getReminderByMemoryId(memory.id);
      
      if (existing != null) {
        debugPrint("🔔 REMINDER MANAGER: Reminder already exists for memoryId ${memory.id}, skipping duplicate");
        return false;
      }

      final reminder = ReminderRecord(
        id: _uuid.v4(),
        memoryId: memory.id,
        scheduledTime: scheduledAt!,
        status: wasAdjusted ? 'adjusted' : 'pending',
      );

      debugPrint("🔔 REMINDER MANAGER: Inserting new reminder into DB");
      await database.insertReminder(reminder);

      final settings = _ref.read(settingsProvider);
      debugPrint("🔔 REMINDER MANAGER: notificationsEnabled = ${settings.notificationsEnabled}");
      
      if (settings.notificationsEnabled) {
        debugPrint("🔔 REMINDER MANAGER: Scheduling alarm (REAL ALARM)");
        final alarmScheduled = await AlarmManager.instance.scheduleAlarm(
          reminder: reminder,
          title: 'Omi Alarm',
          body: memory.content,
        );
        
        if (alarmScheduled) {
          debugPrint("🔔 REMINDER MANAGER: Alarm scheduled successfully!");
        } else {
          debugPrint("🔔 REMINDER MANAGER: Alarm scheduling failed, falling back to notification");
          await NotificationService.instance.scheduleReminder(
            reminder,
            memory.content,
          );
        }
      } else {
        debugPrint("🔔 REMINDER MANAGER: Notifications disabled, skipping schedule");
      }

      _ref.invalidate(reminderListProvider);
      return true;
    } catch (e) {
      debugPrint("🔔 REMINDER MANAGER: Error: $e");
      return false;
    }
  }

  Future<void> rescheduleAllReminders() async {
    final settings = _ref.read(settingsProvider);
    if (!settings.notificationsEnabled) {
      return;
    }

    try {
      final database = _ref.read(appDatabaseProvider);
      final reminders = await database.getAllReminders();

      for (final reminder in reminders) {
        if (reminder.status == 'done') {
          continue;
        }

        if (reminder.scheduledTime.isBefore(DateTime.now())) {
          await database.updateReminder(reminder.copyWith(status: 'expired'));
          continue;
        }

        final memory = await database.getMemoryById(reminder.memoryId);
        if (memory != null) {
          await AlarmManager.instance.scheduleAlarm(
            reminder: reminder,
            title: 'Omi Alarm',
            body: memory.content,
          );
        }
      }
    } catch (e) {
      debugPrint("🔔 REMINDER MANAGER: Reschedule error: $e");
    }
  }

  Future<void> cancelReminderForMemory(String memoryId) async {
    final database = _ref.read(appDatabaseProvider);
    final existing = await database.getReminderByMemoryId(memoryId);

    if (existing != null) {
      await AlarmManager.instance.cancelAlarm(existing.notificationId);
      await NotificationService.instance.cancelReminder(existing.id);
      await database.deleteReminderByMemoryId(memoryId);
      _ref.invalidate(reminderListProvider);
    }
  }
}

final reminderListProvider = FutureProvider<List<ReminderRecord>>((ref) async {
  final database = ref.read(appDatabaseProvider);
  final reminders = await database.getAllReminders();

  final activeReminders = reminders
      .where((r) => r.status != 'done' && r.status != 'expired')
      .toList();

  activeReminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  return activeReminders;
});

final reminderByMemoryProvider = FutureProvider.family<ReminderRecord?, String>((ref, memoryId) async {
  final database = ref.read(appDatabaseProvider);
  return database.getReminderByMemoryId(memoryId);
});