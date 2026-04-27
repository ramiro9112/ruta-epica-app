import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    if (response.user != null) {
      await _ensureProfileExists(response.user!);
    }
    return response;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    );
    // Only upsert profile when there is an active session.
    // When email confirmation is required, session is null — the DB trigger
    // creates the profile automatically upon confirmation.
    if (response.user != null && response.session != null) {
      try {
        await _upsertProfile(
          userId: response.user!.id,
          email: email.trim().toLowerCase(),
          fullName: fullName,
          phone: phone,
        );
      } catch (_) {
        // Profile creation via trigger will handle it on first sign-in.
      }
    }
    return response;
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  Future<UserProfileModel?> getProfile(String userId) async {
    final response =
        await client.from('profiles').select().eq('id', userId).maybeSingle();
    if (response == null) return null;
    return UserProfileModel.fromJson(response);
  }

  Future<UserProfileModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    final response = await client
        .from('profiles')
        .update(data)
        .eq('id', userId)
        .select()
        .single();
    return UserProfileModel.fromJson(response);
  }

  Future<String?> uploadAvatar(File file, String userId) async {
    final ext = file.path.split('.').last;
    final path = 'avatars/$userId.$ext';
    await client.storage.from('avatars').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return client.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> _ensureProfileExists(User user) async {
    final existing = await client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing == null) {
      await _upsertProfile(
        userId: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] as String?,
        phone: user.userMetadata?['phone'] as String?,
      );
    }
  }

  Future<void> _upsertProfile({
    required String userId,
    required String email,
    String? fullName,
    String? phone,
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'email': email,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
    });
  }
}
