import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _openFaq;

  static const _phone = AppStrings.whatsAppNumber;
  static const _contactEmail = 'agenciarutaepica@gmail.com';

  Future<void> _whatsApp() async {
    final msg = Uri.encodeComponent('Hola! Necesito ayuda con la app Ruta Épica');
    final url = Uri.parse('https://wa.me/$_phone?text=$msg');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _sendEmail() async {
    final url = Uri.parse(
        'mailto:$_contactEmail?subject=Soporte%20Ruta%20%C3%89pica&body=Hola%2C%20necesito%20ayuda%20con...');
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  Future<void> _call() async {
    try {
      await launchUrl(Uri.parse('tel:+$_phone'));
    } catch (_) {}
  }

  static const _faqs = [
    {
      'q': '¿Cómo reservo un paquete?',
      'a': 'Busca el destino que deseas, toca en la tarjeta y luego presiona "RESERVAR AHORA". Completa tus datos y confirma. Un asesor te contactará para finalizar el proceso.'
    },
    {
      'q': '¿Cuáles son los medios de pago?',
      'a': 'Aceptamos transferencias bancarias, pagos PSE, tarjetas de crédito/débito y efectivo a través de corresponsales. Te indicamos el proceso al confirmar tu reserva.'
    },
    {
      'q': '¿Puedo cancelar mi reserva?',
      'a': 'Sí. Las cancelaciones con más de 30 días de anticipación tienen reembolso total. Entre 15-30 días, 50%. Menos de 15 días, aplican penalidades. Contáctanos para casos especiales.'
    },
    {
      'q': '¿Los precios incluyen tiquetes aéreos?',
      'a': 'La mayoría de nuestros paquetes incluyen tiquetes aéreos desde las principales ciudades de Colombia. El detalle está especificado en cada paquete bajo la sección "Incluye".'
    },
    {
      'q': '¿Puedo viajar en grupo?',
      'a': 'Sí. Al reservar puedes indicar el número de adultos y niños. Para grupos grandes de más de 10 personas, contáctanos por WhatsApp para obtener tarifas especiales.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Ayuda y soporte'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        children: [
          // Contact header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deepBlue, AppColors.deepBlueLight],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Necesitas ayuda?',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Estamos disponibles de lunes a sábado, 8am - 6pm.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _whatsApp,
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.whatsApp,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _call,
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: const Text('Llamar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: const BorderSide(color: Colors.white54),
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _sendEmail,
                    icon: const Icon(Icons.email_outlined, size: 16),
                    label: const Text('agenciarutaepica@gmail.com'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // FAQ
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: const Text(
              'Preguntas frecuentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _faqs.asMap().entries.map((entry) {
                final i = entry.key;
                final faq = entry.value;
                final isOpen = _openFaq == i;
                return Column(
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _openFaq = isOpen ? null : i),
                      borderRadius: BorderRadius.vertical(
                        top: i == 0
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottom: i == _faqs.length - 1 && !isOpen
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq['q']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isOpen
                                      ? AppColors.deepBlue
                                      : AppColors.darkText,
                                ),
                              ),
                            ),
                            Icon(
                              isOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.darkGray,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isOpen)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['a']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkGray,
                            height: 1.6,
                          ),
                        ),
                      ),
                    if (i < _faqs.length - 1)
                      const Divider(
                          height: 1, indent: 16, endIndent: 16,
                          color: AppColors.lightGray),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
