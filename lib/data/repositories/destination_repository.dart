import '../models/destination_model.dart';
import '../services/supabase_service.dart';

class DestinationRepository {
  final SupabaseService _service;

  DestinationRepository({SupabaseService? service})
      : _service = service ?? SupabaseService.instance;

  Future<List<DestinationModel>> getFeatured() async {
    final response = await _service.client
        .from('destinations')
        .select()
        .eq('is_featured', true)
        .eq('is_active', true)
        .order('rating', ascending: false)
        .limit(10);
    return (response as List)
        .map((json) => DestinationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<DestinationModel>> getAll({String? category}) async {
    var query = _service.client
        .from('destinations')
        .select()
        .eq('is_active', true);

    if (category != null && category.isNotEmpty && category != 'all') {
      query = query.eq('category', category);
    }

    final response =
        await query.order('is_featured', ascending: false).order('rating', ascending: false);

    return (response as List)
        .map((json) => DestinationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<DestinationModel>> getPromotions() async {
    final response = await _service.client
        .from('destinations')
        .select()
        .eq('is_promotion', true)
        .eq('is_active', true)
        .order('discount_percent', ascending: false)
        .limit(10);
    return (response as List)
        .map((json) => DestinationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DestinationModel> getById(String id) async {
    final response = await _service.client
        .from('destinations')
        .select()
        .eq('id', id)
        .single();
    return DestinationModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<DestinationModel>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _service.client
        .from('destinations')
        .select()
        .eq('is_active', true)
        .or('name.ilike.%$query%,country.ilike.%$query%,description.ilike.%$query%')
        .order('rating', ascending: false)
        .limit(20);
    return (response as List)
        .map((json) => DestinationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
