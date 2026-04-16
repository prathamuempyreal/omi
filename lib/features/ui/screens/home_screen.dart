import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/glass_card.dart';
import '../../audio/providers/audio_provider.dart';
import '../../memory/providers/memory_provider.dart';
import '../../reminder/providers/reminder_provider.dart';
import '../../transcription/providers/transcription_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    final transcript = ref.watch(transcriptProvider);
    final memories = ref.watch(memoryProvider);
    final reminders = ref.watch(reminderProvider);
    final recentMemories = memories.memories.take(4).toList();
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (audio.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    audio.errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.all(16),
          ),
        );
        ref.read(audioProvider.notifier).clearError();
      });
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050913), Color(0xFF0D1527), Color(0xFF101E37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(memoryProvider.notifier).loadMemories();
            await ref.read(reminderProvider.notifier).loadReminders();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              const _Header(),
              const SizedBox(height: 20),
              if (memories.errorMessage != null ||
                  reminders.errorMessage != null ||
                  transcript.errorMessage != null) ...[
                GlassCard(
                  child: Text(
                    transcript.errorMessage ??
                        memories.errorMessage ??
                        reminders.errorMessage!,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: audio.isRecording
                                ? const Color(0xFF70E1F5)
                                : Colors.white24,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            audio.isRecording
                                ? 'Listening in real time'
                                : 'Ready to capture your next memory',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _TranscriptPanel(
                        key: UniqueKey(),
                        transcript: transcript,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: screenWidth > 520
                              ? 120
                              : (screenWidth - 76) / 2,
                          child: _MiniMetric(
                            label: 'Chunks',
                            value: '${transcript.audioChunkCount}',
                          ),
                        ),
                        SizedBox(
                          width: screenWidth > 520
                              ? 120
                              : (screenWidth - 76) / 2,
                          child: _MiniMetric(
                            label: 'Memories',
                            value: '${memories.memories.length}',
                          ),
                        ),
                        SizedBox(
                          width: screenWidth > 520
                              ? 120
                              : (screenWidth - 76) / 2,
                          child: _MiniMetric(
                            label: 'Reminders',
                            value: '${reminders.reminders.length}',
                          ),
                        ),
                        SizedBox(
                          width: screenWidth > 520
                              ? 120
                              : (screenWidth - 76) / 2,
                          child: _MiniMetric(
                            label: 'PCM',
                            value: audio.isPcmStreaming
                                ? '${(transcript.audioLevel * 100).round()}%'
                                : 'Off',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 420;
                  final first = _ActionTile(
                    title: 'All memories',
                    subtitle: 'Browse and filter everything',
                    icon: Icons.auto_awesome_mosaic_rounded,
                    onTap: () => context.go('/memories'),
                  );
                  final second = _ActionTile(
                    title: 'Reminders',
                    subtitle: 'Snooze or complete quickly',
                    icon: Icons.notifications_active_rounded,
                    onTap: () => context.go('/reminders'),
                  );

                  if (stacked) {
                    return Column(
                      children: [first, const SizedBox(height: 14), second],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: first),
                      const SizedBox(width: 14),
                      Expanded(child: second),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Recent memories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/memories'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (memories.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (recentMemories.isEmpty)
                const GlassCard(
                  child: Text(
                    'Your saved memories will appear here after the first transcript is processed.',
                  ),
                )
              else
                ...recentMemories.map(
                  (memory) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.go('/memory/${memory.id}'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _TypeBadge(type: memory.type),
                                  const Spacer(),
                                  Text(
                                    DateFormat(
                                      'MMM d, h:mm a',
                                    ).format(memory.createdAt),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                memory.content,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (memory.datetimeRaw != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Reminder: ${memory.datetimeRaw}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                'Omi keeps your spoken moments organized.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        const _PulseMicButton(),
      ],
    );
  }
}

class _PulseMicButton extends ConsumerWidget {
  const _PulseMicButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    final transcript = ref.watch(transcriptProvider);
    final isListening = transcript.isListening || audio.isRecording;
    final isProcessing = transcript.isProcessing;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.95, end: isListening ? 1.12 : 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: InkWell(
            onTap: isProcessing
                ? null
                : () async {
                    final audioNotifier = ref.read(audioProvider.notifier);

                    if (isListening) {
                      await audioNotifier.stopRecording();
                    } else {
                      await audioNotifier.startRecording();
                    }
                  },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isListening
                      ? [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)]
                      : [const Color(0xFF70E1F5), const Color(0xFFFFB77C)],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isListening
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF70E1F5))
                            .withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: isListening ? 6 : 0,
                  ),
                ],
              ),
              child: Icon(
                isProcessing
                    ? Icons.hourglass_empty_rounded
                    : isListening
                    ? Icons.stop_rounded
                    : Icons.mic_rounded,
                color: theme.colorScheme.surface,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isProcessing
                ? 'Processing...'
                : isListening
                ? 'Listening...'
                : 'Tap to speak',
            key: UniqueKey(),
            style: TextStyle(
              color: isListening
                  ? const Color(0xFF70E1F5)
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: isListening ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF70E1F5)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF70E1F5).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF70E1F5),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TranscriptPanel extends StatelessWidget {
  const _TranscriptPanel({super.key, required this.transcript});

  final TranscriptState transcript;

  @override
  Widget build(BuildContext context) {
    final text = transcript.errorMessage != null
        ? transcript.errorMessage!
        : transcript.liveTranscript.isEmpty
        ? 'Tap the mic and speak naturally. Omi will transcribe, structure, and save it for you.'
        : transcript.liveTranscript;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.88),
            height: 1.45,
          ),
        ),
        if (transcript.isProcessing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 3),
        ],
      ],
    );
  }
}
