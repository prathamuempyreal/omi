import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../data/models/api/omi_models.dart';
import '../../sessions/providers/session_provider.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  static const _languageFilters = ['all', 'en', 'hi', 'gu'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Conversations')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(sessionProvider.notifier).loadConversations(
            languageFilter: state.languageFilter,
          );
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _buildLanguageFilters(context, ref, state),
            const SizedBox(height: 16),
            if (state.errorMessage != null) ...[
              GlassCard(child: Text(state.errorMessage!)),
              const SizedBox(height: 12),
            ],
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.sessions.isEmpty)
              const GlassCard(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Conversations will appear here after you speak.',
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
              ...state.sessions.map((conversation) {
                return _ConversationCard(
                  conversation: conversation,
                  onTap: () => _showConversationDetail(context, conversation),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageFilters(BuildContext context, WidgetRef ref, SessionState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _languageFilters.map((filter) {
          final isSelected = (state.languageFilter ?? 'all') == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_getLanguageLabel(filter)),
              selected: isSelected,
              onSelected: (_) {
                ref.read(sessionProvider.notifier).loadConversations(
                  languageFilter: filter,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getLanguageLabel(String filter) {
    switch (filter) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'gu':
        return 'ગુજરાતી';
      default:
        return 'All';
    }
  }

  void _showConversationDetail(BuildContext context, OmiConversation conversation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1f2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ConversationDetailSheet(conversation: conversation),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.onTap,
  });

  final OmiConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = conversation.updatedAt == null &&
        (conversation.metadata?['endedAt'] == null);
    final endedAt = conversation.metadata?['endedAt'] != null
        ? DateTime.tryParse(conversation.metadata!['endedAt'].toString())
        : null;
    final memoryCount = conversation.metadata?['memoryCount'] ?? 0;
    final duration = endedAt != null
        ? endedAt.difference(conversation.createdAt)
        : (conversation.updatedAt != null
            ? conversation.updatedAt!.difference(conversation.createdAt)
            : null);

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
                  if (conversation.language != null)
                    _LanguageBadge(language: conversation.language!),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conversation.title ?? DateFormat('MMM d, h:mm a').format(conversation.createdAt),
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _SessionBadge(
                    label: isLive ? 'LIVE' : 'DONE',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SessionStat(
                    label: 'Duration',
                    value: duration == null
                        ? 'Pending'
                        : '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s',
                  ),
                  _SessionStat(
                    label: 'Memories',
                    value: '$memoryCount',
                  ),
                  _SessionStat(
                    label: 'Time',
                    value: DateFormat('h:mm a').format(conversation.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                conversation.transcript?.trim().isNotEmpty == true
                    ? (conversation.transcript!.length > 200
                        ? '${conversation.transcript!.substring(0, 200)}...'
                        : conversation.transcript!)
                    : 'No transcript captured.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.touch_app, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view full transcript',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
}

class _ConversationDetailSheet extends StatelessWidget {
  const _ConversationDetailSheet({required this.conversation});

  final OmiConversation conversation;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (conversation.language != null)
                    _LanguageBadge(language: conversation.language!),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conversation.title ?? 'Conversation',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(conversation.createdAt),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (conversation.summary != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF70E1F5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF70E1F5).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.summarize,
                                color: const Color(0xFF70E1F5),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Summary',
                                style: TextStyle(
                                  color: Color(0xFF70E1F5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            conversation.summary!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Full Transcript',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      conversation.transcript ?? 'No transcript available.',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SessionBadge extends StatelessWidget {
  const _SessionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB77C).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFFFFB77C),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  const _SessionStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}