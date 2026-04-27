import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/destination_model.dart';
import '../../providers/destinations_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/shimmer_loading.dart';

class DestinationDetailScreen extends ConsumerWidget {
  final String destinationId;

  const DestinationDetailScreen({super.key, required this.destinationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationAsync =
        ref.watch(destinationDetailProvider(destinationId));

    return destinationAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.lightGray,
        body: const _DetailShimmer(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Destino')),
        body: const Center(
          child: Text(AppStrings.errorGeneral),
        ),
      ),
      data: (destination) => _DetailView(destination: destination),
    );
  }
}

class _DetailView extends ConsumerWidget {
  final DestinationModel destination;

  const _DetailView({required this.destination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesNotifierProvider);
    final isFav = favorites.contains(destination.id);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: CustomScrollView(
        slivers: [
          // Parallax hero appbar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.deepBlue,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white, size: 18),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? Colors.red : AppColors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => ref
                    .read(favoritesNotifierProvider.notifier)
                    .toggle(destination.id),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded,
                      color: AppColors.white, size: 20),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'destination_${destination.id}',
                child: CachedNetworkImage(
                  imageUrl: destination.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) =>
                      Container(color: AppColors.mediumGray),
                  errorWidget: (ctx, url, err) => Container(
                    color: AppColors.mediumGray,
                    child: const Icon(Icons.image_not_supported,
                        color: AppColors.darkGray, size: 40),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and country row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 14, color: AppColors.darkGray),
                                  const SizedBox(width: 3),
                                  Text(
                                    destination.country,
                                    style: const TextStyle(
                                      color: AppColors.darkGray,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Duration badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.deepBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${destination.durationDays}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.deepBlue,
                                ),
                              ),
                              const Text(
                                'días',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.deepBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Rating row
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < destination.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          destination.rating.ratingFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${destination.reviewCount} reseñas)',
                          style: const TextStyle(
                            color: AppColors.darkGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Price section
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.desde,
                            style: TextStyle(
                              color: AppColors.darkGray,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            destination.priceFrom.copFormatted,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepBlue,
                            ),
                          ),
                          const Text(
                            AppStrings.porPersona,
                            style: TextStyle(
                              color: AppColors.darkGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (destination.isPromotion &&
                        destination.discountPercent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '-${destination.discountPercent!.toInt()}% OFERTA',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Includes section
              if (destination.includes.isNotEmpty)
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.incluye,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: destination.includes
                            .map((item) => _IncludeChip(item: item))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Description
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.descripcion,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      destination.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkText,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              // Gallery
              if (destination.gallery.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.galeria,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: destination.gallery.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: destination.gallery[i],
                                width: 120,
                                height: 90,
                                fit: BoxFit.cover,
                                errorWidget: (ctx, url, err) => Container(
                                  width: 120,
                                  height: 90,
                                  color: AppColors.mediumGray,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () =>
                context.push('/booking/${destination.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.darkText,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              AppStrings.reservarAhora,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncludeChip extends StatelessWidget {
  final String item;

  const _IncludeChip({required this.item});

  IconData _getIcon(String item) {
    final lower = item.toLowerCase();
    if (lower.contains('aéreo') || lower.contains('vuelo') || lower.contains('tiquete')) {
      return Icons.flight_rounded;
    } else if (lower.contains('hotel') || lower.contains('hospedaje')) {
      return Icons.hotel_rounded;
    } else if (lower.contains('traslado') || lower.contains('transporte')) {
      return Icons.directions_bus_rounded;
    } else if (lower.contains('seguro')) {
      return Icons.health_and_safety_rounded;
    } else if (lower.contains('tour') || lower.contains('city')) {
      return Icons.tour_rounded;
    } else if (lower.contains('comida') || lower.contains('incluido')) {
      return Icons.restaurant_rounded;
    }
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.turquoise.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(item), size: 13, color: AppColors.turquoiseDark),
          const SizedBox(width: 5),
          Text(
            item,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.turquoiseDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ShimmerBox(
            width: double.infinity, height: 300, borderRadius: 0),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: 220, height: 28, borderRadius: 6),
              const SizedBox(height: 8),
              const ShimmerBox(width: 140, height: 16, borderRadius: 4),
              const SizedBox(height: 20),
              const ShimmerBox(width: 180, height: 40, borderRadius: 8),
              const SizedBox(height: 20),
              ...List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ShimmerBox(
                      width: double.infinity, height: 14, borderRadius: 4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
