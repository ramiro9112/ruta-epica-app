import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class WhatsAppFab extends StatelessWidget {
  final String? phoneNumber;
  final String? message;

  const WhatsAppFab({
    super.key,
    this.phoneNumber,
    this.message,
  });

  Future<void> _openWhatsApp() async {
    final phone = phoneNumber ?? AppStrings.whatsAppNumber;
    final msg = Uri.encodeComponent(message ?? AppStrings.whatsAppMessage);
    final url = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _openWhatsApp,
      backgroundColor: AppColors.whatsApp,
      foregroundColor: AppColors.white,
      elevation: 4,
      tooltip: AppStrings.contactarWhatsApp,
      child: const Icon(Icons.chat_rounded, size: 26),
    );
  }
}
