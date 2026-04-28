import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/destination_model.dart';
import '../../data/models/promotion_model.dart';
import '../../data/repositories/destination_repository.dart';

final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  final repo = DestinationRepository();
  ref.onDispose(repo.invalidateCache);
  return repo;
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

final activeBannersProvider = FutureProvider<List<PromotionModel>>((ref) async {
  try {
    final now = DateTime.now().toIso8601String();
    final data = await Supabase.instance.client
        .from('banners')
        .select()
        .eq('is_active', true)
        .or('ends_at.is.null,ends_at.gte.$now')
        .order('display_order')
        .limit(10);
    return (data as List).map((b) => PromotionModel(
      id: b['id'] as String,
      title: b['title'] as String? ?? '',
      subtitle: b['subtitle'] as String? ?? '',
      imageUrl: b['image_url'] as String? ?? '',
      destinationId: b['destination_id'] as String?,
      discountPercent: null,
      validUntil: b['ends_at'] != null ? DateTime.tryParse(b['ends_at']) ?? DateTime.now().add(const Duration(days: 30)) : DateTime.now().add(const Duration(days: 30)),
      isActive: true,
    )).toList();
  } catch (_) {
    return [];
  }
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
  Timer? _debounce;

  SearchNotifier(this._repository) : super(const SearchState());

  void search(String query) {
    _debounce?.cancel();
    state = state.copyWith(query: query, clearError: true);
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true);
    _debounce = Timer(const Duration(milliseconds: 600), () => _execute(query));
  }

  Future<void> _execute(String query) async {
    try {
      final results = await _repository.search(query);
      if (mounted) state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Error al buscar destinos.',
        );
      }
    }
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(destinationRepositoryProvider));
});
