import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/omi_realtime_provider.dart';
import '../../../core/services/omi/omi_sync_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/api/omi_models.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<SearchResults>((ref) {
  final query = ref.watch(searchQueryProvider);
  final state = ref.watch(omiRealtimeProvider);
  
  if (query.isEmpty) {
    return SearchResults.empty();
  }
  
  return _performSearch(query, state);
});

SearchResults _performSearch(String query, OmiRealtimeState state) {
  final lowerQuery = query.toLowerCase();
  final lowerQueryHindi = query;
  final lowerQueryGujarati = query;
  
  final conversations = state.conversations.where((c) {
    final transcript = c.transcript?.toLowerCase() ?? '';
    final title = c.title?.toLowerCase() ?? '';
    return transcript.contains(lowerQuery) || title.contains(lowerQuery);
  }).toList();
  
  final memories = state.memories.where((m) {
    final content = m.content.toLowerCase();
    return content.contains(lowerQuery);
  }).toList();
  
  final actionItems = state.actionItems.where((a) {
    final title = a.title.toLowerCase();
    final description = a.description?.toLowerCase() ?? '';
    return title.contains(lowerQuery) || description.contains(lowerQuery);
  }).toList();
  
  final dailySummaries = state.dailySummary != null
      ? (state.dailySummary!.summary?.toLowerCase().contains(lowerQuery) == true
          ? <OmiDailySummary>[state.dailySummary!]
          : <OmiDailySummary>[])
      : <OmiDailySummary>[];
  
  return SearchResults(
    conversations: conversations,
    memories: memories,
    actionItems: actionItems,
    dailySummaries: dailySummaries,
    query: query,
  );
}

class SearchResults {
  final List<OmiConversation> conversations;
  final List<OmiMemory> memories;
  final List<OmiActionItem> actionItems;
  final List<OmiDailySummary> dailySummaries;
  final String query;

  SearchResults({
    required this.conversations,
    required this.memories,
    required this.actionItems,
    required this.dailySummaries,
    required this.query,
  });

  factory SearchResults.empty() => SearchResults(
    conversations: [],
    memories: [],
    actionItems: [],
    dailySummaries: [],
    query: '',
  );

  int get totalCount => conversations.length + memories.length + actionItems.length + dailySummaries.length;

  bool get isEmpty => totalCount == 0;

