import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final SupabaseService _service;

  AuthRepository({SupabaseService? service})
      : _service = service ?? SupabaseService.instance;

  Stream<AuthState> get authStateChanges => _service.authStateChanges;

  User? get currentUser => _service.currentUser;
  bool get isAuthenticated => _service.isAuthenticated;

  Future<UserProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _service.signIn(email: email, password: password);
    if (response.user == null) {
      throw Exception('Error al iniciar sesión. Verifica tus credenciales.');
    }
    final profile = await _service.getProfile(response.user!.id);
    if (profile != null) return profile;
    return UserProfileModel(
      id: response.user!.id,
      email: response.user!.email ?? email,
      createdAt: DateTime.now(),
    );
  }

  Future<UserProfileModel> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final response = await _service.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    if (response.user == null) {
      throw Exception('Error al crear la cuenta. Intenta de nuevo.');
    }
    return UserProfileModel(
      id: response.user!.id,
      email: response.user!.email ?? email,
      fullName: fullName,
      phone: phone,
      createdAt: DateTime.now(),
    );
  }

  Future<void> signOut() => _service.signOut();

  Future<void> resetPassword(String email) => _service.resetPassword(email);

  Future<UserProfileModel?> getProfile(String userId) =>
      _service.getProfile(userId);

  Future<UserProfileModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) {
    return _service.updateProfile(
      userId: userId,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }
}
