import 'package:flutter/material.dart';

/// Design tokens for the RepLog dark gym aesthetic.
/// Charcoal backgrounds, graphite cards, white text, and lime-green accents.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0E1012);
  static const Color surface = Color(0xFF16191D);
  static const Color surfaceElevated = Color(0xFF1E232B);
  static const Color surfaceHighlight = Color(0xFF282E38);
  static const Color card = Color(0xFF191D23);
  static const Color cardBorder = Color(0xFF262C36);

  // Lime-Green Accents
  static const Color accent = Color(0xFFCCFF00); // Athletic Neon Lime
  static const Color accentPressed = Color(0xFFB5E600);
  static const Color accentMuted = Color(0x33CCFF00);
  static const Color accentSecondary = Color(0xFF84CC16);

  // Text
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textOnAccent = Color(0xFF0E1012);

  // Status & Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Set Types
  static const Color warmup = Color(0xFFF59E0B);
  static const Color normal = Color(0xFFCCFF00);
  static const Color dropSet = Color(0xFFA855F7);
  static const Color failure = Color(0xFFEF4444);

  // Divider & Outlines
  static const Color divider = Color(0xFF232830);
  static const Color inputBorder = Color(0xFF333B47);
  static const Color inputFocused = Color(0xFFCCFF00);
}
