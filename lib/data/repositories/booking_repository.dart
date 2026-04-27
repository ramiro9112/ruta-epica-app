import '../models/booking_model.dart';
import '../services/supabase_service.dart';

class BookingRepository {
  final SupabaseService _service;

  BookingRepository({SupabaseService? service})
      : _service = service ?? SupabaseService.instance;

  Future<BookingModel> create(BookingModel booking) async {
    final response = await _service.client
        .from('bookings')
        .insert(booking.toInsertJson())
        .select()
        .single();
    return BookingModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    final response = await _service.client
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> getById(String id) async {
    final response = await _service.client
        .from('bookings')
        .select()
        .eq('id', id)
        .single();
    return BookingModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> cancel(String id) async {
    await _service.client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }
}
