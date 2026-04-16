import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/glass_card.dart';
import '../../sessions/providers/session_provider.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Sessions')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(sessionProvider.notifier).loadSessions();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
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
                        Icons.mic_none_outlined,
                        size: 48,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No recording sessions yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Recording sessions will appear here after you start using the mic.',
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
              ...state.sessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat(
                                  'MMM d, yyyy - h:mm a',
                                ).format(session.startedAt),
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            _SessionBadge(
                              label: session.endedAt == null ? 'LIVE' : 'DONE',
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
                              value: session.duration == null
                                  ? 'Pending'
                                  : '${session.duration!.inMinutes}m ${session.duration!.inSeconds.remainder(60)}s',
                            ),
                            _SessionStat(
                              label: 'Memories',
                              value: '${session.memoryCount}',
                            ),
                            _SessionStat(
                              label: 'Ended',
                              value: session.endedAt == null
                                  ? 'Active'
                                  : DateFormat('h:mm a').format(session.endedAt!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          session.transcriptSnippet?.trim().isNotEmpty == true
                              ? session.transcriptSnippet!
                              : 'No transcript snippet captured for this session.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.74),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
      constraints: const BoxConstraints(minWidth: 92),
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
