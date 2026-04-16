import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/omi_realtime_provider.dart';
import '../../../core/services/omi/omi_endpoints.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/api/omi_models.dart';

final selectedSummaryDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailySummaryProvider = FutureProvider.family<OmiDailySummary?, DateTime>((ref, date) async {
  final response = await OmiApi.getDailySummary(date);
  return response.data;
});

class DailySummaryScreen extends ConsumerStatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  ConsumerState<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends ConsumerState<DailySummaryScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final state = ref.watch(omiRealtimeProvider);

    final dayMemories = state.memories.where((m) {
      return _isSameDay(m.createdAt, _selectedDate);
    }).toList();

    final dayActionItems = state.actionItems.where((a) {
      return a.dueDate != null && _isSameDay(a.dueDate!, _selectedDate);
    }).toList();

    final completedCount = dayActionItems.where((a) => a.completed).length;
    final pendingCount = dayActionItems.where((a) => !a.completed).length;

    final dayConversations = state.conversations.where((c) {
      return _isSameDay(c.createdAt, _selectedDate);
    }).toList();

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
            _buildDateSelector(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSummaryOverview(
                    screenWidth,
                    dayConversations.length,
                    dayMemories.length,
                    completedCount,
                    pendingCount,
                  ),
                  const SizedBox(height: 24),
                  if (dayConversations.isNotEmpty) ...[
                    _buildSectionHeader('Major Discussions', Icons.chat_bubble_outline, dayConversations.length),
                    ...dayConversations.map((c) => _buildConversationCard(c)),
                    const SizedBox(height: 16),
                  ],
                  if (dayMemories.isNotEmpty) ...[
                    _buildSectionHeader('Important Memories', Icons.auto_awesome_mosaic, dayMemories.length),
                    ...dayMemories.map((m) => _buildMemoryCard(m)),
                    const SizedBox(height: 16),
                  ],
                  if (dayActionItems.isNotEmpty) ...[
                    _buildSectionHeader('Reminders', Icons.notifications_outlined, dayActionItems.length),
                    _buildRemindersSummary(pendingCount, completedCount),
                    ...dayActionItems.map((a) => _buildActionItemCard(a)),
                    const SizedBox(height: 16),
                  ],
                  if (dayConversations.isEmpty && dayMemories.isEmpty && dayActionItems.isEmpty)
                    _buildEmptyDay(),
                  const SizedBox(height: 100),
                ],
              ),
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
              'Daily Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              _shareSummary();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: index));
          final isSelected = _isSameDay(date, _selectedDate);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF70E1F5).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF70E1F5)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date),
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF70E1F5) : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d').format(date),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM').format(date),
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF70E1F5) : Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryOverview(
    double width,
    int conversations,
    int memories,
    int completed,
    int pending,
  ) {
    return GlassCard(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize, color: Color(0xFF70E1F5)),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                icon: Icons.chat_bubble_outline,
                value: conversations.toString(),
                label: 'Discussions',
                color: Colors.blue,
              ),
              _buildMetricItem(
                icon: Icons.auto_awesome_mosaic,
                value: memories.toString(),
                label: 'Memories',
                color: Colors.purple,
              ),
              _buildMetricItem(
                icon: Icons.check_circle_outline,
                value: completed.toString(),
                label: 'Completed',
                color: Colors.green,
              ),
              _buildMetricItem(
                icon: Icons.pending_outlined,
                value: pending.toString(),
                label: 'Pending',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF70E1F5), size: 20),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(
              color: Color(0xFF70E1F5),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(OmiConversation conversation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (conversation.language != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLanguageColor(conversation.language!).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      conversation.language?.toUpperCase() ?? 'EN',
                      style: TextStyle(
                        color: _getLanguageColor(conversation.language!),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  DateFormat('h:mm a').format(conversation.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              conversation.title ?? 'Untitled',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (conversation.transcript != null) ...[
              const SizedBox(height: 8),
              Text(
                conversation.transcript!.length > 150
                    ? '${conversation.transcript!.substring(0, 150)}...'
                    : conversation.transcript!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard(OmiMemory memory) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/memory/${memory.id}'),
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _getImportanceColor(memory.importance),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTypeBadge(memory.type),
                        const SizedBox(width: 8),
                        _buildImportanceIndicator(memory.importance),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      memory.content.length > 100
                          ? '${memory.content.substring(0, 100)}...'
                          : memory.content,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersSummary(int pending, int completed) {
    final total = pending + completed;
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed of $total completed',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF70E1F5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF70E1F5)),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItemCard(OmiActionItem actionItem) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: actionItem.completed
                    ? const Color(0xFF70E1F5)
                    : Colors.transparent,
                border: Border.all(
                  color: actionItem.completed
                      ? const Color(0xFF70E1F5)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: actionItem.completed
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actionItem.title,
                    style: TextStyle(
                      color: Colors.white,
                      decoration: actionItem.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (actionItem.dueDate != null)
                    Text(
                      'Due: ${DateFormat('h:mm a').format(actionItem.dueDate!)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No activity on ${DateFormat('MMMM d').format(_selectedDate)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start speaking to create memories',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF70E1F5).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF70E1F5),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImportanceIndicator(int importance) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < importance
                ? _getImportanceColor(importance)
                : Colors.white.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }

  Color _getLanguageColor(String language) {
    switch (language) {
      case 'hi':
        return Colors.orange;
      case 'gu':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getImportanceColor(int importance) {
    if (importance >= 4) return Colors.red;
    if (importance >= 3) return Colors.orange;
    return Colors.green;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _shareSummary() {
    debugPrint('Share summary for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}');
  }
}
