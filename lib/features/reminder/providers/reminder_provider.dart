import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/alarm_service.dart';
import '../../../core/services/notifications_services.dart';
import '../../../core/utils/date_time_parser.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/memory_record.dart';
import '../../../data/models/reminder_record.dart';
import '../../memory/providers/memory_provider.dart';
import '../../settings/providers/settings_provider.dart';

final reminderProvider = NotifierProvider<ReminderController, ReminderState>(
  ReminderController.new,
);

class ReminderState {
  const ReminderState({
    required this.reminders,
    required this.isLoading,
    this.errorMessage,
  });

  factory ReminderState.initial() =>
      const ReminderState(reminders: [], isLoading: false);

  final List<ReminderRecord> reminders;
  final bool isLoading;
  final String? errorMessage;

  ReminderState copyWith({
    List<ReminderRecord>? reminders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ReminderController extends Notifier<ReminderState> {
  final _uuid = const Uuid();

  @override
  ReminderState build() {
    StreamSubscription<NotificationResponse>? subscription;

    Future.microtask(() async {
      await loadReminders();
      subscription = NotificationService.instance.responses.listen(
        _handleNotificationResponse,
      );
    });

    ref.onDispose(() {
      subscription?.cancel();
    });

    return ReminderState.initial();
  }

  Future<void> loadReminders() async {
    state = state.copyWith(isLoading: true);
    try {
      final reminders = await ref.read(appDatabaseProvider).getAllReminders();
      final activeReminders = reminders
          .where((r) => r.status != 'done')
          .toList();
      activeReminders.sort(
        (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
      );
      state = state.copyWith(
        reminders: activeReminders,
        isLoading: false,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Reminders could not be loaded right now.',
      );
    }
  }

  Future<void> syncForLatestMemories() async {
    final memories = ref.read(memoryProvider).memories.take(6);
    for (final memory in memories) {
      await createOrUpdateReminderForMemory(memory);
    }
    await loadReminders();
  }

  Future<void> createOrUpdateReminderForMemory(MemoryRecord memory) async {
    try {
      final parsed = DateTimeParser.parse(memory.datetimeRaw);
      if (parsed.scheduledAt == null) {
        return;
      }

      final database = ref.read(appDatabaseProvider);
      final existing = await database.getReminderByMemoryId(memory.id);
      if (existing != null &&
          existing.scheduledTime == parsed.scheduledAt &&
          existing.status == (parsed.wasAdjusted ? 'adjusted' : 'pending')) {
        return;
      }
      final reminder =
          (existing ??
                  ReminderRecord(
                    id: _uuid.v4(),
                    memoryId: memory.id,
                    scheduledTime: parsed.scheduledAt!,
                    status: parsed.wasAdjusted ? 'adjusted' : 'pending',
                  ))
              .copyWith(
                scheduledTime: parsed.scheduledAt,
                status: parsed.wasAdjusted ? 'adjusted' : 'pending',
              );

      if (existing == null) {
        await database.insertReminder(reminder);
      } else {
        await database.updateReminder(reminder);
      }

      if (ref.read(settingsProvider).notificationsEnabled) {
        await NotificationService.instance.scheduleReminder(
          reminder,
          memory.content,
        );
      } else {
        await NotificationService.instance.cancelReminder(reminder.id);
      }
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Reminder scheduling failed safely.',
      );
    }
  }

  Future<void> snoozeReminder(String reminderId, Duration duration) async {
    final reminder = _findReminder(reminderId);
    if (reminder == null) {
      return;
    }

    await AlarmService.stopAlarm();

    final updated = reminder.copyWith(
      scheduledTime: DateTime.now().add(duration),
      status: 'snoozed',
    );

    await ref.read(appDatabaseProvider).updateReminder(updated);
    final memory = await ref
        .read(appDatabaseProvider)
        .getMemoryById(updated.memoryId);
    if (memory != null && ref.read(settingsProvider).notificationsEnabled) {
      await NotificationService.instance.scheduleReminder(
        updated,
        memory.content,
      );
    }
    await loadReminders();
  }

  Future<void> markReminderDone(String reminderId) async {
    final reminder = _findReminder(reminderId);
    if (reminder == null) {
      return;
    }

    await AlarmService.stopAlarm();

    await ref
        .read(appDatabaseProvider)
        .updateReminder(reminder.copyWith(status: 'done'));
    await NotificationService.instance.cancelReminder(reminder.id);
    await loadReminders();
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminder = _findReminder(reminderId);
    if (reminder != null) {
      await AlarmService.stopAlarm();
    }
    await NotificationService.instance.cancelReminder(reminderId);
    await loadReminders();
  }

  Future<void> deleteReminderForMemory(String memoryId) async {
    final existing = await ref
        .read(appDatabaseProvider)
        .getReminderByMemoryId(memoryId);
    if (existing != null) {
      await NotificationService.instance.cancelReminder(existing.id);
    }
    await ref.read(appDatabaseProvider).deleteReminderByMemoryId(memoryId);
    await loadReminders();
  }

  Future<void> refreshSchedulesForPreferences() async {
    final enabled = ref.read(settingsProvider).notificationsEnabled;
    final reminders = await ref.read(appDatabaseProvider).getAllReminders();
    for (final reminder in reminders) {
      if (reminder.status == 'done') {
        await NotificationService.instance.cancelReminder(reminder.id);
        continue;
      }

      if (!enabled) {
        await NotificationService.instance.cancelReminder(reminder.id);
        continue;
      }

      final memory = await ref
          .read(appDatabaseProvider)
          .getMemoryById(reminder.memoryId);
      if (memory != null) {
        await NotificationService.instance.scheduleReminder(
          reminder,
          memory.content,
        );
      }
    }
  }

  ReminderRecord? _findReminder(String reminderId) {
    for (final reminder in state.reminders) {
      if (reminder.id == reminderId) {
        return reminder;
      }
    }
    return null;
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    debugPrint('Notification tapped -> stopping alarm');
    await AlarmService.stopAlarm();

    if (response.payload == null || response.payload!.isEmpty) {
      return;
    }

    try {
      final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
      final reminderId = payload['reminderId']?.toString();
      if (reminderId == null) {
        return;
      }

      if (response.actionId == 'snooze_10') {
        await snoozeReminder(reminderId, const Duration(minutes: 10));
      }
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'A reminder action could not be completed.',
      );
    }
  }
}
