import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state stream provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Current user profile provider
final userProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  final user = authState.session?.user;
  if (user == null) return null;
  return ref.read(authRepositoryProvider).getProfile(user.id);
});

// Auth notifier state
class AppAuthState {
  final bool isLoading;
  final String? errorMessage;
  final UserProfileModel? user;

  const AppAuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AppAuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserProfileModel? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AppAuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AppAuthState());

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signOut();
      state = const AppAuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _parseError(Object e) {
    final message = e.toString();
    if (message.contains('Invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'Correo o contraseña incorrectos.';
    } else if (message.contains('Email not confirmed')) {
      return 'Por favor confirma tu correo electrónico.';
    } else if (message.contains('User already registered')) {
      return 'Este correo ya está registrado. Inicia sesión.';
    } else if (message.contains('network') || message.contains('connection')) {
      return 'Error de conexión. Verifica tu internet.';
    }
    return 'Algo salió mal. Intenta de nuevo.';
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
