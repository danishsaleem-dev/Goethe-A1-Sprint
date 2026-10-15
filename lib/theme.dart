import 'package:flutter/material.dart';

class AppColors {
  static const Color der = Color(0xFF2F6FED);
  static const Color die = Color(0xFFE5484D);
  static const Color das = Color(0xFF2FA866);
  static const Color gold = Color(0xFFF5A524);

  static Color forArticle(String? article) {
    switch (article) {
      case 'der':
        return der;
      case 'die':
        return die;
      case 'das':
        return das;
      default:
        return Colors.grey;
    }
  }
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3D5AFE),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: brightness == Brightness.light
        ? const Color(0xFFF6F7FB)
        : const Color(0xFF0F1117),
  );
}
