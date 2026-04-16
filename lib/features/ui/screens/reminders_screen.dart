import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../data/models/api/omi_models.dart';
import '../../reminder/providers/reminder_provider.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          if (state.actionItems.any((r) => r.completed))
            TextButton.icon(
              onPressed: () {
                ref.read(reminderProvider.notifier).loadReminders(
                  showCompleted: !(state.showCompleted),
                );
              },
              icon: Icon(
                state.showCompleted
                    ? Icons.visibility_off
                    : Icons.visibility,
                size: 18,
              ),
              label: Text(
                state.showCompleted ? 'Hide done' : 'Show done',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(reminderProvider.notifier).loadReminders(
            showCompleted: state.showCompleted,
          );
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.reminders.isEmpty)
              const GlassCard(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 48,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No reminders yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Reminders will appear here after you speak.\nTry saying "remind me to..." or "set a reminder for..."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildSummary(state),
              const SizedBox(height: 16),
              ...state.reminders.map((reminder) => _ReminderCard(
                reminder: reminder,
                onSnooze: () {
                  ref.read(reminderProvider.notifier).snoozeReminder(
                    reminder.id,
                    const Duration(minutes: 10),
                  );
                },
                onComplete: () {
                  if (reminder.completed) {
                    ref.read(reminderProvider.notifier).markReminderPending(
                      reminder.id,
                    );
                  } else {
                    ref.read(reminderProvider.notifier).markReminderDone(
                      reminder.id,
                    );
                  }
                },
                onDelete: () {
                  ref.read(reminderProvider.notifier).deleteReminder(
                    reminder.id,
                  );
                },
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ReminderState state) {
    final pending = state.reminders.where((r) => !r.completed).length;
    final completed = state.reminders.where((r) => r.completed).length;
    final urgent = state.reminders.where((r) {
      if (r.completed || r.dueDate == null) return false;
      return r.dueDate!.difference(DateTime.now()).inMinutes <= 60;
    }).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            label: 'Pending',
            value: pending.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryChip(
            label: 'Completed',
            value: completed.toString(),
            color: Colors.green,
          ),
        ),
        if (urgent > 0) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryChip(
              label: 'Urgent',
              value: urgent.toString(),
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onSnooze,
    required this.onComplete,
    required this.onDelete,
  });

  final OmiActionItem reminder;
  final VoidCallback onSnooze;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isUrgent = reminder.dueDate != null &&
        !reminder.completed &&
        reminder.dueDate!.difference(now).inMinutes <= 60;
    final isOverdue = reminder.dueDate != null &&
        !reminder.completed &&
        reminder.dueDate!.isBefore(now);

    String timeDisplay;
    if (reminder.dueDate != null) {
      if (isOverdue) {
        final overdueMinutes = now.difference(reminder.dueDate!).inMinutes;
        if (overdueMinutes < 60) {
          timeDisplay = 'Overdue by $overdueMinutes min';
        } else {
          final overdueHours = overdueMinutes ~/ 60;
          timeDisplay = 'Overdue by $overdueHours hours';
        }
      } else {
        final diff = reminder.dueDate!.difference(now);
        if (diff.inMinutes < 60) {
          timeDisplay = 'Due in ${diff.inMinutes} min';
        } else if (diff.inHours < 24) {
          timeDisplay = 'Due in ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
        } else {
          timeDisplay = DateFormat('MMM d - h:mm a').format(reminder.dueDate!);
        }
      }
    } else {
      timeDisplay = 'No due date';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUrgent
                ? Colors.red.withValues(alpha: 0.5)
                : (reminder.completed
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        child: GlassCard(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reminder.completed
                          ? Colors.green
                          : Colors.transparent,
                      border: Border.all(
                        color: reminder.completed
                            ? Colors.green
                            : (isUrgent ? Colors.red : Colors.white.withValues(alpha: 0.3)),
                        width: 2,
                      ),
                    ),
                    child: reminder.completed
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: reminder.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: reminder.completed
                              ? Colors.white54
                              : Colors.white,
                        ),
                      ),
                      if (reminder.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.description!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (reminder.language != null) ...[
                  const SizedBox(width: 8),
                  _LanguageBadge(language: reminder.language!),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red.withValues(alpha: 0.15)
                    : (isUrgent
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.schedule,
                    size: 16,
                    color: isOverdue
                        ? Colors.red
                        : (isUrgent ? Colors.orange : Colors.white54),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeDisplay,
                    style: TextStyle(
                      color: isOverdue
                          ? Colors.red
                          : (isUrgent ? Colors.orange : Colors.white70),
                      fontSize: 13,
                      fontWeight: isUrgent || isOverdue
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!reminder.completed) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSnooze,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text('Snooze 10m'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: onComplete,
                    style: FilledButton.styleFrom(
                      backgroundColor: reminder.completed
                          ? Colors.orange
                          : Colors.green,
                    ),
                    child: Text(
                      reminder.completed ? 'Undo' : 'Mark done',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (language) {
      case 'hi':
        color = Colors.orange;
        label = 'HI';
        break;
      case 'gu':
        color = Colors.green;
        label = 'GU';
        break;
      default:
        color = Colors.blue;
        label = 'EN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}