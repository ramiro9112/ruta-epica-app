import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.white,
                  size: 64,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: const Duration(milliseconds: 300)),
              const SizedBox(height: 32),
              const Text(
                AppStrings.reservaExitosa,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 500),
                  )
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 16),
              const Text(
                AppStrings.reservaExitosaSubtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.darkGray,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 500),
                  ),
              const SizedBox(height: 16),
              // WhatsApp notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.whatsApp.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.whatsApp.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_rounded,
                        color: AppColors.whatsApp, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Te contactaremos vía WhatsApp para confirmar los detalles de tu viaje.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 800),
                    duration: const Duration(milliseconds: 500),
                  ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => context.go('/home/bookings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  AppStrings.irAReservas,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 900),
                    duration: const Duration(milliseconds: 400),
                  ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home/explore'),
                child: const Text(
                  'Volver al inicio',
                  style: TextStyle(
                    color: AppColors.darkGray,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
