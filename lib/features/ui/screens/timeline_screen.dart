import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/omi_realtime_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/api/omi_models.dart';

final selectedTimelineDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class TimelineItem {
  final DateTime timestamp;
  final TimelineItemType type;
  final String title;
  final String? subtitle;
  final String? id;
  final String? language;
  final int? importance;
  final bool? completed;

  TimelineItem({
    required this.timestamp,
    required this.type,
    required this.title,
    this.subtitle,
    this.id,
    this.language,
    this.importance,
    this.completed,
  });
}

enum TimelineItemType {
  conversation,
  memory,
  reminder,
  summary,
}

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(omiRealtimeProvider);

    final items = _buildTimelineItems(state, _selectedDate);
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final groupedItems = _groupItemsByHour(items);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050913), Color(0xFF0D1527), Color(0xFF101E37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildDateNav(),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState()
                  : _buildTimeline(groupedItems),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'Timeline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF70E1F5).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF70E1F5).withValues(alpha: 0.3)),
            ),
            child: Text(
              _isToday(_selectedDate)
                  ? 'Today'
                  : _isYesterday(_selectedDate)
                      ? 'Yesterday'
                      : DateFormat('MMMM d, yyyy').format(_selectedDate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
            onPressed: _isToday(_selectedDate)
                ? null
                : () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                  },
          ),
        ],
      ),
    );
  }

  List<TimelineItem> _buildTimelineItems(OmiRealtimeState state, DateTime date) {
    final items = <TimelineItem>[];

    for (final conv in state.conversations) {
      if (_isSameDay(conv.createdAt, date)) {
        items.add(TimelineItem(
          timestamp: conv.createdAt,
          type: TimelineItemType.conversation,
          title: conv.title ?? 'Conversation',
          subtitle: conv.transcript,
          id: conv.id,
          language: conv.language,
        ));
      }
    }

    for (final memory in state.memories) {
      if (_isSameDay(memory.createdAt, date)) {
        items.add(TimelineItem(
          timestamp: memory.createdAt,
          type: TimelineItemType.memory,
          title: memory.content.length > 80
              ? '${memory.content.substring(0, 80)}...'
              : memory.content,
          subtitle: memory.type,
          id: memory.id,
          importance: memory.importance,
        ));
      }
    }

    for (final action in state.actionItems) {
      if (action.dueDate != null && _isSameDay(action.dueDate!, date)) {
        items.add(TimelineItem(
          timestamp: action.dueDate!,
          type: TimelineItemType.reminder,
          title: action.title,
          subtitle: action.completed ? 'Completed' : 'Pending',
          id: action.id,
          completed: action.completed,
        ));
      }
    }

    if (state.dailySummary != null && _isSameDay(state.dailySummary!.date, date)) {
      items.add(TimelineItem(
        timestamp: state.dailySummary!.date,
        type: TimelineItemType.summary,
        title: 'Daily Summary',
        subtitle: state.dailySummary!.summary,
      ));
    }

    return items;
  }

  Map<String, List<TimelineItem>> _groupItemsByHour(List<TimelineItem> items) {
    final grouped = <String, List<TimelineItem>>{};

    for (final item in items) {
      final hour = DateFormat('h:mm a').format(item.timestamp);
      grouped.putIfAbsent(hour, () => []).add(item);
    }

    return grouped;
  }

  Widget _buildTimeline(Map<String, List<TimelineItem>> groupedItems) {
    final hours = groupedItems.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final hour = hours[index];
        final items = groupedItems[hour]!;

        return _buildHourSection(hour, items);
      },
    );
  }

  Widget _buildHourSection(String hour, List<TimelineItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hour,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildTimelineItem(item)),
      ],
    );
  }

  Widget _buildTimelineItem(TimelineItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onItemTap(item),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineDot(item.type),
            Expanded(
              child: GlassCard(
                margin: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTypeIcon(item.type),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.completed == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DONE',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.subtitle!.length > 120
                            ? '${item.subtitle!.substring(0, 120)}...'
                            : item.subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.language != null) ...[
                          _buildLanguageChip(item.language!),
                          const SizedBox(width: 8),
                        ],
                        if (item.importance != null)
                          _buildImportanceIndicator(item.importance!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineDot(TimelineItemType type) {
    Color color;
    switch (type) {
      case TimelineItemType.conversation:
        color = Colors.blue;
        break;
      case TimelineItemType.memory:
        color = Colors.purple;
        break;
      case TimelineItemType.reminder:
        color = Colors.orange;
        break;
      case TimelineItemType.summary:
        color = const Color(0xFF70E1F5);
        break;
    }

    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(TimelineItemType type) {
    IconData icon;
    Color color;

    switch (type) {
      case TimelineItemType.conversation:
        icon = Icons.chat_bubble_outline;
        color = Colors.blue;
        break;
      case TimelineItemType.memory:
        icon = Icons.auto_awesome_mosaic;
        color = Colors.purple;
        break;
      case TimelineItemType.reminder:
        icon = Icons.notifications_outlined;
        color = Colors.orange;
        break;
      case TimelineItemType.summary:
        icon = Icons.summarize_outlined;
        color = const Color(0xFF70E1F5);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildLanguageChip(String language) {
    Color color;
    switch (language) {
      case 'hi':
        color = Colors.orange;
        break;
      case 'gu':
        color = Colors.green;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        language.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImportanceIndicator(int importance) {
    final color = _getImportanceColor(importance);

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

  Color _getImportanceColor(int importance) {
    if (importance >= 4) return Colors.red;
    if (importance >= 3) return Colors.orange;
    return Colors.green;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            _isToday(_selectedDate)
                ? 'No activity today yet'
                : 'No activity on this day',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your timeline will show conversations,\nmemories, and reminders throughout the day',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTap(TimelineItem item) {
    switch (item.type) {
      case TimelineItemType.memory:
        if (item.id != null) {
          context.go('/memory/${item.id}');
        }
        break;
      case TimelineItemType.conversation:
        debugPrint('Open conversation: ${item.id}');
        break;
      case TimelineItemType.reminder:
        debugPrint('Open reminder: ${item.id}');
        break;
      case TimelineItemType.summary:
        context.go('/daily-summary');
        break;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _isSameDay(date, yesterday);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
