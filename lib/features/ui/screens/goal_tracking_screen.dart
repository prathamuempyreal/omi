import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/omi_realtime_provider.dart';
import '../../../core/services/omi/omi_endpoints.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/api/omi_models.dart';

final selectedGoalFilterProvider = StateProvider<String>((ref) => 'all');

class GoalTrackingScreen extends ConsumerStatefulWidget {
  const GoalTrackingScreen({super.key});

  @override
  ConsumerState<GoalTrackingScreen> createState() => _GoalTrackingScreenState();
}

class _GoalTrackingScreenState extends ConsumerState<GoalTrackingScreen> {
  List<OmiGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);

    try {
      final response = await OmiApi.getGoals();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _goals = response.data as List<OmiGoal>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('GoalTrackingScreen: Error loading goals: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(omiRealtimeProvider);
    final filter = ref.watch(selectedGoalFilterProvider);

    List<OmiGoal> filteredGoals;
    if (filter == 'all') {
      filteredGoals = _goals;
    } else {
      filteredGoals = _goals.where((g) => g.status == filter).toList();
    }

    final extractedGoals = _extractGoalsFromConversations(state.conversations);

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
            _buildProgressOverview(),
            _buildFilters(filter),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredGoals.isEmpty && extractedGoals.isEmpty
                      ? _buildEmptyState()
                      : _buildGoalsList([...filteredGoals, ...extractedGoals]),
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
              'Goals',
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
            onPressed: () => _showAddGoalDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    final totalGoals = _goals.length;
    final completedGoals = _goals.where((g) => g.status == 'completed').length;
    final inProgressGoals = _goals.where((g) => g.status == 'in_progress').length;
    final progressPercent = totalGoals > 0 ? (completedGoals / totalGoals * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', totalGoals.toString(), Colors.white),
                _buildStatItem('In Progress', inProgressGoals.toString(), Colors.blue),
                _buildStatItem('Completed', completedGoals.toString(), Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressPercent / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF70E1F5)),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$progressPercent%',
                  style: const TextStyle(
                    color: Color(0xFF70E1F5),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
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
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(String currentFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', currentFilter),
            const SizedBox(width: 8),
            _buildFilterChip('In Progress', 'in_progress', currentFilter),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', 'pending', currentFilter),
            const SizedBox(width: 8),
            _buildFilterChip('Completed', 'completed', currentFilter),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current) {
    final isSelected = value == current;

    return InkWell(
      onTap: () {
        ref.read(selectedGoalFilterProvider.notifier).state = value;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF70E1F5).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF70E1F5)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF70E1F5) : Colors.white70,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'No goals yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Goals will be automatically extracted\nfrom your conversations',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF70E1F5),
            ),
            onPressed: () => _showAddGoalDialog(),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Add Goal', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<OmiGoal> goals) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return _buildGoalCard(goals[index]);
      },
    );
  }

  Widget _buildGoalCard(OmiGoal goal) {
    final progress = goal.progress.clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(goal.status ?? 'pending'),
                const Spacer(),
                if (goal.dueDate != null)
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d').format(goal.dueDate!),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                  color: const Color(0xFF1a1f2e),
                  onSelected: (value) => _handleGoalAction(goal, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'progress',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('Update Progress', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              goal.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (goal.description != null) ...[
              const SizedBox(height: 8),
              Text(
                goal.description!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$progress%',
                  style: TextStyle(
                    color: _getProgressColor(progress),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'COMPLETED';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'IN PROGRESS';
        break;
      case 'paused':
        color = Colors.orange;
        label = 'PAUSED';
        break;
      default:
        color = Colors.grey;
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getProgressColor(int progress) {
    if (progress >= 100) return Colors.green;
    if (progress >= 50) return const Color(0xFF70E1F5);
    if (progress >= 25) return Colors.orange;
    return Colors.grey;
  }

  List<OmiGoal> _extractGoalsFromConversations(List<OmiConversation> conversations) {
    final goals = <OmiGoal>[];

    final goalPatterns = [
      RegExp(r'i want to\s+(.+)', caseSensitive: false),
      RegExp(r'my goal is\s+(.+)', caseSensitive: false),
      RegExp(r'i plan to\s+(.+)', caseSensitive: false),
      RegExp(r'i will\s+(.+)', caseSensitive: false),
      RegExp(r'mein\s+(.+)', caseSensitive: false),
      RegExp(r'mujhe\s+(.+)', caseSensitive: false),
      RegExp(r'hu\.?\s*(.+)', caseSensitive: false),
    ];

    for (final conv in conversations) {
      final transcript = conv.transcript ?? '';

      for (final pattern in goalPatterns) {
        final matches = pattern.allMatches(transcript);
        for (final match in matches) {
          final goalText = match.group(1)?.trim();
          if (goalText != null && goalText.length > 5 && goalText.length < 100) {
            goals.add(OmiGoal(
              id: 'extracted_${conv.id}_${match.start}',
              title: goalText,
              description: 'Extracted from conversation: ${conv.title}',
              status: 'pending',
              progress: 0,
              createdAt: conv.createdAt,
              metadata: {'source_conversation': conv.id},
            ));
          }
        }
      }
    }

    return goals;
  }

  void _handleGoalAction(OmiGoal goal, String action) async {
    switch (action) {
      case 'edit':
        _showEditGoalDialog(goal);
        break;
      case 'progress':
        _showUpdateProgressDialog(goal);
        break;
      case 'delete':
        await _deleteGoal(goal);
        break;
    }
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1f2e),
          title: const Text('Add New Goal', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Goal Title',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white54),
                        const SizedBox(width: 12),
                        Text(
                          dueDate != null
                              ? DateFormat('MMMM d, yyyy').format(dueDate!)
                              : 'Set due date (optional)',
                          style: TextStyle(
                            color: dueDate != null ? Colors.white : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                if (titleController.text.isNotEmpty) {
                  final goal = OmiGoal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descController.text.isEmpty ? null : descController.text,
                    status: 'pending',
                    progress: 0,
                    dueDate: dueDate,
                    createdAt: DateTime.now(),
                  );

                  await OmiApi.createGoal(goal);
                  await _loadGoals();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(OmiGoal goal) {
    final titleController = TextEditingController(text: goal.title);
    final descController = TextEditingController(text: goal.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f2e),
        title: const Text('Edit Goal', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Goal Title',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
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
              if (titleController.text.isNotEmpty) {
                await OmiApi.updateGoal(goal.id, {
                  'title': titleController.text,
                  'description': descController.text.isEmpty ? null : descController.text,
                });
                await _loadGoals();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(OmiGoal goal) {
    int progress = goal.progress;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1f2e),
          title: const Text('Update Progress', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$progress%',
                style: const TextStyle(
                  color: Color(0xFF70E1F5),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: const Color(0xFF70E1F5),
                onChanged: (value) {
                  setDialogState(() => progress = value.round());
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildQuickProgressChip(0, progress, setDialogState),
                  _buildQuickProgressChip(25, progress, setDialogState),
                  _buildQuickProgressChip(50, progress, setDialogState),
                  _buildQuickProgressChip(75, progress, setDialogState),
                  _buildQuickProgressChip(100, progress, setDialogState),
                ],
              ),
            ],
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
                await OmiApi.updateGoal(goal.id, {
                  'progress': progress,
                  'status': progress >= 100 ? 'completed' : 'in_progress',
                });
                await _loadGoals();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Update', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickProgressChip(int value, int current, StateSetter setState) {
    final isSelected = value == current;

    return InkWell(
      onTap: () => setState(() {}),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF70E1F5).withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF70E1F5) : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          '$value%',
          style: TextStyle(
            color: isSelected ? const Color(0xFF70E1F5) : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteGoal(OmiGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f2e),
        title: const Text('Delete Goal?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${goal.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await OmiApi.deleteGoal(goal.id);
      await _loadGoals();
    }
  }
}
