import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/favorites_repository.dart';
import 'auth_provider.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

final favoritesProvider = FutureProvider<List<String>>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  final userId = authState.session?.user.id;
  if (userId == null) return [];
  return ref.watch(favoritesRepositoryProvider).getUserFavorites(userId);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final FavoritesRepository _repository;
  final Ref _ref;

  FavoritesNotifier(this._repository, this._ref) : super({}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final authState = await _ref.read(authStateProvider.future);
      final userId = authState.session?.user.id;
      if (userId == null) return;
      final ids = await _repository.getUserFavorites(userId);
      state = ids.toSet();
    } catch (_) {}
  }

  Future<void> toggle(String destinationId) async {
    try {
      final authState = await _ref.read(authStateProvider.future);
      final userId = authState.session?.user.id;
      if (userId == null) return;

      if (state.contains(destinationId)) {
        await _repository.removeFavorite(userId, destinationId);
        state = {...state}..remove(destinationId);
      } else {
        await _repository.addFavorite(userId, destinationId);
        state = {...state, destinationId};
      }
    } catch (_) {}
  }

  bool isFavorite(String destinationId) => state.contains(destinationId);

  Future<void> refresh() => _loadFavorites();
}

final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref.watch(favoritesRepositoryProvider), ref);
});
