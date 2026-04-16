import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/omi_realtime_provider.dart';
import '../../../core/services/alarm_service.dart';
import '../../../core/services/notifications_services.dart';
import '../../../data/models/api/omi_models.dart';
import '../../../data/models/reminder_record.dart';
import '../../settings/providers/settings_provider.dart';

final reminderProvider = NotifierProvider<ReminderController, ReminderState>(
  ReminderController.new,
);

class ReminderState {
  final List<OmiActionItem> actionItems;
  final bool isLoading;
  final String? errorMessage;
  final bool showCompleted;

  const ReminderState({
    this.actionItems = const [],
    this.isLoading = false,
    this.errorMessage,
    this.showCompleted = false,
  });

  List<OmiActionItem> get reminders => actionItems;

  ReminderState copyWith({
    List<OmiActionItem>? actionItems,
    bool? isLoading,
    String? errorMessage,
    bool? showCompleted,
  }) {
    return ReminderState(
      actionItems: actionItems ?? this.actionItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      showCompleted: showCompleted ?? this.showCompleted,
    );
  }
}

class ReminderController extends Notifier<ReminderState> {
  @override
  ReminderState build() {
    Future.microtask(() => loadReminders());
    return const ReminderState();
  }

  Future<void> loadReminders({bool? showCompleted}) async {
    state = state.copyWith(isLoading: true, showCompleted: showCompleted ?? state.showCompleted);
    try {
      await ref.read(omiRealtimeProvider.notifier).refreshActionItems();
      final omiState = ref.read(omiRealtimeProvider);
      
      var items = List<OmiActionItem>.from(omiState.actionItems);
      
      if (showCompleted != true) {
        items = items.where((r) => !r.completed).toList();
      }
      
      items.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      
      final pendingCount = items.where((r) => !r.completed).length;
      final completedCount = items.where((r) => r.completed).length;
      
      debugPrint('ReminderProvider: Loaded action items: ${items.length}');
      debugPrint('ReminderProvider: Pending: $pendingCount, Completed: $completedCount');
      
      state = state.copyWith(
        actionItems: items,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('ReminderProvider: Error loading reminders: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Reminders could not be loaded right now.',
      );
    }
  }

  Future<void> createReminder(OmiActionItem item) async {
    debugPrint('ReminderProvider: Creating reminder: ${item.title}');
    try {
      await ref.read(omiRealtimeProvider.notifier).createActionItem(item);
      await loadReminders(showCompleted: state.showCompleted);
    } catch (e) {
      debugPrint('ReminderProvider: Error creating reminder: $e');
      state = state.copyWith(errorMessage: 'Failed to create reminder.');
    }
  }

  Future<void> snoozeReminder(String reminderId, Duration duration) async {
    final reminder = _findReminder(reminderId);
    if (reminder == null) return;

    debugPrint('ReminderProvider: Snoozing reminder $reminderId for ${duration.inMinutes} minutes');

    await AlarmService.stopAlarm();

    final newDueDate = DateTime.now().add(duration);
    await ref.read(omiRealtimeProvider.notifier).updateActionItem(
      reminderId,
      {'due_date': newDueDate.toIso8601String(), 'status': 'snoozed'},
    );
    await loadReminders(showCompleted: state.showCompleted);
  }

  Future<void> markReminderDone(String reminderId) async {
    final reminder = _findReminder(reminderId);
    if (reminder == null) return;

    debugPrint('ReminderProvider: Marking reminder done: ${reminder.title}');

    await AlarmService.stopAlarm();

    try {
      await ref.read(omiRealtimeProvider.notifier).completeActionItem(reminderId);
      await NotificationService.instance.cancelReminder(reminderId);
      await loadReminders(showCompleted: state.showCompleted);
    } catch (e) {
      debugPrint('ReminderProvider: Error completing reminder: $e');
      state = state.copyWith(errorMessage: 'Failed to complete reminder.');
    }
  }

  Future<void> markReminderPending(String reminderId) async {
    final reminder = _findReminder(reminderId);
    if (reminder == null) return;

    debugPrint('ReminderProvider: Marking reminder pending: ${reminder.title}');

    try {
      await ref.read(omiRealtimeProvider.notifier).updateActionItem(
        reminderId,
        {'completed': false},
      );
      await loadReminders(showCompleted: state.showCompleted);
    } catch (e) {
      debugPrint('ReminderProvider: Error marking reminder pending: $e');
      state = state.copyWith(errorMessage: 'Failed to update reminder.');
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminder = _findReminder(reminderId);
    if (reminder != null) {
      debugPrint('ReminderProvider: Deleting reminder: ${reminder.title}');
      await AlarmService.stopAlarm();
    }

    try {
      await ref.read(omiRealtimeProvider.notifier).deleteActionItem(reminderId);
      await NotificationService.instance.cancelReminder(reminderId);
      await loadReminders(showCompleted: state.showCompleted);
    } catch (e) {
      debugPrint('ReminderProvider: Error deleting reminder: $e');
      state = state.copyWith(errorMessage: 'Failed to delete reminder.');
    }
  }

  Future<void> refreshSchedulesForPreferences() async {
    final enabled = ref.read(settingsProvider).notificationsEnabled;
    final reminders = state.actionItems;
    for (final reminder in reminders) {
      if (reminder.completed) {
        await NotificationService.instance.cancelReminder(reminder.id);
        continue;
      }
      if (!enabled) {
        await NotificationService.instance.cancelReminder(reminder.id);
        continue;
      }
      if (reminder.dueDate != null) {
        final record = ReminderRecord(
          id: reminder.id,
          memoryId: reminder.conversationId ?? reminder.id,
          scheduledTime: reminder.dueDate!,
          status: reminder.completed ? 'done' : 'pending',
        );
        await NotificationService.instance.scheduleReminder(
          record,
          reminder.title,
        );
      }
    }
  }

  OmiActionItem? _findReminder(String reminderId) {
    for (final reminder in state.actionItems) {
      if (reminder.id == reminderId) {
        return reminder;
      }
    }
    return null;
  }
}