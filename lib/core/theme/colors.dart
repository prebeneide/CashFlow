import 'package:flutter/material.dart';

class AppColors {
  // Moderne primærfarger (SaaS-stil) – skarp lilla som hovedfarge
  static const Color primary = Color(0xFF7C3AED);       // Skarp lilla
  static const Color primaryDark = Color(0xFF6D28D9);   // Mørkere lilla
  static const Color primaryLight = Color(0xFFA855F7);  // Lysere lilla
  
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color accent = Color(0xFFF59E0B); // Amber
  
  // Status-farger
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Light mode - moderne SaaS bakgrunner (lyse, rene)
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  
  // Dark mode - moderne SaaS bakgrunner (dype, rike, med subtil lilla-tone)
  static const Color backgroundDark = Color(0xFF050316);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);
  
  // Tekst-farger
  static const Color textLight = Color(0xFF0A0A0A);
  static const Color textLightSecondary = Color(0xFF6B7280);
  static const Color textDark = Color(0xFFFAFAFA);
  static const Color textDarkSecondary = Color(0xFF9CA3AF);
  
  // Glassmorphism-farger (for gjennomsiktighet)
  static Color glassLight = Colors.white.withValues(alpha: 0.1);
  static Color glassDark = Colors.black.withValues(alpha: 0.2);
  
  // Gradient-bakgrunner (SaaS-stil)
  static const LinearGradient backgroundGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAFAFA),
      Color(0xFFF5F5F5),
    ],
  );
  
  static const LinearGradient backgroundGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF050316),
      Color(0xFF111827),
    ],
  );
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C3AED), // skarp lilla
      Color(0xFFA855F7), // lysere lilla
    ],
  );
}
