import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final void Function(String) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<_CategoryItem> _categories = [
    _CategoryItem(key: 'all', label: AppStrings.todos, icon: Icons.explore_rounded),
    _CategoryItem(key: 'beach', label: AppStrings.playas, icon: Icons.beach_access_rounded),
    _CategoryItem(key: 'city', label: AppStrings.ciudades, icon: Icons.location_city_rounded),
    _CategoryItem(key: 'adventure', label: AppStrings.aventura, icon: Icons.hiking_rounded),
    _CategoryItem(key: 'cultural', label: AppStrings.cultural, icon: Icons.museum_rounded),
    _CategoryItem(key: 'international', label: AppStrings.internacional, icon: Icons.flight_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = selectedCategory == category.key;
          return _CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected(category.key),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final _CategoryItem category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepBlue : AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.deepBlue : AppColors.mediumGray,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.deepBlue.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 14,
              color: isSelected ? AppColors.white : AppColors.darkGray,
            ),
            const SizedBox(width: 5),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String key;
  final String label;
  final IconData icon;

  const _CategoryItem({
    required this.key,
    required this.label,
    required this.icon,
  });
}
