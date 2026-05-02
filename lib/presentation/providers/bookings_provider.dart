import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import 'auth_provider.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

final userBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  final userId = authState.session?.user.id;
  if (userId == null) return [];
  return ref.watch(bookingRepositoryProvider).getUserBookings(userId);
});

class BookingFormState {
  final int currentStep;
  final DateTime? travelDate;
  final int adults;
  final int children;
  final String fullName;
  final String phone;
  final String email;
  final String observations;
  final bool isLoading;
  final String? errorMessage;
  final BookingModel? completedBooking;

  const BookingFormState({
    this.currentStep = 0,
    this.travelDate,
    this.adults = 1,
    this.children = 0,
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.observations = '',
    this.isLoading = false,
    this.errorMessage,
    this.completedBooking,
  });

  BookingFormState copyWith({
    int? currentStep,
    DateTime? travelDate,
    int? adults,
    int? children,
    String? fullName,
    String? phone,
    String? email,
    String? observations,
    bool? isLoading,
    String? errorMessage,
    BookingModel? completedBooking,
    bool clearError = false,
  }) {
    return BookingFormState(
      currentStep: currentStep ?? this.currentStep,
      travelDate: travelDate ?? this.travelDate,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      observations: observations ?? this.observations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      completedBooking: completedBooking ?? this.completedBooking,
    );
  }

  bool get isStep1Valid => travelDate != null && adults >= 1;
  bool get isStep2Valid =>
      fullName.trim().isNotEmpty && phone.trim().isNotEmpty;
}

class BookingNotifier extends StateNotifier<BookingFormState> {
  final BookingRepository _repository;
  final Ref _ref;

  BookingNotifier(this._repository, this._ref) : super(const BookingFormState());

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setTravelDate(DateTime date) => state = state.copyWith(travelDate: date);
  void setAdults(int count) =>
      state = state.copyWith(adults: count.clamp(1, 20));
  void setChildren(int count) =>
      state = state.copyWith(children: count.clamp(0, 20));
  void setFullName(String value) => state = state.copyWith(fullName: value);
  void setPhone(String value) => state = state.copyWith(phone: value);
  void setEmail(String value) => state = state.copyWith(email: value);
  void setObservations(String value) =>
      state = state.copyWith(observations: value);

  Future<bool> submitBooking({
    required String destinationId,
    required String destinationName,
    required double pricePerPerson,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authState = await _ref.read(authStateProvider.future);
      final userId = authState.session?.user.id;
      if (userId == null) throw Exception('Usuario no autenticado.');

      final totalPeople = state.adults + state.children;
      final totalPrice = pricePerPerson * totalPeople;

      final booking = BookingModel(
        id: '',
        userId: userId,
        destinationId: destinationId,
        destinationName: destinationName,
        travelDate: state.travelDate!,
        adults: state.adults,
        children: state.children,
        fullName: state.fullName.trim(),
        phone: state.phone.trim(),
        email: state.email.trim().isEmpty ? null : state.email.trim(),
        observations:
            state.observations.trim().isEmpty ? null : state.observations.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
        totalPrice: totalPrice,
      );

      final created = await _repository.create(booking);
      state = state.copyWith(isLoading: false, completedBooking: created);
      _ref.invalidate(userBookingsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al crear la reserva. Intenta de nuevo.',
      );
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _repository.cancel(bookingId);
      _ref.invalidate(userBookingsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  void reset() {
    state = const BookingFormState();
  }
}

final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, BookingFormState>((ref) {
  return BookingNotifier(ref.watch(bookingRepositoryProvider), ref);
});
