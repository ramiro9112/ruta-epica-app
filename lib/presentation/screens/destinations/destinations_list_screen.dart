import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/destinations_provider.dart';
import '../../widgets/category_filter.dart';
import '../../widgets/destination_card.dart';
import '../../widgets/shimmer_loading.dart';

class DestinationsListScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const DestinationsListScreen({super.key, this.initialCategory});

  @override
  ConsumerState<DestinationsListScreen> createState() =>
      _DestinationsListScreenState();
}

class _DestinationsListScreenState
    extends ConsumerState<DestinationsListScreen> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    final categoryKey =
        _selectedCategory == 'all' ? null : _selectedCategory;
    final destinationsAsync = ref.watch(allDestinationsProvider(categoryKey));

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(AppStrings.destinos),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          CategoryFilter(
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) {
              setState(() => _selectedCategory = cat);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: destinationsAsync.when(
              loading: () => const DestinationGridShimmer(),
              error: (_, __) => const Center(
                child: Text(
                  AppStrings.errorGeneral,
                  style: TextStyle(color: AppColors.darkGray),
                ),
              ),
              data: (destinations) {
                if (destinations.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_off_rounded,
                            size: 64, color: AppColors.mediumGray),
                        SizedBox(height: 16),
                        Text(
                          'No hay destinos en esta categoría',
                          style: TextStyle(
                            color: AppColors.darkGray,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: destinations.length,
                  itemBuilder: (_, i) =>
                      DestinationGridCard(destination: destinations[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
