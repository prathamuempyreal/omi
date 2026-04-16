import 'package:drift/drift.dart';

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.transcriptSnippet,
    required this.memoryCount,
    required this.durationSeconds,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? transcriptSnippet;
  final int memoryCount;
  final int? durationSeconds;

  Duration? get duration => durationSeconds != null
      ? Duration(seconds: durationSeconds!)
      : endedAt?.difference(startedAt);

  factory SessionRecord.fromRow(QueryRow row) {
    return SessionRecord(
      id: row.read<String>('id'),
      startedAt: DateTime.parse(row.read<String>('started_at')).toLocal(),
      endedAt: row.readNullable<String>('ended_at') == null
          ? null
          : DateTime.parse(row.read<String>('ended_at')).toLocal(),
      transcriptSnippet: row.readNullable<String>('transcript_snippet'),
      memoryCount: row.readNullable<int>('memory_count') ?? 0,
      durationSeconds: row.readNullable<int>('duration_seconds'),
    );
  }

  SessionRecord copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    String? transcriptSnippet,
    int? memoryCount,
    int? durationSeconds,
  }) {
    return SessionRecord(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      transcriptSnippet: transcriptSnippet ?? this.transcriptSnippet,
      memoryCount: memoryCount ?? this.memoryCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}
