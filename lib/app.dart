import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class RutaEpicaApp extends ConsumerWidget {
  const RutaEpicaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Ruta Épica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        // Clamp font scale to prevent accessibility overrides from breaking layout
        final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(0.8, 1.2);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
