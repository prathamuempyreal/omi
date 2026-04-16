import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/memory_record.dart';
import '../models/reminder_record.dart';
import '../models/session_record.dart';
import '../models/user_record.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

class AppDatabase extends GeneratedDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      await customStatement('''
            CREATE TABLE IF NOT EXISTS memories(
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              content TEXT NOT NULL,
              datetime_raw TEXT,
              importance INTEGER NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');

      await customStatement('''
            CREATE TABLE IF NOT EXISTS reminders(
              id TEXT PRIMARY KEY,
              memory_id TEXT NOT NULL,
              scheduled_time TEXT NOT NULL,
              status TEXT NOT NULL,
              FOREIGN KEY(memory_id) REFERENCES memories(id) ON DELETE CASCADE
            )
          ''');

      await customStatement('''
            CREATE TABLE IF NOT EXISTS sessions(
              id TEXT PRIMARY KEY,
              started_at TEXT NOT NULL,
              ended_at TEXT,
              transcript_snippet TEXT,
              memory_count INTEGER NOT NULL DEFAULT 0,
              duration_seconds INTEGER
            )
          ''');

      await _ensureColumnExists('sessions', 'transcript_snippet', 'TEXT');
      await _ensureColumnExists(
        'sessions',
        'memory_count',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _ensureColumnExists('sessions', 'duration_seconds', 'INTEGER');

      await customStatement('''
            CREATE TABLE IF NOT EXISTS users(
              id TEXT PRIMARY KEY,
              email TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
    },
  );

  Future<int> insertMemory(MemoryRecord memory) {
    return customInsert(
      '''
      INSERT INTO memories(id, type, content, datetime_raw, importance, created_at)
      VALUES(?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable<String>(memory.id),
        Variable<String>(memory.type),
        Variable<String>(memory.content),
        Variable<String>(memory.datetimeRaw),
        Variable<int>(memory.importance),
        Variable<String>(memory.createdAt.toUtc().toIso8601String()),
      ],
    );
  }

  Future<void> updateMemory(MemoryRecord memory) {
    return customUpdate(
      '''
      UPDATE memories
      SET type = ?, content = ?, datetime_raw = ?, importance = ?
      WHERE id = ?
      ''',
      variables: [
        Variable<String>(memory.type),
        Variable<String>(memory.content),
        Variable<String>(memory.datetimeRaw),
        Variable<int>(memory.importance),
        Variable<String>(memory.id),
      ],
      updateKind: UpdateKind.update,
    );
  }

  Future<List<MemoryRecord>> getAllMemories() async {
    final rows = await customSelect(
      'SELECT * FROM memories ORDER BY created_at DESC',
    ).get();
    return rows.map(MemoryRecord.fromRow).toList();
  }

  Future<List<MemoryRecord>> getMemoriesByType(String type) async {
    final rows = await customSelect(
      'SELECT * FROM memories WHERE type = ? ORDER BY created_at DESC',
      variables: [Variable<String>(type)],
    ).get();
    return rows.map(MemoryRecord.fromRow).toList();
  }

  Future<MemoryRecord?> getMemoryById(String id) async {
    final rows = await customSelect(
      'SELECT * FROM memories WHERE id = ? LIMIT 1',
      variables: [Variable<String>(id)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return MemoryRecord.fromRow(rows.first);
  }

  Future<void> deleteMemory(String id) {
    return customUpdate(
      'DELETE FROM memories WHERE id = ?',
      variables: [Variable<String>(id)],
      updateKind: UpdateKind.delete,
    );
  }

  Future<int> insertReminder(ReminderRecord reminder) {
    return customInsert(
      '''
      INSERT INTO reminders(id, memory_id, scheduled_time, status)
      VALUES(?, ?, ?, ?)
      ''',
      variables: [
        Variable<String>(reminder.id),
        Variable<String>(reminder.memoryId),
        Variable<String>(reminder.scheduledTime.toUtc().toIso8601String()),
        Variable<String>(reminder.status),
      ],
    );
  }

  Future<void> updateReminder(ReminderRecord reminder) {
    return customUpdate(
      '''
      UPDATE reminders
      SET scheduled_time = ?, status = ?
      WHERE id = ?
      ''',
      variables: [
        Variable<String>(reminder.scheduledTime.toUtc().toIso8601String()),
        Variable<String>(reminder.status),
        Variable<String>(reminder.id),
      ],
      updateKind: UpdateKind.update,
    );
  }

  Future<List<ReminderRecord>> getAllReminders() async {
    final rows = await customSelect(
      'SELECT * FROM reminders ORDER BY scheduled_time ASC',
    ).get();
    return rows.map(ReminderRecord.fromRow).toList();
  }

  Future<ReminderRecord?> getReminderByMemoryId(String memoryId) async {
    final rows = await customSelect(
      'SELECT * FROM reminders WHERE memory_id = ? LIMIT 1',
      variables: [Variable<String>(memoryId)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return ReminderRecord.fromRow(rows.first);
  }

  Future<void> deleteReminder(String id) {
    return customUpdate(
      'DELETE FROM reminders WHERE id = ?',
      variables: [Variable<String>(id)],
      updateKind: UpdateKind.delete,
    );
  }

  Future<void> deleteReminderByMemoryId(String memoryId) {
    return customUpdate(
      'DELETE FROM reminders WHERE memory_id = ?',
      variables: [Variable<String>(memoryId)],
      updateKind: UpdateKind.delete,
    );
  }

  Future<int> insertSession(SessionRecord session) {
    return customInsert(
      '''
      INSERT INTO sessions(
        id,
        started_at,
        ended_at,
        transcript_snippet,
        memory_count,
        duration_seconds
      )
      VALUES(?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable<String>(session.id),
        Variable<String>(session.startedAt.toUtc().toIso8601String()),
        Variable<String>(session.endedAt?.toUtc().toIso8601String()),
        Variable<String>(session.transcriptSnippet),
        Variable<int>(session.memoryCount),
        Variable<int>(session.durationSeconds),
      ],
    );
  }

  Future<void> updateSession(SessionRecord session) {
    return customUpdate(
      '''
      UPDATE sessions
      SET transcript_snippet = ?, memory_count = ?
      WHERE id = ?
      ''',
      variables: [
        Variable<String>(session.transcriptSnippet),
        Variable<int>(session.memoryCount),
        Variable<String>(session.id),
      ],
      updateKind: UpdateKind.update,
    );
  }

  Future<void> endSession(
    String sessionId,
    DateTime endedAt, {
    String? transcriptSnippet,
    required int memoryCount,
    required int durationSeconds,
  }) {
    return customUpdate(
      '''
      UPDATE sessions
      SET ended_at = ?, transcript_snippet = ?, memory_count = ?, duration_seconds = ?
      WHERE id = ?
      ''',
      variables: [
        Variable<String>(endedAt.toUtc().toIso8601String()),
        Variable<String>(transcriptSnippet),
        Variable<int>(memoryCount),
        Variable<int>(durationSeconds),
        Variable<String>(sessionId),
      ],
      updateKind: UpdateKind.update,
    );
  }

  Future<List<SessionRecord>> getAllSessions() async {
    final rows = await customSelect(
      'SELECT * FROM sessions ORDER BY started_at DESC',
    ).get();
    return rows.map(SessionRecord.fromRow).toList();
  }

  Future<SessionRecord?> getSessionById(String id) async {
    final rows = await customSelect(
      'SELECT * FROM sessions WHERE id = ? LIMIT 1',
      variables: [Variable<String>(id)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return SessionRecord.fromRow(rows.first);
  }

  Future<int> insertUser(UserRecord user) {
    return customInsert(
      '''
      INSERT INTO users(id, email, password, created_at)
      VALUES(?, ?, ?, ?)
      ''',
      variables: [
        Variable<String>(user.id),
        Variable<String>(user.email),
        Variable<String>(user.password),
        Variable<String>(user.createdAt.toUtc().toIso8601String()),
      ],
    );
  }

  Future<UserRecord?> getUserByEmail(String email) async {
    final rows = await customSelect(
      'SELECT * FROM users WHERE email = ? LIMIT 1',
      variables: [Variable<String>(email)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return UserRecord.fromRow(rows.first);
  }

  Future<UserRecord?> getUserById(String id) async {
    final rows = await customSelect(
      'SELECT * FROM users WHERE id = ? LIMIT 1',
      variables: [Variable<String>(id)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return UserRecord.fromRow(rows.first);
  }

  Future<bool> userExists(String email) async {
    final rows = await customSelect(
      'SELECT COUNT(*) as count FROM users WHERE email = ?',
      variables: [Variable<String>(email)],
    ).get();
    final count = rows.first.read<int>('count');
    return count > 0;
  }

  Future<void> _ensureColumnExists(
    String table,
    String column,
    String definition,
  ) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    final hasColumn = rows.any(
      (row) => row.read<String>('name').toLowerCase() == column.toLowerCase(),
    );
    if (!hasColumn) {
      await customStatement(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'omi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
