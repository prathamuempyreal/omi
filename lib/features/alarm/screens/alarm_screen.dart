import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/alarm_service.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _alarmPlatform = MethodChannel(
    'com.example.omi/alarm_service',
  );
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    try {
      await _alarmPlatform.invokeMethod<void>('stopAlarm');
    } catch (e) {
      debugPrint('Failed to stop native alarm playback: $e');
    }
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _snooze() async {
    await AlarmService.snooze(const Duration(minutes: 5));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alarm snoozed for 5 minutes'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                      border: Border.all(
                        color: const Color(0xFFDC2626),
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.alarm_rounded,
                      size: 80,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            const Text(
              'ALARM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Time to wake up!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.snooze_rounded,
                  label: 'Snooze',
                  color: const Color(0xFFF59E0B),
                  onPressed: _snooze,
                ),
                _ActionButton(
                  icon: Icons.stop_rounded,
                  label: 'STOP',
                  color: const Color(0xFFDC2626),
                  onPressed: _stopAlarm,
                  isLarge: true,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLarge = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 100.0 : 70.0;
    final iconSize = isLarge ? 48.0 : 32.0;

    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
              border: Border.all(color: color, width: 3),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
