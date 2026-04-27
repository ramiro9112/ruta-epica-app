import '../services/supabase_service.dart';
import 'destination_repository.dart';

class FavoritesRepository {
  final SupabaseService _service;

  FavoritesRepository({SupabaseService? service})
      : _service = service ?? SupabaseService.instance;

  String get _currentUserId {
    final uid = _service.currentUser?.id;
    if (uid == null) throw const RepositoryException('Usuario no autenticado.');
    return uid;
  }

  Future<List<String>> getUserFavorites(String userId) async {
    if (_service.currentUser?.id != userId) {
      throw const RepositoryException('Acceso no autorizado.');
    }
    try {
      final response = await _service.client
          .from('favorites')
          .select('destination_id')
          .eq('user_id', _currentUserId);
      return response
          .map((json) => json['destination_id'] as String)
          .toList();
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw const RepositoryException('No se pudieron cargar los favoritos.');
    }
  }

  Future<void> addFavorite(String userId, String destinationId) async {
    if (_service.currentUser?.id != userId) {
      throw const RepositoryException('Acceso no autorizado.');
    }
    try {
      await _service.client.from('favorites').upsert({
        'user_id': _currentUserId,
        'destination_id': destinationId,
      });
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw const RepositoryException('No se pudo agregar a favoritos.');
    }
  }

  Future<void> removeFavorite(String userId, String destinationId) async {
    if (_service.currentUser?.id != userId) {
      throw const RepositoryException('Acceso no autorizado.');
    }
    try {
      await _service.client
          .from('favorites')
          .delete()
          .eq('user_id', _currentUserId)
          .eq('destination_id', destinationId);
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw const RepositoryException('No se pudo quitar de favoritos.');
    }
  }

  Future<bool> isFavorite(String userId, String destinationId) async {
    if (_service.currentUser?.id != userId) return false;
    try {
      final response = await _service.client
          .from('favorites')
          .select('id')
          .eq('user_id', _currentUserId)
          .eq('destination_id', destinationId)
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }
}
