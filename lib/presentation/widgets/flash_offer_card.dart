import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/destination_model.dart';

class FlashOfferCard extends StatelessWidget {
  final DestinationModel destination;
  final VoidCallback? onTap;

  const FlashOfferCard({
    super.key,
    required this.destination,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discountedPrice = destination.discountPercent != null
        ? destination.priceFrom *
            (1 - destination.discountPercent! / 100)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: destination.imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      height: 100,
                      color: AppColors.mediumGray,
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      height: 100,
                      color: AppColors.mediumGray,
                      child: const Icon(Icons.image_not_supported,
                          color: AppColors.darkGray),
                    ),
                  ),
                  if (destination.discountPercent != null)
                    Positioned(
                      top: 6,
                      left: 6,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (discountedPrice != null) ...[
                    Text(
                      destination.priceFrom.copFormatted,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.darkGray,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      discountedPrice.copFormatted,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ] else
                    Text(
                      destination.priceFrom.copFormatted,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepBlue,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: AppColors.darkGray),
                      const SizedBox(width: 3),
                      Text(
                        '${destination.durationDays} días',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
