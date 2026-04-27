import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color deepBlue = Color(0xFF0B2F5C);
  static const Color deepBlueLight = Color(0xFF1A4A8A);
  static const Color deepBlueDark = Color(0xFF071D3A);

  // Accent
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFE8BB3A);
  static const Color goldDark = Color(0xFFAA7F10);
  static const Color turquoise = Color(0xFF00BFA5);
  static const Color turquoiseLight = Color(0xFF33CCBA);
  static const Color turquoiseDark = Color(0xFF009982);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F7FA);
  static const Color mediumGray = Color(0xFFE0E6EF);
  static const Color darkGray = Color(0xFF8A8FA8);
  static const Color darkText = Color(0xFF1A1A2E);

  // Status
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // WhatsApp
  static const Color whatsApp = Color(0xFF25D366);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepBlue, deepBlueLight],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC0B2F5C)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, goldDark],
  );

  static const LinearGradient slideGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepBlue, Color(0xFF1565C0)],
  );

  static const LinearGradient slideGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), turquoiseDark],
  );

  static const LinearGradient slideGradient3 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
  );
}
