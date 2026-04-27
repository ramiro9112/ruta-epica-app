import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/bookings_provider.dart';
import '../../widgets/shimmer_loading.dart';

class BookingsListScreen extends ConsumerWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: AppBar(
          title: const Text(AppStrings.misReservas),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStrings.activas),
              Tab(text: AppStrings.historial),
            ],
          ),
        ),
        body: bookingsAsync.when(
          loading: () => ListView.builder(
            itemCount: 3,
            itemBuilder: (_, __) => const ListTileShimmer(),
          ),
          error: (_, __) => const Center(
            child: Text(AppStrings.errorGeneral),
          ),
          data: (bookings) {
            final active =
                bookings.where((b) => b.isActive).toList();
            final history =
                bookings.where((b) => !b.isActive).toList();

            return TabBarView(
              children: [
                _BookingsList(bookings: active, isEmpty: active.isEmpty),
                _BookingsList(
                    bookings: history,
                    isEmpty: history.isEmpty,
                    isHistory: true),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool isEmpty;
  final bool isHistory;

  const _BookingsList({
    required this.bookings,
    required this.isEmpty,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.luggage_outlined,
                  size: 64, color: AppColors.mediumGray),
              const SizedBox(height: 16),
              const Text(
                AppStrings.sinReservas,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.sinReservasSubtitle,
                style: TextStyle(color: AppColors.darkGray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!isHistory)
                ElevatedButton(
                  onPressed: () => context.go('/home/explore'),
                  child: const Text('Explorar destinos'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => BookingCard(booking: bookings[i]),
    );
  }
}

class BookingCard extends ConsumerWidget {
  final BookingModel booking;

  const BookingCard({super.key, required this.booking});

  Color _statusColor() {
    switch (booking.status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel() {
    switch (booking.status) {
      case 'confirmed':
        return AppStrings.confirmada;
      case 'cancelled':
        return AppStrings.cancelada;
      default:
        return AppStrings.pendiente;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.destinationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor().withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.darkGray),
                const SizedBox(width: 5),
                Text(
                  booking.travelDate.formattedDate,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.darkGray),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.people_rounded,
                    size: 13, color: AppColors.darkGray),
                const SizedBox(width: 5),
                Text(
                  '${booking.totalPeople} pax',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.darkGray),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.totalPrice.copFormatted,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepBlue,
                  ),
                ),
                if (booking.isPending)
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cancelar reserva'),
                          content: const Text(
                              '¿Estás seguro de que deseas cancelar esta reserva?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('No'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error),
                              onPressed: () {
                                ref
                                    .read(bookingNotifierProvider.notifier)
                                    .cancelBooking(booking.id);
                                Navigator.pop(context);
                              },
                              child: const Text(AppStrings.cancelarReserva),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: AppColors.error),
                    label: const Text(
                      'Cancelar',
                      style: TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Reservado el ${booking.createdAt.formattedDate}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.darkGray),
            ),
          ],
        ),
      ),
    );
  }
}
