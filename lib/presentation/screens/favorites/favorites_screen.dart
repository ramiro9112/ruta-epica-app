import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/destinations_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/destination_card.dart';
import '../../widgets/shimmer_loading.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesNotifierProvider);
    final allDestinations = ref.watch(allDestinationsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(AppStrings.misFavoritos),
        automaticallyImplyLeading: false,
      ),
      body: allDestinations.when(
        loading: () => const DestinationGridShimmer(),
        error: (err, _) => Center(
          child: Text(
            AppStrings.errorGeneral,
            style: const TextStyle(color: AppColors.darkGray),
          ),
        ),
        data: (destinations) {
          final favDestinations = destinations
              .where((d) => favoriteIds.contains(d.id))
              .toList();

          if (favoriteIds.isEmpty || favDestinations.isEmpty) {
            return _EmptyFavoritesView(
              onExplore: () => context.go('/home/explore'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favDestinations.length,
            itemBuilder: (_, i) =>
                DestinationGridCard(destination: favDestinations[i]),
          );
        },
      ),
    );
  }
}

class _EmptyFavoritesView extends StatelessWidget {
  final VoidCallback onExplore;

  const _EmptyFavoritesView({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.deepBlue.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: AppColors.deepBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.sinFavoritos,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              AppStrings.sinFavoritosSubtitle,
              style: TextStyle(
                color: AppColors.darkGray,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onExplore,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepBlue,
                foregroundColor: AppColors.white,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                AppStrings.explorarDestinos,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
