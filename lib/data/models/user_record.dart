import 'package:drift/drift.dart';

class UserRecord {
  const UserRecord({
    required this.id,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String password;
  final DateTime createdAt;

  factory UserRecord.fromRow(QueryRow row) {
    return UserRecord(
      id: row.read<String>('id'),
      email: row.read<String>('email'),
      password: row.read<String>('password'),
      createdAt: DateTime.parse(row.read<String>('created_at')).toLocal(),
    );
  }

  UserRecord copyWith({
    String? id,
    String? email,
    String? password,
    DateTime? createdAt,
  }) {
    return UserRecord(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}