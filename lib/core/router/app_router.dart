import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/explore_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/favorites/favorites_screen.dart';
import '../../presentation/screens/bookings/bookings_list_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/destinations/destination_detail_screen.dart';
import '../../presentation/screens/destinations/destinations_list_screen.dart';
import '../../presentation/screens/bookings/booking_form_screen.dart';
import '../../presentation/screens/bookings/booking_confirmation_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final isOnSplash = state.matchedLocation == '/splash';
      if (isOnSplash) return null;

      final isAuthenticated =
          Supabase.instance.client.auth.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/onboarding';

      if (!isAuthenticated && !isAuthRoute) {
        final prefs = await SharedPreferences.getInstance();
        final onboardingDone = prefs.getBool('onboarding_done') ?? false;
        if (!onboardingDone) return '/onboarding';
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/home/explore';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/destination/:id',
        name: 'destinationDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DestinationDetailScreen(destinationId: id);
        },
      ),
      GoRoute(
        path: '/destinations',
        name: 'destinationsList',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return DestinationsListScreen(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/booking/:destinationId',
        name: 'bookingForm',
        builder: (context, state) {
          final destinationId = state.pathParameters['destinationId']!;
          return BookingFormScreen(destinationId: destinationId);
        },
      ),
      GoRoute(
        path: '/booking/confirmation',
        name: 'bookingConfirmation',
        builder: (context, state) => const BookingConfirmationScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return HomeScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home/explore',
            name: 'explore',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExploreScreen(),
            ),
          ),
          GoRoute(
            path: '/home/search',
            name: 'search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/home/favorites',
            name: 'favorites',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FavoritesScreen(),
            ),
          ),
          GoRoute(
            path: '/home/bookings',
            name: 'bookings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BookingsListScreen(),
            ),
          ),
          GoRoute(
            path: '/home/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
