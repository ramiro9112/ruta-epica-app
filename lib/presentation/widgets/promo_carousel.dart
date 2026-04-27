import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/promotion_model.dart';

class PromoCarousel extends StatefulWidget {
  final List<PromotionModel> promotions;
  final void Function(PromotionModel)? onTap;

  const PromoCarousel({
    super.key,
    required this.promotions,
    this.onTap,
  });

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.promotions.isEmpty) {
      return _buildFallback();
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.promotions.length,
          options: CarouselOptions(
            height: 190,
            viewportFraction: 0.92,
            enlargeCenterPage: true,
            enlargeFactor: 0.12,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 600),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final promo = widget.promotions[index];
            return GestureDetector(
              onTap: () => widget.onTap?.call(promo),
              child: _PromoCard(promo: promo),
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: widget.promotions.length,
          effect: const WormEffect(
            dotWidth: 8,
            dotHeight: 8,
            activeDotColor: AppColors.gold,
            dotColor: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildFallback() {
    return _PromoCard(
      promo: PromotionModel(
        id: 'fallback',
        title: 'Descubre el Mundo con Ruta Épica',
        subtitle: 'Destinos increíbles te esperan',
        imageUrl:
            'https://images.unsplash.com/photo-1503220317375-aaad61436b1b?w=800',
        validUntil: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromotionModel promo;

  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: promo.imageUrl,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(color: AppColors.mediumGray),
            errorWidget: (ctx, url, err) => Container(
              color: AppColors.deepBlue,
              child: const Icon(Icons.image, color: AppColors.white, size: 40),
            ),
          ),
          // Gradient overlay
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.transparent,
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          // Text content
          Positioned(
            left: 16,
            right: 80,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (promo.hasDiscount)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${promo.discountPercent!.toInt()}% DESCUENTO',
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Text(
                  promo.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  promo.subtitle,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
