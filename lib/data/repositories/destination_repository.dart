import '../models/destination_model.dart';
import '../services/supabase_service.dart';

class DestinationRepository {
  final SupabaseService _service;

  // Simple in-memory cache with TTL
  final Map<String, _CacheEntry<dynamic>> _cache = {};
  static const _ttl = Duration(minutes: 5);

  DestinationRepository({SupabaseService? service})
      : _service = service ?? SupabaseService.instance;

  T? _fromCache<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > _ttl) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void _toCache(String key, dynamic data) {
    _cache[key] = _CacheEntry(data, DateTime.now());
  }

  Future<List<DestinationModel>> getFeatured() async {
    const key = 'featured';
    final cached = _fromCache<List<DestinationModel>>(key);
    if (cached != null) return cached;
    try {
      final response = await _service.client
          .from('destinations')
          .select()
          .eq('is_featured', true)
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(10);
      final result = response
          .map((json) => DestinationModel.fromJson(json))
          .toList();
      _toCache(key, result);
      return result;
    } catch (e) {
      throw RepositoryException('No se pudieron cargar los destinos destacados.');
    }
  }

  Future<List<DestinationModel>> getAll({String? category}) async {
    final normalizedCategory = category?.trim().toLowerCase();
    final key = 'all_$normalizedCategory';
    final cached = _fromCache<List<DestinationModel>>(key);
    if (cached != null) return cached;
    try {
      var query = _service.client
          .from('destinations')
          .select()
          .eq('is_active', true);

      if (normalizedCategory != null &&
          normalizedCategory.isNotEmpty &&
          normalizedCategory != 'all') {
        query = query.eq('category', normalizedCategory);
      }

      final response = await query
          .order('is_featured', ascending: false)
          .order('rating', ascending: false);
      final result = response
          .map((json) => DestinationModel.fromJson(json))
          .toList();
      _toCache(key, result);
      return result;
    } catch (e) {
      throw RepositoryException('No se pudieron cargar los destinos.');
    }
  }

  Future<List<DestinationModel>> getPromotions() async {
    const key = 'promotions';
    final cached = _fromCache<List<DestinationModel>>(key);
    if (cached != null) return cached;
    try {
      final response = await _service.client
          .from('destinations')
          .select()
          .eq('is_promotion', true)
          .eq('is_active', true)
          .order('discount_percent', ascending: false)
          .limit(10);
      final result = response
          .map((json) => DestinationModel.fromJson(json))
          .toList();
      _toCache(key, result);
      return result;
    } catch (e) {
      throw RepositoryException('No se pudieron cargar las promociones.');
    }
  }

  Future<DestinationModel> getById(String id) async {
    final key = 'detail_$id';
    final cached = _fromCache<DestinationModel>(key);
    if (cached != null) return cached;
    try {
      final response = await _service.client
          .from('destinations')
          .select()
          .eq('id', id)
          .single();
      final result = DestinationModel.fromJson(response);
      _toCache(key, result);
      return result;
    } catch (e) {
      throw RepositoryException('No se pudo cargar el destino.');
    }
  }

  Future<List<DestinationModel>> search(String query) async {
    final sanitized = query.trim().replaceAll(RegExp(r"[%_\\']"), '');
    if (sanitized.isEmpty) return [];
    try {
      final response = await _service.client
          .from('destinations')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$sanitized%,country.ilike.%$sanitized%')
          .order('rating', ascending: false)
          .limit(20);
      return response
          .map((json) => DestinationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw RepositoryException('Error al buscar destinos.');
    }
  }

  void invalidateCache() => _cache.clear();
}

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  _CacheEntry(this.data, this.timestamp);
}

class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);
  @override
  String toString() => message;
}
