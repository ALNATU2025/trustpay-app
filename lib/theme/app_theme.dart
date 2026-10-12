import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours sampled by eye from the Figma screens. Replace with exact values
/// from Figma Dev Mode if you need pixel-perfect matching.
class TpColors {
  static const primary = Color(0xFF0560E4);
  static const navy = Color(0xFF14233F);
  static const muted = Color(0xFF74829B);
  static const background = Color(0xFFF4F7FD);
  static const tint = Color(0xFFEAF1FE);
  static const border = Color(0xFFE3EAF5);
  static const dot = Color(0xFFDDE5F2);
  static const green = Color(0xFF0E8F47);
  static const greenTint = Color(0xFFE8F6EE);
  static const splash = Color(0xFFF5F5F5);
  static const danger = Color(0xFFD64545);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TpColors.primary,
      primary: TpColors.primary,
    ),
    scaffoldBackgroundColor: TpColors.background,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: TpColors.navy,
      displayColor: TpColors.navy,
    ),
  );
}
