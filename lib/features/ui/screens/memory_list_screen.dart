import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/glass_card.dart';
import '../../memory/providers/memory_provider.dart';

class MemoryListScreen extends ConsumerWidget {
  const MemoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Memory vault')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(memoryProvider.notifier).loadMemories(
            filter: state.activeFilter,
          );
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _buildFilters(context, ref, state),
            const SizedBox(height: 18),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.memories.isEmpty)
              const GlassCard(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_mosaic_outlined,
                        size: 48,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No memories yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Memories will appear here after you speak.',
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
            else
              ...state.memories.map(
                (memory) => _MemoryCard(
                  memory: memory,
                  onTap: () => context.go('/memory/${memory.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, MemoryState state) {
    final filters = MemoryController.memoryFilters;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = (state.activeFilter ?? 'all') == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_getFilterLabel(filter)),
              selected: selected,
              onSelected: (_) {
                ref.read(memoryProvider.notifier).loadMemories(filter: filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'note':
        return 'NOTES';
      case 'fact':
        return 'FACTS';
      case 'event':
        return 'EVENTS';
      default:
        return 'ALL';
    }
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.memory,
    required this.onTap,
  });

  final dynamic memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color typeColor;
    switch (memory.type) {
      case 'fact':
        typeColor = Colors.amber;
        break;
      case 'event':
        typeColor = Colors.purple;
        break;
      default:
        typeColor = const Color(0xFF70E1F5);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      memory.type.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (memory.language != null) ...[
                    const SizedBox(width: 8),
                    _LanguageBadge(language: memory.language),
                  ],
                  const Spacer(),
                  _ImportanceIndicator(importance: memory.importance),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                memory.content,
                style: theme.textTheme.titleMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (memory.datetimeRaw != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      'Reminder: ${memory.datetimeRaw}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy - h:mm a').format(memory.createdAt),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
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

class _ImportanceIndicator extends StatelessWidget {
  const _ImportanceIndicator({required this.importance});

  final int importance;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (importance >= 4) {
      color = Colors.red;
    } else if (importance >= 3) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < importance ? color : Colors.white.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}
