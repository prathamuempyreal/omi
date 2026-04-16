import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/glass_card.dart';
import '../../memory/providers/memory_provider.dart';
import '../../reminder/providers/reminder_provider.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderProvider);
    final memories = ref.watch(memoryProvider).memories;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.reminders.isEmpty)
            const GlassCard(
              child: Text(
                'No reminders scheduled yet. Speak a date or time to create one automatically.',
              ),
            )
          else
            ...state.reminders.map((reminder) {
              final matches = memories.where(
                (item) => item.id == reminder.memoryId,
              );
              final memory = matches.isEmpty ? null : matches.first;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            reminder.status.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: const Color(0xFFFFB77C)),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat(
                              'MMM d - h:mm a',
                            ).format(reminder.scheduledTime),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        memory?.content ?? 'Linked memory unavailable',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(reminderProvider.notifier)
                                    .snoozeReminder(
                                      reminder.id,
                                      const Duration(minutes: 10),
                                    );
                              },
                              child: const Text('Snooze 10m'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                ref
                                    .read(reminderProvider.notifier)
                                    .markReminderDone(reminder.id);
                              },
                              child: const Text('Mark done'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
