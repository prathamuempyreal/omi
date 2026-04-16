import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/services/alarm_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/alarm/screens/alarm_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/ui/screens/home_screen.dart';
import 'features/ui/screens/memory_detail_screen.dart';
import 'features/ui/screens/memory_list_screen.dart';
import 'features/ui/screens/onboarding_screen.dart';
import 'features/ui/screens/reminders_screen.dart';
import 'features/ui/screens/settings_screen.dart';
import 'features/ui/screens/sessions_screen.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final settingsState = ValueNotifier<SettingsState>(
    ref.read(settingsProvider),
  );

  ref.listen<SettingsState>(settingsProvider, (previous, next) {
    settingsState.value = next;
  });

  final router = GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: settingsState,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _LoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/alarm',
        builder: (context, state) => const AlarmScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            _AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/memories',
            builder: (context, state) => const MemoryListScreen(),
          ),
          GoRoute(
            path: '/memory/:id',
            builder: (context, state) =>
                MemoryDetailScreen(memoryId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/reminders',
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: '/sessions',
            builder: (context, state) => const SessionsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF70E1F5).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFF70E1F5),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Page not found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'The requested page could not be loaded.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  ref.onDispose(() {
    settingsState.dispose();
    router.dispose();
  });

  return router;
});

class OmiApp extends ConsumerStatefulWidget {
  const OmiApp({super.key});

  @override
  ConsumerState<OmiApp> createState() => _OmiAppState();
}

class _OmiAppState extends ConsumerState<OmiApp> with WidgetsBindingObserver {
  static bool _errorWidgetConfigured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configureErrorWidget();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingAlarmRoute();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPendingAlarmRoute();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _configureErrorWidget() {
    if (!_errorWidgetConfigured) {
      _errorWidgetConfigured = true;
      ErrorWidget.builder = (details) => _ErrorFallback(error: details.exception);
    }
  }

  Future<void> _openPendingAlarmRoute() async {
    final context = appNavigatorKey.currentContext;
    if (!mounted || context == null) {
      return;
    }

    final shouldOpenAlarm = await consumePendingAlarmRoute();
    if (shouldOpenAlarm) {
      GoRouter.of(context).go('/alarm');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Omi',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}

class _LoadingScreen extends ConsumerStatefulWidget {
  const _LoadingScreen();

  @override
  ConsumerState<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<_LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectAfterLoad();
    });
  }

  Future<void> _redirectAfterLoad() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    final settings = ref.read(settingsProvider);

    if (authState.isLoading == true) {
      _redirectAfterLoad();
      return;
    }

    if (!settings.onboardingCompleted) {
      context.go('/onboarding');
      return;
    }

    if (authState.isAuthenticated == true) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A0E1A),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF70E1F5).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFF70E1F5),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please restart the app to continue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    ErrorWidget.builder = (_) => const SizedBox.shrink();
                    if (context.mounted) {
                      Navigator.of(context).maybePop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.location, required this.child});

  final String location;
  final Widget child;

  int _indexForLocation() {
    if (location.startsWith('/memories') || location.startsWith('/memory/')) {
      return 1;
    }
    if (location.startsWith('/reminders')) {
      return 2;
    }
    if (location.startsWith('/sessions')) {
      return 3;
    }
    if (location.startsWith('/settings')) {
      return 4;
    }
    return 0;
  }

  String _getBackRoute() {
    if (location.startsWith('/memory/')) {
      return '/memories';
    }
    if (location.startsWith('/home')) {
      return '/home';
    }
    return '/home';
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexForLocation();
    const destinations = <String>[
      '/home',
      '/memories',
      '/reminders',
      '/sessions',
      '/settings',
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          final backRoute = _getBackRoute();
          if (backRoute != location) {
            context.go(backRoute);
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        body: child,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              height: 76,
              backgroundColor: const Color(0xDD141B2D),
              selectedIndex: currentIndex,
              indicatorColor: const Color(0xFF70E1F5).withValues(alpha: 0.22),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.graphic_eq_rounded),
                  selectedIcon: Icon(Icons.graphic_eq_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_mosaic_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
                  label: 'Memories',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_active_outlined),
                  selectedIcon: Icon(Icons.notifications_active_rounded),
                  label: 'Reminders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded),
                  selectedIcon: Icon(Icons.history_rounded),
                  label: 'Sessions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_rounded),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: 'Settings',
                ),
              ],
              onDestinationSelected: (index) {
                if (destinations[index] != location) {
                  context.go(destinations[index]);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
