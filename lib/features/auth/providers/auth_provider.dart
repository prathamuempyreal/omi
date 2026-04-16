import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/app_database.dart';
import '../../../data/models/user_record.dart';
import '../../settings/providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/session_helper.dart';

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  const AuthState({
    this.isLoading,
    this.isAuthenticated,
    this.currentUser,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(
    isLoading: true,
    isAuthenticated: false,
  );

  final bool? isLoading;
  final bool? isAuthenticated;
  final UserRecord? currentUser;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserRecord? currentUser,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkExistingSession();
    return AuthState.initial();
  }

  Future<void> _checkExistingSession() async {
    try {
      final sessionHelper = ref.read(sessionHelperProvider);
      final isLoggedIn = await sessionHelper.isLoggedIn();

      if (isLoggedIn) {
        final userId = await sessionHelper.getLoggedUserId();
        if (userId != null) {
          final database = ref.read(appDatabaseProvider);
          final user = await database.getUserById(userId);
          
          if (user != null) {
            state = state.copyWith(
              isLoading: false,
              isAuthenticated: true,
              currentUser: user,
            );
            return;
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  Future<bool> signup(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final authService = ref.read(authServiceProvider);
    final result = await authService.signup(email, password);

    if (result.success && result.user != null) {
      final sessionHelper = ref.read(sessionHelperProvider);
      await sessionHelper.saveLogin(result.user!.id, result.user!.email);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: result.user,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: result.errorMessage,
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final authService = ref.read(authServiceProvider);
    final result = await authService.login(email, password);

    if (result.success && result.user != null) {
      final sessionHelper = ref.read(sessionHelperProvider);
      await sessionHelper.saveLogin(result.user!.id, result.user!.email);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: result.user,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: result.errorMessage,
      );
      return false;
    }
  }

  Future<void> logout() async {
    final sessionHelper = ref.read(sessionHelperProvider);
    await sessionHelper.logout();

    state = const AuthState(
      isLoading: false,
      isAuthenticated: false,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}