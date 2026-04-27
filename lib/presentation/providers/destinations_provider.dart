import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/destination_model.dart';
import '../../data/repositories/destination_repository.dart';

final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return DestinationRepository();
});

final featuredDestinationsProvider =
    FutureProvider<List<DestinationModel>>((ref) async {
  return ref.watch(destinationRepositoryProvider).getFeatured();
});

final allDestinationsProvider =
    FutureProvider.family<List<DestinationModel>, String?>((ref, category) async {
  return ref.watch(destinationRepositoryProvider).getAll(category: category);
});

final promotionsProvider =
    FutureProvider<List<DestinationModel>>((ref) async {
  return ref.watch(destinationRepositoryProvider).getPromotions();
});

final destinationDetailProvider =
    FutureProvider.family<DestinationModel, String>((ref, id) async {
  return ref.watch(destinationRepositoryProvider).getById(id);
});

// Search state
class SearchState {
  final String query;
  final List<DestinationModel> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<DestinationModel>? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final DestinationRepository _repository;

  SearchNotifier(this._repository) : super(const SearchState());

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true, clearError: true);
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }
    try {
      final results = await _repository.search(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al buscar destinos.',
      );
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(destinationRepositoryProvider));
});
