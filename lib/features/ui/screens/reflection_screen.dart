import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/omi_realtime_provider.dart';
import '../../../core/services/omi/omi_endpoints.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/api/omi_models.dart';

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  List<OmiReflection> _reflections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReflections();
  }

  Future<void> _loadReflections() async {
    setState(() => _isLoading = true);

    try {
      final response = await OmiApi.getReflections(limit: 30);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _reflections = response.data as List<OmiReflection>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('ReflectionScreen: Error loading reflections: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(omiRealtimeProvider);
    final todayMemories = state.memories.where((m) {
      return _isToday(m.createdAt);
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildTodayInsights(todayMemories),
                        const SizedBox(height: 24),
                        _buildMoodSection(),
                        const SizedBox(height: 24),
                        _buildReflectionCards(),
                        const SizedBox(height: 24),
                        _buildQuickReflections(),
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
              'Reflection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddReflectionDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayInsights(List<OmiMemory> todayMemories) {
    final taskCount = todayMemories.where((m) => m.type == 'task').length;
    final eventCount = todayMemories.where((m) => m.type == 'event').length;
    final factCount = todayMemories.where((m) => m.type == 'fact').length;
    final reminderCount = todayMemories.where((m) => m.type == 'reminder').length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight, color: Color(0xFF70E1F5)),
              const SizedBox(width: 8),
              const Text(
                "Today's Journey",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMMM d').format(DateTime.now()),
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInsightItem(Icons.task_alt, taskCount, 'Tasks', Colors.blue),
              _buildInsightItem(Icons.event, eventCount, 'Events', Colors.purple),
              _buildInsightItem(Icons.lightbulb_outline, factCount, 'Facts', Colors.amber),
              _buildInsightItem(Icons.notifications_outlined, reminderCount, 'Reminders', Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightText(todayMemories),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, int count, String label, Color color) {
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
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildInsightText(List<OmiMemory> memories) {
    if (memories.isEmpty) {
      return const Text(
        'No memories captured today yet.',
        style: TextStyle(color: Colors.white54),
      );
    }

    final importantMemories = memories.where((m) => m.importance >= 4).toList();
    if (importantMemories.isNotEmpty) {
      return Text(
        'You captured ${memories.length} memories today, including ${importantMemories.length} high-importance ones.',
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      );
    }

    return Text(
      'You captured ${memories.length} memories today. Keep speaking to capture more!',
      style: const TextStyle(color: Colors.white70, fontSize: 13),
    );
  }

  Widget _buildMoodSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodButton('😊', 'Great', Colors.green),
              _buildMoodButton('🙂', 'Good', Colors.blue),
              _buildMoodButton('😐', 'Okay', Colors.grey),
              _buildMoodButton('😔', 'Low', Colors.orange),
              _buildMoodButton('😤', 'Frustrated', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String emoji, String label, Color color) {
    return InkWell(
      onTap: () => _saveMood(label.toLowerCase()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReflectionCards() {
    if (_reflections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Past Reflections',
          style: TextStyle(
            color: Color(0xFF70E1F5),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._reflections.take(5).map((r) => _buildReflectionCard(r)),
      ],
    );
  }

  Widget _buildReflectionCard(OmiReflection reflection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (reflection.mood != null)
                  Text(
                    _getMoodEmoji(reflection.mood!),
                    style: const TextStyle(fontSize: 24),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(reflection.date),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (reflection.content != null) ...[
              const SizedBox(height: 8),
              Text(
                reflection.content!,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (reflection.tags != null && reflection.tags!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: reflection.tags!.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReflections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Reflections',
          style: TextStyle(
            color: Color(0xFF70E1F5),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickReflectionChip('What went well today?', Icons.thumb_up_outlined),
            _buildQuickReflectionChip('What could be better?', Icons.trending_up),
            _buildQuickReflectionChip('What did I learn?', Icons.school_outlined),
            _buildQuickReflectionChip('What am I grateful for?', Icons.favorite_outline),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickReflectionChip(String text, IconData icon) {
    return InkWell(
      onTap: () => _showQuickReflectionDialog(text),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'great':
      case 'happy':
        return '😊';
      case 'good':
        return '🙂';
      case 'okay':
      case 'neutral':
        return '😐';
      case 'low':
      case 'sad':
        return '😔';
      case 'frustrated':
      case 'angry':
        return '😤';
      default:
        return '😐';
    }
  }

  Future<void> _saveMood(String mood) async {
    debugPrint('ReflectionScreen: Saving mood: $mood');

    final reflection = OmiReflection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      mood: mood,
      tags: ['mood', mood],
    );

    try {
      await OmiApi.createReflection(reflection);
      await _loadReflections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood saved: ${_getMoodEmoji(mood)}'),
            backgroundColor: const Color(0xFF70E1F5),
          ),
        );
      }
    } catch (e) {
      debugPrint('ReflectionScreen: Error saving mood: $e');
    }
  }

  void _showAddReflectionDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f2e),
        title: const Text('New Reflection', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Write your thoughts...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF70E1F5)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF70E1F5),
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final reflection = OmiReflection(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: DateTime.now(),
                  content: controller.text,
                );

                await OmiApi.createReflection(reflection);
                await _loadReflections();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showQuickReflectionDialog(String prompt) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f2e),
        title: Text(prompt, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Your response...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF70E1F5),
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final reflection = OmiReflection(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: DateTime.now(),
                  content: '${prompt.replaceAll('?', '')}: ${controller.text}',
                  tags: [prompt.split(' ').first.toLowerCase()],
                );

                await OmiApi.createReflection(reflection);
                await _loadReflections();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
