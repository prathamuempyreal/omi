import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../../data/models/user_record.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

class AuthResult {
  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  final bool success;
  final String? errorMessage;
  final UserRecord? user;
}

class AuthService {
  final Ref _ref;
  final _uuid = const Uuid();

  AuthService(this._ref);

  String hashPassword(String password) {
    final bytes = password.codeUnits;
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AuthResult> signup(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const AuthResult(
        success: false,
        errorMessage: 'Email and password are required',
      );
    }

    if (!_isValidEmail(email)) {
      return const AuthResult(
        success: false,
        errorMessage: 'Please enter a valid email address',
      );
    }

    if (password.length < 6) {
      return const AuthResult(
        success: false,
        errorMessage: 'Password must be at least 6 characters',
      );
    }

    try {
      final database = _ref.read(appDatabaseProvider);
      
      final exists = await database.userExists(email.trim().toLowerCase());
      if (exists) {
        return const AuthResult(
          success: false,
          errorMessage: 'An account with this email already exists',
        );
      }

      final user = UserRecord(
        id: _uuid.v4(),
        email: email.trim().toLowerCase(),
        password: hashPassword(password),
        createdAt: DateTime.now(),
      );

      await database.insertUser(user);

      return AuthResult(
        success: true,
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Signup failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const AuthResult(
        success: false,
        errorMessage: 'Email and password are required',
      );
    }

    try {
      final database = _ref.read(appDatabaseProvider);
      
      final user = await database.getUserByEmail(email.trim().toLowerCase());
      if (user == null) {
        return const AuthResult(
          success: false,
          errorMessage: 'No account found with this email',
        );
      }

      final hashedInput = hashPassword(password);
      if (hashedInput != user.password) {
        return const AuthResult(
          success: false,
          errorMessage: 'Incorrect password',
        );
      }

      return AuthResult(
        success: true,
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}