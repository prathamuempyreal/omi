import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../../data/models/memory_record.dart';
import '../../reminder/services/reminder_manager.dart';
import '../../settings/providers/settings_provider.dart';
import '../services/gemini_service.dart';

final memoryProvider = NotifierProvider<MemoryController, MemoryState>(
  MemoryController.new,
);

const _memoryStateUnset = Object();

class MemoryState {
  const MemoryState({
    required this.memories,
    required this.isLoading,
    required this.isProcessing,
    required this.pendingAiJobs,
    this.activeFilter,
    this.errorMessage,
  });

  factory MemoryState.initial() => const MemoryState(
    memories: [],
    isLoading: false,
    isProcessing: false,
    pendingAiJobs: 0,
  );

  final List<MemoryRecord> memories;
  final bool isLoading;
  final bool isProcessing;
  final int pendingAiJobs;
  final String? activeFilter;
  final String? errorMessage;

  MemoryState copyWith({
    List<MemoryRecord>? memories,
    bool? isLoading,
    bool? isProcessing,
    int? pendingAiJobs,
    Object? activeFilter = _memoryStateUnset,
    String? errorMessage,
  }) {
    return MemoryState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      pendingAiJobs: pendingAiJobs ?? this.pendingAiJobs,
      activeFilter: activeFilter == _memoryStateUnset
          ? this.activeFilter
          : activeFilter as String?,
      errorMessage: errorMessage,
    );
  }
}

class MemoryController extends Notifier<MemoryState> {
  static const _queueKey = 'pending_ai_jobs';
  final _uuid = const Uuid();

  @override
  MemoryState build() {
    Future.microtask(() async {
      await loadMemories();
      await flushPendingQueue();
    });
    return MemoryState.initial();
  }

  Future<void> loadMemories({String? filter}) async {
    state = state.copyWith(isLoading: true, activeFilter: filter);
    final database = ref.read(appDatabaseProvider);

    try {
      final memories = filter == null || filter == 'all'
          ? await database.getAllMemories()
          : await database.getMemoriesByType(filter);

      state = state.copyWith(
        memories: memories,
        isLoading: false,
        pendingAiJobs: _pendingJobs.length,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        pendingAiJobs: _pendingJobs.length,
        errorMessage: 'Memories could not be loaded right now.',
      );
    }
  }

  Future<MemoryRecord?> getMemory(String id) async {
    final fromState = state.memories.where((memory) => memory.id == id);
    if (fromState.isNotEmpty) {
      return fromState.first;
    }
    return ref.read(appDatabaseProvider).getMemoryById(id);
  }

  Future<void> processTranscript(String transcript) async {
    final normalized = transcript.trim();
    if (normalized.isEmpty) {
      print("MEMORY: Empty transcript, skipping");
      return;
    }

    print("MEMORY: Starting to process transcript: $normalized");
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      print("MEMORY: Calling Gemini to extract memory");
      final result = await ref.read(geminiProvider).extractMemory(normalized);
      print(
        "MEMORY: Gemini result - type: ${result.type}, content: ${result.content}",
      );

      final memory = MemoryRecord(
        id: _uuid.v4(),
        type: result.type,
        content: result.content,
        datetimeRaw: result.datetimeRaw,
        importance: result.importance,
        createdAt: DateTime.now(),
      );

      print("MEMORY: Inserting memory into database");
      await ref.read(appDatabaseProvider).insertMemory(memory);

      if (memory.type.contains('reminder')) {
        print("MEMORY: Creating reminder for memory: ${memory.content}");
        final reminderResult = await ref.read(reminderManagerProvider).processMemoryForReminder(memory);
        print("MEMORY: Reminder created: $reminderResult");
      }

      if (result.shouldRetry &&
          ref.read(settingsProvider).offlineRetryEnabled) {
        await _enqueuePendingJob(memory.id, normalized);
      }

      print("MEMORY: Reloading memories");
      await loadMemories(filter: state.activeFilter);
      state = state.copyWith(
        isProcessing: false,
        pendingAiJobs: _pendingJobs.length,
        errorMessage: null,
      );
      await ref.read(settingsProvider.notifier).refreshPermissions();
      print("MEMORY: Processing complete");
    } catch (e) {
      print("MEMORY: Error during processing: $e");
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Memory processing failed, but the app stayed safe.',
      );
    }
  }

  Future<void> updateMemory(MemoryRecord memory) async {
    await ref.read(appDatabaseProvider).updateMemory(memory);
    await loadMemories(filter: state.activeFilter);
  }

  Future<void> deleteMemory(String id) async {
    await ref.read(appDatabaseProvider).deleteMemory(id);
    await loadMemories(filter: state.activeFilter);
  }

  Future<void> flushPendingQueue() async {
    if (!ref.read(settingsProvider).offlineRetryEnabled) {
      state = state.copyWith(
        pendingAiJobs: _pendingJobs.length,
        errorMessage: null,
      );
      return;
    }

    if (_pendingJobs.isEmpty) {
      state = state.copyWith(pendingAiJobs: 0, errorMessage: null);
      return;
    }

    try {
      final jobs = List<Map<String, dynamic>>.from(_pendingJobs);
      final remaining = <Map<String, dynamic>>[];

      for (final job in jobs) {
        final transcript = job['transcript']?.toString() ?? '';
        final memoryId = job['memoryId']?.toString() ?? '';
        if (transcript.isEmpty || memoryId.isEmpty) {
          continue;
        }

        final result = await ref.read(geminiProvider).extractMemory(transcript);
        if (result.usedFallback) {
          remaining.add(job);
          continue;
        }

        final existing = await ref
            .read(appDatabaseProvider)
            .getMemoryById(memoryId);
        if (existing == null) {
          continue;
        }

        await ref
            .read(appDatabaseProvider)
            .updateMemory(
              existing.copyWith(
                type: result.type,
                content: result.content,
                datetimeRaw: result.datetimeRaw,
                importance: result.importance,
              ),
            );
      }

      await _writeQueue(remaining);
      await loadMemories(filter: state.activeFilter);
    } catch (_) {
      state = state.copyWith(
        pendingAiJobs: _pendingJobs.length,
        errorMessage: 'Queued AI jobs could not be retried right now.',
      );
    }
  }

  List<Map<String, dynamic>> get _pendingJobs {
    final prefs = ref.read(sharedPreferencesProvider);
    final items = prefs.getStringList(_queueKey) ?? const <String>[];
    return items
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }

  Future<void> _enqueuePendingJob(String memoryId, String transcript) async {
    final items = _pendingJobs
      ..add({'id': _uuid.v4(), 'memoryId': memoryId, 'transcript': transcript});
    await _writeQueue(items);
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> jobs) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_queueKey, jobs.map(jsonEncode).toList());
  }
}
