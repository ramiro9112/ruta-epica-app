import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/destinations_provider.dart';
import '../../widgets/destination_card.dart';
import '../../widgets/shimmer_loading.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  int _currentTab = 0;

  static const List<String> _tabs = [
    AppStrings.paquetes,
    AppStrings.vuelos,
    AppStrings.hoteles,
    AppStrings.autos,
    AppStrings.actividades,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        setState(() => _currentTab = _tabController.index);
      });
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final recents = prefs.getStringList('recent_searches') ?? [];
    if (mounted) setState(() => _recentSearches = recents.take(5).toList());
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final recents = prefs.getStringList('recent_searches') ?? [];
    recents.remove(query);
    recents.insert(0, query);
    await prefs.setStringList('recent_searches', recents.take(5).toList());
    if (mounted) setState(() => _recentSearches = recents.take(5).toList());
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    _saveSearch(query.trim());
    ref.read(searchNotifierProvider.notifier).search(query.trim());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          autofocus: _currentTab == 0,
          onChanged: (v) {
            if (v.isEmpty) {
              ref.read(searchNotifierProvider.notifier).clear();
            }
          },
          onSubmitted: _performSearch,
          style: const TextStyle(color: AppColors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: AppStrings.buscarPaquetes,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded,
                color: Colors.white70, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: Colors.white70, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchNotifierProvider.notifier).clear();
                    },
                  )
                : null,
            filled: false,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PackagesTab(
            onSearch: _performSearch,
            recentSearches: _recentSearches,
            searchController: _searchController,
          ),
          const _ComingSoonTab(icon: Icons.flight_rounded, label: AppStrings.vuelos),
          const _ComingSoonTab(icon: Icons.hotel_rounded, label: AppStrings.hoteles),
          const _ComingSoonTab(icon: Icons.directions_car_rounded, label: AppStrings.autos),
          const _ComingSoonTab(icon: Icons.kayaking_rounded, label: AppStrings.actividades),
        ],
      ),
    );
  }
}

class _PackagesTab extends ConsumerWidget {
  final void Function(String) onSearch;
  final List<String> recentSearches;
  final TextEditingController searchController;

  const _PackagesTab({
    required this.onSearch,
    required this.recentSearches,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);

    if (searchState.query.isNotEmpty) {
      // Show results
      if (searchState.isLoading) {
        return const DestinationGridShimmer();
      }
      if (searchState.results.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 64, color: AppColors.mediumGray),
              const SizedBox(height: 16),
              const Text(
                AppStrings.sinResultados,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.sinResultadosSubtitle,
                style: const TextStyle(
                  color: AppColors.darkGray,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
        itemCount: searchState.results.length,
        itemBuilder: (_, i) =>
            DestinationGridCard(destination: searchState.results[i]),
      );
    }

    // Show recent searches + popular
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            const Text(
              AppStrings.busquedasRecientes,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSearches
                  .map((s) => GestureDetector(
                        onTap: () {
                          searchController.text = s;
                          onSearch(s);
                        },
                        child: Chip(
                          avatar: const Icon(Icons.history_rounded,
                              size: 14, color: AppColors.darkGray),
                          label: Text(s,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppColors.white,
                          side: const BorderSide(color: AppColors.mediumGray),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            AppStrings.destinosPopulares,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _SearchScreen._popularDestinations
                .map((dest) => GestureDetector(
                      onTap: () {
                        searchController.text = dest;
                        onSearch(dest);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.deepBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.deepBlue.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          dest,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.deepBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// Namespace to hold popular destinations constant for use in _PackagesTab
class _SearchScreen {
  static const List<String> _popularDestinations = [
    'San Andrés',
    'Cartagena',
    'Cancún',
    'Punta Cana',
    'Santa Marta',
    'Europa',
    'Miami',
    'Ciudad de México',
  ];
  // Prevent instantiation
  _SearchScreen._();
}

class _ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ComingSoonTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.deepBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: AppColors.deepBlue),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.proximamente,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.proximamenteSubtitle,
            style: TextStyle(color: AppColors.darkGray, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
