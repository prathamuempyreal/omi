import 'package:drift/drift.dart';

class ReminderRecord {
  const ReminderRecord({
    required this.id,
    required this.memoryId,
    required this.scheduledTime,
    required this.status,
  });

  final String id;
  final String memoryId;
  final DateTime scheduledTime;
  final String status;

  int get notificationId => id.hashCode;

  factory ReminderRecord.fromRow(QueryRow row) {
    return ReminderRecord(
      id: row.read<String>('id'),
      memoryId: row.read<String>('memory_id'),
      scheduledTime: DateTime.parse(
        row.read<String>('scheduled_time'),
      ).toLocal(),
      status: row.read<String>('status'),
    );
  }

  ReminderRecord copyWith({
    String? id,
    String? memoryId,
    DateTime? scheduledTime,
    String? status,
  }) {
    return ReminderRecord(
      id: id ?? this.id,
      memoryId: memoryId ?? this.memoryId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
    );
  }
}
