import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/home/explore')) return 0;
    if (location.startsWith('/home/search')) return 1;
    if (location.startsWith('/home/favorites')) return 2;
    if (location.startsWith('/home/bookings')) return 3;
    if (location.startsWith('/home/profile')) return 4;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home/explore');
        break;
      case 1:
        context.go('/home/search');
        break;
      case 2:
        context.go('/home/favorites');
        break;
      case 3:
        context.go('/home/bookings');
        break;
      case 4:
        context.go('/home/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onTabTapped(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.darkGray,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: AppStrings.inicio,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: AppStrings.buscar,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: AppStrings.favoritos,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.luggage_outlined),
              activeIcon: Icon(Icons.luggage_rounded),
              label: AppStrings.reservas,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: AppStrings.perfil,
            ),
          ],
        ),
      ),
    );
  }
}
