import '../models/booking_model.dart';
import '../services/supabase_service.dart';
import 'destination_repository.dart';

class BookingRepository {
  final SupabaseService _service;

  BookingRepository({SupabaseService? service})
      : _service = service ?? SupabaseService.instance;

  String get _currentUserId {
    final uid = _service.currentUser?.id;
    if (uid == null) throw const RepositoryException('Usuario no autenticado.');
    return uid;
  }

  Future<BookingModel> create(BookingModel booking) async {
    final uid = _currentUserId;
    try {
      final response = await _service.client
          .from('bookings')
          .insert({...booking.toInsertJson(), 'user_id': uid})
          .select()
          .single();
      return BookingModel.fromJson(response);
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw const RepositoryException('No se pudo crear la reserva.');
    }
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    if (_service.currentUser?.id != userId) {
      throw const RepositoryException('Acceso no autorizado.');
    }
    try {
      final response = await _service.client
          .from('bookings')
          .select()
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false);
      return response
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw const RepositoryException('No se pudieron cargar las reservas.');
    }
  }

  Future<BookingModel> getById(String id) async {
    try {
      final response = await _service.client
          .from('bookings')
          .select()
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .single();
      return BookingModel.fromJson(response);
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw const RepositoryException('No se encontró la reserva.');
    }
  }

  Future<void> cancel(String id) async {
    try {
      await _service.client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw const RepositoryException('No se pudo cancelar la reserva.');
    }
  }
}
