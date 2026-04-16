import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/glass_card.dart';
import '../../memory/providers/memory_provider.dart';

class MemoryListScreen extends ConsumerWidget {
  const MemoryListScreen({super.key});

  static const _filters = ['all', 'reminder', 'task', 'event', 'fact', 'note'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Memory vault')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _filters.map((filter) {
              final selected = (state.activeFilter ?? 'all') == filter;
              return ChoiceChip(
                label: Text(filter.toUpperCase()),
                selected: selected,
                onSelected: (_) {
                  ref
                      .read(memoryProvider.notifier)
                      .loadMemories(filter: filter);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.memories.isEmpty)
            const GlassCard(child: Text('No memories match this filter yet.'))
          else
            ...state.memories.map(
              (memory) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () => context.go('/memory/${memory.id}'),
                  borderRadius: BorderRadius.circular(20),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              memory.type.toUpperCase(),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: const Color(0xFF70E1F5)),
                            ),
                            const Spacer(),
                            Text(
                              'P${memory.importance}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          memory.content,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          DateFormat(
                            'MMM d, yyyy - h:mm a',
                          ).format(memory.createdAt),
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
