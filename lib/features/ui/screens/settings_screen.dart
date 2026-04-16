import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/permission_services.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../memory/providers/memory_provider.dart';
import '../../reminder/providers/reminder_provider.dart';
import '../../settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final memoryState = ref.watch(memoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.microphoneGranted,
                  onChanged: (_) {
                    ref.read(settingsProvider.notifier).requestPermissions();
                  },
                  title: const Text('Microphone access'),
                  subtitle: Text(
                    settings.microphoneGranted
                        ? 'Ready for live capture'
                        : 'Required for recording',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.notificationsEnabled,
                  onChanged: (value) async {
                    await ref
                        .read(settingsProvider.notifier)
                        .setNotificationsEnabled(value);
                    await ref
                        .read(reminderProvider.notifier)
                        .refreshSchedulesForPreferences();
                  },
                  title: const Text('Reminder notifications'),
                  subtitle: Text(
                    settings.notificationsGranted
                        ? settings.notificationsEnabled
                              ? 'Alerts are scheduled locally'
                              : 'Saved reminders stay silent'
                        : 'Permission required for alerts',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.offlineRetryEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setOfflineRetryEnabled(value);
                  },
                  title: const Text('Offline retry'),
                  subtitle: Text(
                    'Queued AI jobs: ${memoryState.pendingAiJobs}',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.pcmAssistEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setPcmAssistEnabled(value);
                  },
                  title: const Text('PCM assist'),
                  subtitle: const Text(
                    'Keep raw audio stream available as a fallback',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(settingsProvider.notifier)
                        .setThemeMode(selection.first);
                  },
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light',style: TextStyle(fontSize: 12),),
                      icon: Icon(Icons.light_mode_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark',style: TextStyle(fontSize: 12),),
                      icon: Icon(Icons.dark_mode_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System',style: TextStyle(fontSize: 12),),
                      icon: Icon(Icons.phone_iphone_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: settings.offlineRetryEnabled
                      ? () {
                          ref.read(memoryProvider.notifier).flushPendingQueue();
                        }
                      : null,
                  child: const Text('Retry queued AI jobs'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: PermissionService.openSettings,
                  child: const Text('Open system settings'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).resetOnboarding();
                  },
                  child: const Text('Show onboarding again'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
