import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/api/omi_models.dart';
import 'omi_endpoints.dart';

class OmiSyncManager {
  OmiSyncManager._();

  static OmiSyncManager? _instance;
  static OmiSyncManager get instance => _instance ??= OmiSyncManager._();

  Timer? _periodicSyncTimer;
  Timer? _debounceTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final List<VoidCallback> _listeners = [];

  static const Duration _syncInterval = Duration(seconds: 30);
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  void startPeriodicSync() {
    stopPeriodicSync();
    _periodicSyncTimer = Timer.periodic(_syncInterval, (_) => syncAll());
    debugPrint('OmiSyncManager: Started periodic sync every 30 seconds');
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    debugPrint('OmiSyncManager: Stopped periodic sync');
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('OmiSyncManager: Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;
    _lastSyncTime = DateTime.now();
    _notifyListeners();

    try {
      await Future.wait([
        OmiApi.getConversations(),
        OmiApi.getMemories(),
        OmiApi.getActionItems(),
      ]);
      debugPrint('OmiSyncManager: Full sync completed at $_lastSyncTime');
    } catch (e) {
      debugPrint('OmiSyncManager: Sync error: $e');
    } finally {
      _isSyncing = false;
      _notifyListeners();
    }
  }

  void triggerSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, syncAll);
  }

  void triggerImmediateSync() {
    _debounceTimer?.cancel();
    syncAll();
  }

  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;

  void dispose() {
    stopPeriodicSync();
    _debounceTimer?.cancel();
    _listeners.clear();
  }
}

final omiSyncManagerProvider = Provider<OmiSyncManager>((ref) {
  final manager = OmiSyncManager.instance;
  ref.onDispose(manager.dispose);
  return manager;
});