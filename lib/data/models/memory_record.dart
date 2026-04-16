import 'package:drift/drift.dart';

const _memoryUnset = Object();

class MemoryRecord {
  const MemoryRecord({
    required this.id,
    required this.type,
    required this.content,
    required this.datetimeRaw,
    required this.importance,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String content;
  final String? datetimeRaw;
  final int importance;
  final DateTime createdAt;

  factory MemoryRecord.fromRow(QueryRow row) {
    return MemoryRecord(
      id: row.read<String>('id'),
      type: row.read<String>('type'),
      content: row.read<String>('content'),
      datetimeRaw: row.readNullable<String>('datetime_raw'),
      importance: row.read<int>('importance'),
      createdAt: DateTime.parse(row.read<String>('created_at')).toLocal(),
    );
  }

  MemoryRecord copyWith({
    String? id,
    String? type,
    String? content,
    Object? datetimeRaw = _memoryUnset,
    int? importance,
    DateTime? createdAt,
  }) {
    return MemoryRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      datetimeRaw: datetimeRaw == _memoryUnset
          ? this.datetimeRaw
          : datetimeRaw as String?,
      importance: importance ?? this.importance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
