import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/destination_model.dart';
import '../../../data/models/promotion_model.dart';
import '../../providers/destinations_provider.dart';
import '../../widgets/destination_card.dart';
import '../../widgets/flash_offer_card.dart';
import '../../widgets/promo_carousel.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/testimonial_card.dart';
import '../../widgets/whatsapp_fab.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredDestinationsProvider);
    final promotionsAsync = ref.watch(promotionsProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final firstName = _getFirstName(user);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: CustomScrollView(
        slivers: [
          // SliverAppBar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.deepBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.deepBlue, AppColors.deepBlueLight],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.hola}, $firstName!',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              '¿A dónde viajas hoy?',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded,
                              color: AppColors.white, size: 26),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                color: AppColors.deepBlue,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: GestureDetector(
                  onTap: () => context.go('/home/search'),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: AppColors.darkGray, size: 20),
                        SizedBox(width: 10),
                        Text(
                          AppStrings.buscarDestinos,
                          style: TextStyle(
                            color: AppColors.darkGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              // Promo Carousel
              _buildCarousel(promotionsAsync),
              const SizedBox(height: 24),
              // Featured destinations
              _buildSectionHeader(
                context,
                AppStrings.destinosDestacados,
                onViewAll: () => context.push('/destinations'),
              ),
              const SizedBox(height: 12),
              _buildFeaturedScroll(featuredAsync, context),
              const SizedBox(height: 24),
              // Flash offers
              _buildSectionHeader(
                context,
                AppStrings.ofertasFlash,
                onViewAll: () =>
                    context.push('/destinations?category=promotion'),
              ),
              const SizedBox(height: 12),
              _buildFlashOffers(ref, context),
              const SizedBox(height: 24),
              // Popular packages
              _buildSectionHeader(
                context,
                AppStrings.paquetesPopulares,
                onViewAll: () => context.push('/destinations'),
              ),
              const SizedBox(height: 12),
              _buildPopularPackages(featuredAsync, context),
              const SizedBox(height: 24),
              // Testimonials
              _buildSectionHeader(
                context,
                AppStrings.testimonios,
              ),
              const SizedBox(height: 12),
              _buildTestimonials(),
              const SizedBox(height: 20),
              // Contact footer
              _buildContactFooter(context),
              const SizedBox(height: 80),
            ]),
          ),
        ],
      ),
      floatingActionButton: const WhatsAppFab(),
    );
  }

  String _getFirstName(dynamic user) {
    if (user == null) return 'Viajero';
    final meta = user.userMetadata;
    if (meta != null && meta['full_name'] != null) {
      final fullName = meta['full_name'] as String;
      return fullName.split(' ').first;
    }
    final email = user.email as String? ?? '';
    return email.split('@').first.capitalized;
  }

  Widget _buildCarousel(AsyncValue<List<DestinationModel>> promotionsAsync) {
    return promotionsAsync.when(
      loading: () => Container(
        height: 190,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.mediumGray,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      error: (_, __) => PromoCarousel(promotions: PromotionSamples.samples),
      data: (destinations) {
        final promos = destinations
            .map((d) => PromotionModel(
                  id: d.id,
                  title: d.name,
                  subtitle: 'Desde ${d.priceFrom.copFormatted} COP',
                  imageUrl: d.imageUrl,
                  destinationId: d.id,
                  discountPercent: d.discountPercent,
                  validUntil: DateTime.now().add(const Duration(days: 30)),
                  isActive: true,
                ))
            .toList();
        if (promos.isEmpty) {
          return PromoCarousel(promotions: PromotionSamples.samples);
        }
        return PromoCarousel(promotions: promos);
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                AppStrings.verTodos,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedScroll(
    AsyncValue<List<DestinationModel>> async,
    BuildContext context,
  ) {
    return SizedBox(
      height: 220,
      child: async.when(
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(right: 12),
            child: DestinationCardShimmer(),
          ),
        ),
        error: (_, __) => _buildFeaturedFromSamples(),
        data: (destinations) {
          if (destinations.isEmpty) return _buildFeaturedFromSamples();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: destinations.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DestinationCard(destination: destinations[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedFromSamples() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: DestinationSamples.samples.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: DestinationCard(destination: DestinationSamples.samples[i]),
      ),
    );
  }

  Widget _buildFlashOffers(WidgetRef ref, BuildContext context) {
    final promotionsAsync = ref.watch(promotionsProvider);
    return SizedBox(
      height: 190,
      child: promotionsAsync.when(
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child:
                ShimmerBox(width: 160, height: 190, borderRadius: 14),
          ),
        ),
        error: (_, __) => _buildFlashFromSamples(context),
        data: (destinations) {
          if (destinations.isEmpty) return _buildFlashFromSamples(context);
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: destinations.length,
            itemBuilder: (_, i) => FlashOfferCard(
              destination: destinations[i],
              onTap: () =>
                  context.push('/destination/${destinations[i].id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlashFromSamples(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: DestinationSamples.samples.length,
      itemBuilder: (_, i) => FlashOfferCard(
        destination: DestinationSamples.samples[i],
        onTap: () => context
            .push('/destination/${DestinationSamples.samples[i].id}'),
      ),
    );
  }

  Widget _buildPopularPackages(
    AsyncValue<List<DestinationModel>> async,
    BuildContext context,
  ) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [ListTileShimmer(), ListTileShimmer()],
        ),
      ),
      error: (_, __) => _buildPackagesFromSamples(context),
      data: (destinations) {
        if (destinations.isEmpty) return _buildPackagesFromSamples(context);
        final limited = destinations.take(4).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: limited
                .map((d) => _PackageListTile(destination: d))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildPackagesFromSamples(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: DestinationSamples.samples
            .map((d) => _PackageListTile(destination: d))
            .toList(),
      ),
    );
  }

  Widget _buildTestimonials() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: TestimonialData.testimonials.length,
        itemBuilder: (_, i) {
          final t = TestimonialData.testimonials[i];
          return TestimonialCard(
            name: t['name'] as String,
            city: t['city'] as String,
            quote: t['quote'] as String,
            rating: t['rating'] as int,
          );
        },
      ),
    );
  }

  Widget _buildContactFooter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepBlue, AppColors.deepBlueLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Necesitas ayuda para planear tu viaje?',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nuestros asesores están listos para ayudarte a encontrar el viaje perfecto.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                        'https://wa.me/573052394904?text=${Uri.encodeComponent('Hola! Quiero información sobre un viaje')}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsApp,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const Text('Llamar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackageListTile extends StatelessWidget {
  final DestinationModel destination;

  const _PackageListTile({required this.destination});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/destination/${destination.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Hero(
                tag: 'pkg_${destination.id}',
                child: Image.network(
                  destination.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: AppColors.mediumGray,
                    child: const Icon(Icons.image_not_supported,
                        color: AppColors.darkGray),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    destination.country,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.darkGray),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.gold, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        destination.rating.ratingFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.darkGray),
                      const SizedBox(width: 3),
                      Text(
                        '${destination.durationDays} días',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.darkGray),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  destination.priceFrom.copFormatted,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepBlue,
                  ),
                ),
                const Text(
                  'p/persona',
                  style: TextStyle(fontSize: 10, color: AppColors.darkGray),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.darkGray, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
