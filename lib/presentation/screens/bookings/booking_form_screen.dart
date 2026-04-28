import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/destination_model.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/destinations_provider.dart';
import '../../widgets/custom_button.dart';
import '../profile/profile_screen.dart' show showAuthRequiredDialog;

class BookingFormScreen extends ConsumerStatefulWidget {
  final String destinationId;

  const BookingFormScreen({super.key, required this.destinationId});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKeyStep2 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Reset form on open
    Future.microtask(() {
      ref.read(bookingNotifierProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Safety net: if user navigated here as guest (deep link), redirect.
    final isGuest = Supabase.instance.client.auth.currentUser == null;
    if (isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showAuthRequiredDialog(context,
              reason: 'Inicia sesión para hacer una reserva.');
          context.pop();
        }
      });
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final bookingState = ref.watch(bookingNotifierProvider);
    final destinationAsync =
        ref.watch(destinationDetailProvider(widget.destinationId));

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(AppStrings.nuevaReserva),
      ),
      body: destinationAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text(AppStrings.errorGeneral)),
        data: (destination) => Column(
          children: [
            // Step indicator
            _StepIndicator(currentStep: bookingState.currentStep),
            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: bookingState.currentStep == 0
                      ? _Step1(key: const ValueKey(0))
                      : bookingState.currentStep == 1
                          ? _Step2(
                              key: const ValueKey(1),
                              formKey: _formKeyStep2,
                            )
                          : _Step3(
                              key: const ValueKey(2),
                              destination: destination,
                            ),
                ),
              ),
            ),
            // Navigation buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (bookingState.currentStep > 0)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SecondaryButton(
                            label: AppStrings.anterior,
                            onPressed: () => ref
                                .read(bookingNotifierProvider.notifier)
                                .previousStep(),
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        label: bookingState.currentStep == 2
                            ? AppStrings.confirmarReserva
                            : AppStrings.siguiente2,
                        isLoading: bookingState.isLoading,
                        onPressed: () => _handleNext(destination.priceFrom,
                            destination.id, destination.name),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNext(
    double pricePerPerson,
    String destinationId,
    String destinationName,
  ) async {
    final notifier = ref.read(bookingNotifierProvider.notifier);
    final state = ref.read(bookingNotifierProvider);

    if (state.currentStep == 0) {
      if (!state.isStep1Valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona la fecha de viaje y el número de pasajeros.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      notifier.nextStep();
    } else if (state.currentStep == 1) {
      if (!_formKeyStep2.currentState!.validate()) return;
      notifier.nextStep();
    } else {
      final success = await notifier.submitBooking(
        destinationId: destinationId,
        destinationName: destinationName,
        pricePerPerson: pricePerPerson,
      );
      if (success && mounted) {
        context.pushReplacement('/booking/confirmation');
      } else if (mounted && ref.read(bookingNotifierProvider).errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(bookingNotifierProvider).errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  static const List<String> _labels = [
    AppStrings.detallesViaje,
    AppStrings.datosCPersonales,
    AppStrings.confirmacion,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentStep
                    ? AppColors.gold
                    : AppColors.mediumGray,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;
          return Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.gold
                      : isCurrent
                          ? AppColors.deepBlue
                          : AppColors.mediumGray,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.white, size: 16)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? AppColors.white
                                : AppColors.darkGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[stepIndex],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isCurrent ? AppColors.deepBlue : AppColors.darkGray,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Step1 extends ConsumerWidget {
  const _Step1({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingNotifierProvider);
    final notifier = ref.read(bookingNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: AppStrings.fechaViaje,
          icon: Icons.calendar_today_rounded,
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.deepBlue,
                      secondary: AppColors.gold,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) notifier.setTravelDate(picked);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: state.travelDate != null
                      ? AppColors.deepBlue
                      : AppColors.mediumGray,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: state.travelDate != null
                        ? AppColors.deepBlue
                        : AppColors.darkGray,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    state.travelDate != null
                        ? state.travelDate!.dayMonthYear
                        : AppStrings.seleccionarFecha,
                    style: TextStyle(
                      fontSize: 14,
                      color: state.travelDate != null
                          ? AppColors.darkText
                          : AppColors.darkGray,
                      fontWeight: state.travelDate != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppStrings.adultos,
          icon: Icons.person_rounded,
          child: _CounterRow(
            label: 'Adultos (12+ años)',
            value: state.adults,
            minValue: 1,
            onDecrement: () => notifier.setAdults(state.adults - 1),
            onIncrement: () => notifier.setAdults(state.adults + 1),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppStrings.ninos,
          icon: Icons.child_care_rounded,
          child: _CounterRow(
            label: 'Niños (2-11 años)',
            value: state.children,
            minValue: 0,
            onDecrement: () => notifier.setChildren(state.children - 1),
            onIncrement: () => notifier.setChildren(state.children + 1),
          ),
        ),
      ],
    );
  }
}

class _Step2 extends ConsumerWidget {
  final GlobalKey<FormState> formKey;

  const _Step2({super.key, required this.formKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingNotifierProvider);
    final notifier = ref.read(bookingNotifierProvider.notifier);

    return Form(
      key: formKey,
      child: Column(
        children: [
          _SectionCard(
            title: AppStrings.datosCPersonales,
            icon: Icons.person_outline,
            child: Column(
              children: [
                TextFormField(
                  initialValue: state.fullName,
                  textCapitalization: TextCapitalization.words,
                  onChanged: notifier.setFullName,
                  decoration: const InputDecoration(
                    labelText: AppStrings.nombreCompleto,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.errorCamposRequeridos
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: state.phone,
                  keyboardType: TextInputType.phone,
                  onChanged: notifier.setPhone,
                  decoration: const InputDecoration(
                    labelText: AppStrings.telefono,
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.errorCamposRequeridos
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: state.email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: notifier.setEmail,
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.correoElectronico} (opcional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: state.observations,
                  maxLines: 3,
                  onChanged: notifier.setObservations,
                  decoration: const InputDecoration(
                    labelText: AppStrings.observaciones,
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step3 extends ConsumerWidget {
  final DestinationModel destination;

  const _Step3({super.key, required this.destination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingNotifierProvider);
    final total =
        destination.priceFrom * (state.adults + state.children);

    return Column(
      children: [
        _SectionCard(
          title: AppStrings.resumenReserva,
          icon: Icons.receipt_long_rounded,
          child: Column(
            children: [
              _SummaryRow(
                label: 'Destino',
                value: destination.name,
                isHighlight: true,
              ),
              _SummaryRow(
                label: AppStrings.fechaViaje,
                value: state.travelDate?.dayMonthYear ?? '-',
              ),
              _SummaryRow(
                label: AppStrings.adultos,
                value: '${state.adults}',
              ),
              _SummaryRow(
                label: AppStrings.ninos,
                value: '${state.children}',
              ),
              _SummaryRow(
                label: 'Pasajeros totales',
                value: '${state.adults + state.children}',
              ),
              const Divider(height: 24),
              _SummaryRow(
                label: 'Precio por persona',
                value: destination.priceFrom.copFormatted,
              ),
              _SummaryRow(
                label: 'TOTAL',
                value: total.copFormatted,
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppStrings.datosCPersonales,
          icon: Icons.person_outline,
          child: Column(
            children: [
              _SummaryRow(label: 'Nombre', value: state.fullName),
              _SummaryRow(label: 'Teléfono', value: state.phone),
              if (state.email.isNotEmpty)
                _SummaryRow(label: 'Correo', value: state.email),
              if (state.observations.isNotEmpty)
                _SummaryRow(
                    label: 'Observaciones', value: state.observations),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.turquoise.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.turquoise.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.turquoiseDark, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Al confirmar, nos pondremos en contacto contigo para finalizar los detalles de tu reserva.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.turquoiseDark,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.deepBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int minValue;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CounterRow({
    required this.label,
    required this.value,
    required this.minValue,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.darkText),
        ),
        Row(
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: value <= minValue
                        ? AppColors.mediumGray
                        : AppColors.deepBlue,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.remove_rounded,
                    size: 16,
                    color: value <= minValue
                        ? AppColors.mediumGray
                        : AppColors.deepBlue),
              ),
              onPressed: value <= minValue ? null : onDecrement,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.deepBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded,
                    size: 16, color: AppColors.white),
              ),
              onPressed: onIncrement,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isTotal ? AppColors.darkText : AppColors.darkGray,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 17 : 13,
              fontWeight: isHighlight || isTotal
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isTotal ? AppColors.deepBlue : AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
