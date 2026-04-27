import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(_emailController.text.trim());
    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.deepBlue),
        title: const Text(
          AppStrings.recuperarContrasena,
          style: TextStyle(color: AppColors.deepBlue),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent
              ? _SuccessView(
                  email: _emailController.text,
                  onBack: () => context.pop(),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.deepBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 48,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recuperar contraseña',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.darkGray,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onSend(),
                        decoration: const InputDecoration(
                          labelText: AppStrings.correoElectronico,
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return AppStrings.errorCamposRequeridos;
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            return AppStrings.errorEmailInvalido;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: AppStrings.enviarEnlace,
                        onPressed: _onSend,
                        isLoading: authState.isLoading,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _SuccessView({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read_rounded,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),
        Text(
          '¡Correo enviado!',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Hemos enviado un enlace de recuperación a:\n$email',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGray,
                height: 1.6,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Volver al inicio',
          onPressed: onBack,
        ),
      ],
    );
  }
}
