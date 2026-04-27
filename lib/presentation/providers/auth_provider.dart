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
  final bool pendingEmailConfirmation;

  const AppAuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.pendingEmailConfirmation = false,
  });

  AppAuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserProfileModel? user,
    bool? pendingEmailConfirmation,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AppAuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: clearUser ? null : (user ?? this.user),
      pendingEmailConfirmation:
          pendingEmailConfirmation ?? this.pendingEmailConfirmation,
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
      // If user created but no active session → email confirmation pending
      final needsConfirmation =
          Supabase.instance.client.auth.currentSession == null;
      state = state.copyWith(
        isLoading: false,
        user: user,
        pendingEmailConfirmation: needsConfirmation,
      );
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
    // Rate limiting
    if (message.contains('over_email_send_rate_limit') ||
        message.contains('rate limit') ||
        message.contains('429')) {
      return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
    }
    // Credentials
    if (message.contains('Invalid login credentials') ||
        message.contains('invalid_credentials') ||
        message.contains('Invalid email') ||
        message.contains('Invalid password')) {
      return 'Correo o contraseña incorrectos.';
    }
    // Email confirmation
    if (message.contains('Email not confirmed') ||
        message.contains('email_not_confirmed')) {
      return 'Revisa tu correo y confirma tu cuenta antes de ingresar.';
    }
    // Duplicate account
    if (message.contains('User already registered') ||
        message.contains('already_registered') ||
        message.contains('email_exists')) {
      return 'Este correo ya está registrado. Inicia sesión.';
    }
    // Redirect URL not allowed (misconfigured dashboard)
    if (message.contains('Redirect URL not allowed') ||
        message.contains('redirect')) {
      return 'Error de configuración. Contacta al soporte.';
    }
    // Network
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('SocketException') ||
        message.contains('TimeoutException')) {
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    }
    // Weak password
    if (message.contains('Password should be') ||
        message.contains('weak_password')) {
      return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
    }
    return 'Error: $message';
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
