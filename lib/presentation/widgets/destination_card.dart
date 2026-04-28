import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/destination_model.dart';
import '../providers/favorites_provider.dart';
import '../screens/profile/profile_screen.dart' show showAuthRequiredDialog;
import 'shimmer_loading.dart';

class DestinationCard extends ConsumerWidget {
  final DestinationModel destination;
  final double width;
  final double height;
  final bool showFavorite;

  const DestinationCard({
    super.key,
    required this.destination,
    this.width = 180,
    this.height = 220,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesNotifierProvider);
    final isFav = favorites.contains(destination.id);

    return GestureDetector(
      onTap: () => context.push('/destination/${destination.id}'),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero image
              Hero(
                tag: 'destination_${destination.id}',
                child: CachedNetworkImage(
                  imageUrl: destination.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 16,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.mediumGray,
                    child: const Icon(Icons.image_not_supported,
                        color: AppColors.darkGray, size: 40),
                  ),
                ),
              ),
              // Gradient overlay
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xDD000000),
                    ],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              // Price badge top-left
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    destination.priceFrom.copFormatted,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Favorite button
              if (showFavorite)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      final isGuest =
                          Supabase.instance.client.auth.currentUser == null;
                      if (isGuest) {
                        showAuthRequiredDialog(context,
                            reason:
                                'Inicia sesión para guardar destinos favoritos.');
                        return;
                      }
                      ref
                          .read(favoritesNotifierProvider.notifier)
                          .toggle(destination.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? Colors.red : AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              // Bottom info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destination.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        destination.country,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.gold, size: 13),
                          const SizedBox(width: 2),
                          Text(
                            destination.rating.ratingFormatted,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${destination.reviewCount.compactFormatted})',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Grid version of destination card
class DestinationGridCard extends ConsumerWidget {
  final DestinationModel destination;

  const DestinationGridCard({super.key, required this.destination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesNotifierProvider);
    final isFav = favorites.contains(destination.id);

    return GestureDetector(
      onTap: () => context.push('/destination/${destination.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'destination_${destination.id}',
                      child: CachedNetworkImage(
                        imageUrl: destination.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => const ShimmerBox(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 0),
                        errorWidget: (ctx, url, err) => Container(
                          color: AppColors.mediumGray,
                          child: const Icon(Icons.image_not_supported,
                              color: AppColors.darkGray),
                        ),
                      ),
                    ),
                    if (destination.isPromotion && destination.discountPercent != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${destination.discountPercent!.toInt()}%',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () {
                          final isGuest =
                              Supabase.instance.client.auth.currentUser == null;
                          if (isGuest) {
                            showAuthRequiredDialog(context,
                                reason:
                                    'Inicia sesión para guardar destinos favoritos.');
                            return;
                          }
                          ref
                              .read(favoritesNotifierProvider.notifier)
                              .toggle(destination.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav ? Colors.red : AppColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination.country,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.darkGray),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            destination.priceFrom.copFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.gold, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              destination.rating.ratingFormatted,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