  bool get isNotEmpty => !isEmpty;
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showFilters = false;
  String _languageFilter = 'all';
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

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
            _buildSearchHeader(context, screenWidth),
            if (_showFilters) _buildFilters(screenWidth),
            Expanded(
              child: searchResults.query.isEmpty
                  ? _buildEmptyState()
                  : searchResults.isEmpty
                      ? _buildNoResults(searchResults.query)
                      : _buildResults(searchResults),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(Icons.search, color: Colors.white54),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Ask Omi - "What did we discuss about login?"',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          onChanged: (value) {
                            ref.read(searchQueryProvider.notifier).state = value;
                          },
                          onSubmitted: (_) {
                            _performNaturalLanguageQuery(_searchController.text);
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: _showFilters ? const Color(0xFF70E1F5) : Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickQueries(),
        ],
      ),
    );
  }

  Widget _buildQuickQueries() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickChip('Tomorrow reminders', () => _search('reminder tomorrow')),
          _buildQuickChip('Hindi conversations', () => _searchLanguage('hi')),
          _buildQuickChip('Gujarati conversations', () => _searchLanguage('gu')),
          _buildQuickChip('Pending tasks', () => _search('pending task')),
          _buildQuickChip('Important memories', () => _searchImportance(5)),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Language Filter',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', _languageFilter, (v) {
                  setState(() => _languageFilter = v);
                }),
                _buildFilterChip('English', 'en', _languageFilter, (v) {
                  setState(() => _languageFilter = v);
                }),
                _buildFilterChip('Hindi', 'hi', _languageFilter, (v) {
                  setState(() => _languageFilter = v);
                }),
                _buildFilterChip('Gujarati', 'gu', _languageFilter, (v) {
                  setState(() => _languageFilter = v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Type Filter',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', _typeFilter, (v) {
                  setState(() => _typeFilter = v);
                }),
                _buildFilterChip('Reminders', 'reminder', _typeFilter, (v) {
                  setState(() => _typeFilter = v);
                }),
                _buildFilterChip('Tasks', 'task', _typeFilter, (v) {
                  setState(() => _typeFilter = v);
                }),
                _buildFilterChip('Events', 'event', _typeFilter, (v) {
                  setState(() => _typeFilter = v);
                }),
                _buildFilterChip('Facts', 'fact', _typeFilter, (v) {
                  setState(() => _typeFilter = v);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, Function(String) onSelected) {
    final isSelected = value == current;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF70E1F5).withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF70E1F5) : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF70E1F5) : Colors.white70,
              fontSize: 12,
            ),
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
            Icons.search_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'Search your second brain',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Ask questions like:\n"What reminders do I have tomorrow?"\n"Show Hindi conversations"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try different keywords or filters',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchResults results) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildResultCount(results),
        if (results.conversations.isNotEmpty)
          _buildSection('Conversations', Icons.chat_bubble_outline, results.conversations.length),
        ...results.conversations.map((c) => _buildConversationCard(c)),
        if (results.memories.isNotEmpty)
          _buildSection('Memories', Icons.auto_awesome_mosaic, results.memories.length),
        ...results.memories.map((m) => _buildMemoryCard(m)),
        if (results.actionItems.isNotEmpty)
          _buildSection('Reminders & Tasks', Icons.notifications_outlined, results.actionItems.length),
        ...results.actionItems.map((a) => _buildActionItemCard(a)),
        if (results.dailySummaries.isNotEmpty)
          _buildSection('Daily Summaries', Icons.summarize_outlined, results.dailySummaries.length),
        ...results.dailySummaries.map((s) => _buildSummaryCard(s)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildResultCount(SearchResults results) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        '${results.totalCount} results for "${results.query}"',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
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
      child: InkWell(
        onTap: () {
          // Navigate to conversation detail
        },
        borderRadius: BorderRadius.circular(16),
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
                    _formatDate(conversation.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                conversation.title ?? 'Untitled Conversation',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (conversation.transcript != null) ...[
                const SizedBox(height: 8),
                Text(
                  conversation.transcript!.length > 100
                      ? '${conversation.transcript!.substring(0, 100)}...'
                      : conversation.transcript!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeBadge(memory.type),
                  const Spacer(),
                  _buildImportanceIndicator(memory.importance),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(memory.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                memory.content.length > 150
                    ? '${memory.content.substring(0, 150)}...'
                    : memory.content,
                style: const TextStyle(color: Colors.white),
              ),
              if (memory.datetimeRaw != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      memory.datetimeRaw!,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItemCard(OmiActionItem actionItem) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
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
                        'Due: ${DateFormat('MMM d, h:mm a').format(actionItem.dueDate!)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(OmiDailySummary summary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.summarize, color: Color(0xFF70E1F5), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM d, yyyy').format(summary.date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${summary.memoriesCount} memories',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (summary.summary != null) ...[
                const SizedBox(height: 8),
                Text(
                  summary.summary!.length > 200
                      ? '${summary.summary!.substring(0, 200)}...'
                      : summary.summary!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${DateFormat('h:mm a').format(date)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _search(String query) {
    _searchController.text = query;
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void _searchLanguage(String language) {
    final state = ref.read(omiRealtimeProvider);
    List<OmiConversation> filtered;

    if (language == 'hi') {
      filtered = state.conversations.where((c) => c.language == 'hi').toList();
    } else if (language == 'gu') {
      filtered = state.conversations.where((c) => c.language == 'gu').toList();
    } else {
      filtered = state.conversations;
    }

    setState(() {
      _showFilters = false;
    });
  }

  void _searchImportance(int minImportance) {
    final state = ref.read(omiRealtimeProvider);
    final filtered = state.memories.where((m) => m.importance >= minImportance).toList();
    
    debugPrint('Search: Found ${filtered.length} memories with importance >= $minImportance');
  }

  void _performNaturalLanguageQuery(String query) {
    final lowerQuery = query.toLowerCase();

    debugPrint('Ask Omi: Processing natural language query: "$query"');

    if (lowerQuery.contains('tomorrow') && (lowerQuery.contains('reminder') || lowerQuery.contains('task'))) {
      _search('tomorrow');
    } else if (lowerQuery.contains('what') && lowerQuery.contains('discuss')) {
      final topic = query.replaceAll(RegExp(r'.*about\s*', caseSensitive: false), '').trim();
      _search(topic);
    } else if (lowerQuery.contains('hindi')) {
      _searchLanguage('hi');
    } else if (lowerQuery.contains('gujarati')) {
      _searchLanguage('gu');
    } else if (lowerQuery.contains('pending') || lowerQuery.contains('incomplete')) {
      _search('pending');
    } else {
      _search(query);
    }
  }
}
