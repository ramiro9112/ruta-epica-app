import '../services/supabase_service.dart';

class FavoritesRepository {
  final SupabaseService _service;

  FavoritesRepository({SupabaseService? service})
      : _service = service ?? SupabaseService.instance;

  Future<List<String>> getUserFavorites(String userId) async {
    final response = await _service.client
        .from('favorites')
        .select('destination_id')
        .eq('user_id', userId);
    return (response as List)
        .map((json) => (json as Map<String, dynamic>)['destination_id'] as String)
        .toList();
  }

  Future<void> addFavorite(String userId, String destinationId) async {
    await _service.client.from('favorites').upsert({
      'user_id': userId,
      'destination_id': destinationId,
    });
  }

  Future<void> removeFavorite(String userId, String destinationId) async {
    await _service.client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('destination_id', destinationId);
  }

  Future<bool> isFavorite(String userId, String destinationId) async {
    final response = await _service.client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('destination_id', destinationId)
        .maybeSingle();
    return response != null;
  }
}
