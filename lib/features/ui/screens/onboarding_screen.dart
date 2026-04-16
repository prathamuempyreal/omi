import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../features/auth/services/session_helper.dart';
import '../../settings/providers/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const _pages = [
    (
      title: 'Capture thoughts instantly',
      subtitle:
          'Record in real time, transcribe speech, and turn spoken fragments into structured memories.',
    ),
    (
      title: 'Never lose reminders',
      subtitle:
          'Important dates are parsed, adjusted safely, and scheduled as local reminders with snooze support.',
    ),
    (
      title: 'Private by default',
      subtitle:
          'Your database stays local, your history stays searchable, and the app keeps working offline.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050913), Color(0xFF0C1425), Color(0xFF141D36)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Omi',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your voice-first memory assistant.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          height: 320,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _pages.length,
                            onPageChanged: (index) =>
                                setState(() => _currentIndex = index),
                            itemBuilder: (context, index) {
                              final page = _pages[index];
                              return GlassCard(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF70E1F5),
                                              Color(0xFFFFB77C),
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.multitrack_audio_rounded,
                                          size: 36,
                                          color: Color(0xFF08111E),
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      Text(
                                        page.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineMedium,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        page.subtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.72,
                                              ),
                                              height: 1.55,
                                            ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: List.generate(
                                          _pages.length,
                                          (dotIndex) => AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            width: _currentIndex == dotIndex
                                                ? 30
                                                : 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _currentIndex == dotIndex
                                                  ? const Color(0xFF70E1F5)
                                                  : Colors.white24,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        GlassCard(
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  settings.microphoneGranted
                                      ? Icons.mic_rounded
                                      : Icons.mic_off_rounded,
                                ),
                                title: const Text('Microphone permission'),
                                subtitle: Text(
                                  settings.microphoneGranted
                                      ? 'Granted'
                                      : 'Required',
                                ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  settings.notificationsGranted
                                      ? Icons.notifications_active_rounded
                                      : Icons.notifications_off_rounded,
                                ),
                                title: const Text('Notification permission'),
                                subtitle: Text(
                                  settings.notificationsGranted
                                      ? 'Granted'
                                      : 'Recommended',
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: settings.isLoading
                                    ? null
                                    : ref
                                          .read(settingsProvider.notifier)
                                          .requestPermissions,
                                child: Text(
                                  settings.isLoading
                                      ? 'Requesting...'
                                      : 'Grant permissions',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _currentIndex == 0
                                    ? null
                                    : () {
                                        _pageController.previousPage(
                                          duration: const Duration(
                                            milliseconds: 280,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        );
                                      },
                                child: const Text('Back'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  if (_currentIndex < _pages.length - 1) {
                                    await _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 280,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                    return;
                                  }

                                  await ref
                                      .read(settingsProvider.notifier)
                                      .completeOnboarding();
                                  if (context.mounted) {
                                    debugPrint('Session exists: ${await SessionHelper.isLoggedIn()}');
                                    if (await SessionHelper.isLoggedIn()) {
                                      context.go('/home');
                                    } else {
                                      context.go('/login');
                                    }
                                  }
                                },
                                child: Text(
                                  _currentIndex == _pages.length - 1
                                      ? 'Enter Omi'
                                      : 'Next',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
