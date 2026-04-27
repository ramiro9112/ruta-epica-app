import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.mediumGray,
      highlightColor: AppColors.lightGray,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.mediumGray,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DestinationCardShimmer extends StatelessWidget {
  const DestinationCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.mediumGray,
      highlightColor: AppColors.lightGray,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              decoration: const BoxDecoration(
                color: AppColors.mediumGray,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 80,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    color: AppColors.mediumGray,
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

class DestinationGridShimmer extends StatelessWidget {
  const DestinationGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _GridCardShimmer(),
    );
  }
}

class _GridCardShimmer extends StatelessWidget {
  const _GridCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.mediumGray,
      highlightColor: AppColors.lightGray,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.mediumGray,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 13, width: 100, color: AppColors.mediumGray),
                  const SizedBox(height: 5),
                  Container(height: 11, width: 70, color: AppColors.mediumGray),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 90, color: AppColors.mediumGray),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListTileShimmer extends StatelessWidget {
  const ListTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.mediumGray,
      highlightColor: AppColors.lightGray,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.mediumGray,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, color: AppColors.mediumGray),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 150, color: AppColors.mediumGray),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 100, color: AppColors.mediumGray),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
