import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/omi_realtime_provider.dart';
import '../../../data/models/api/omi_models.dart';

final memoryProvider = NotifierProvider<MemoryController, MemoryState>(
  MemoryController.new,
);

class MemoryState {
  final List<OmiMemory> memories;
  final bool isLoading;
  final bool isProcessing;
  final int pendingAiJobs;
  final String? activeFilter;
  final String? errorMessage;

  const MemoryState({
    this.memories = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.pendingAiJobs = 0,
    this.activeFilter,
    this.errorMessage,
  });

  MemoryState copyWith({
    List<OmiMemory>? memories,
    bool? isLoading,
    bool? isProcessing,
    int? pendingAiJobs,
    String? activeFilter,
    String? errorMessage,
  }) {
    return MemoryState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      pendingAiJobs: pendingAiJobs ?? this.pendingAiJobs,
      activeFilter: activeFilter ?? this.activeFilter,
      errorMessage: errorMessage,
    );
  }
}

class MemoryController extends Notifier<MemoryState> {
  static const List<String> memoryFilters = ['all', 'note', 'fact', 'event'];

  @override
  MemoryState build() {
    Future.microtask(() => loadMemories());
    return const MemoryState();
  }

  Future<void> loadMemories({String? filter}) async {
    state = state.copyWith(isLoading: true, activeFilter: filter);
    try {
      await ref.read(omiRealtimeProvider.notifier).refreshMemories();
      final omiState = ref.read(omiRealtimeProvider);
      
      var memories = List<OmiMemory>.from(omiState.memories);
      
      if (filter != null && filter != 'all') {
        memories = memories.where((m) => m.type == filter).toList();
      }
      
      memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('MemoryProvider: Loaded memories: ${memories.length}');
      debugPrint('MemoryProvider: Filter: ${filter ?? "all"}');
      debugPrint('MemoryProvider: Memory types - NOTE: ${memories.where((m) => m.type == 'note').length}, '
                  'FACT: ${memories.where((m) => m.type == 'fact').length}, '
                  'EVENT: ${memories.where((m) => m.type == 'event').length}');
      
      state = state.copyWith(
        memories: memories,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('MemoryProvider: Error loading memories: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Memories could not be loaded right now.',
      );
    }
  }

  Future<OmiMemory?> getMemory(String id) async {
    final omiState = ref.read(omiRealtimeProvider);
    final fromState = omiState.memories.where((memory) => memory.id == id);
    if (fromState.isNotEmpty) {
      return fromState.first;
    }
    return null;
  }

  Future<void> createMemory(OmiMemory memory) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      await ref.read(omiRealtimeProvider.notifier).createMemory(memory);
      await loadMemories(filter: state.activeFilter);
      state = state.copyWith(isProcessing: false, errorMessage: null);
    } catch (e) {
      debugPrint('MemoryProvider: Error creating memory: $e');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Memory creation failed.',
      );
    }
  }

  Future<void> updateMemory(OmiMemory memory) async {
    try {
      await ref.read(omiRealtimeProvider.notifier).updateMemory(
        memory.id,
        {
          'type': memory.type,
          'content': memory.content,
          'datetime_raw': memory.datetimeRaw,
          'importance': memory.importance,
        },
      );
      await loadMemories(filter: state.activeFilter);
    } catch (e) {
      debugPrint('MemoryProvider: Error updating memory: $e');
      state = state.copyWith(errorMessage: 'Memory update failed.');
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      await ref.read(omiRealtimeProvider.notifier).deleteMemory(id);
      await loadMemories(filter: state.activeFilter);
    } catch (e) {
      debugPrint('MemoryProvider: Error deleting memory: $e');
      state = state.copyWith(errorMessage: 'Memory deletion failed.');
    }
  }

  Future<void> processTranscript(String transcript) async {
    final normalized = transcript.trim();
    if (normalized.isEmpty) {
      return;
    }

    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final memory = OmiMemory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'note',
        content: normalized,
        importance: 3,
        createdAt: DateTime.now(),
      );

      await ref.read(omiRealtimeProvider.notifier).createMemory(memory);
      await loadMemories(filter: state.activeFilter);
      state = state.copyWith(isProcessing: false, errorMessage: null);
    } catch (e) {
      debugPrint('MemoryProvider: Error processing transcript: $e');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Memory processing failed.',
      );
    }
  }

  Future<void> flushPendingQueue() async {
    // Pending queue handling would be done by sync manager
  }
}