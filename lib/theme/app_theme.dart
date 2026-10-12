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

/// Brand gradients and soft shadows used across the app.
class TpGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B7BFF), Color(0xFF0560E4), Color(0xFF0A3FB0)],
    stops: [0.0, 0.5, 1.0],
  );

  static const success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22B866), Color(0xFF0E8F47)],
  );
}

class TpShadows {
  /// Very soft lift for white cards.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF14233F).withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Coloured glow under the main blue surfaces.
  static List<BoxShadow> get glow => [
        BoxShadow(
          color: TpColors.primary.withOpacity(0.32),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];
}

/// Page transition used for every route: a short fade plus a gentle slide in
/// from the right. The page underneath drifts left a little.
class TpPageTransitionsBuilder extends PageTransitionsBuilder {
  const TpPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideIn = animation.drive(
      Tween<Offset>(begin: const Offset(0.10, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    final fadeIn = animation.drive(CurveTween(curve: Curves.easeOut));
    final slideAway = secondaryAnimation.drive(
      Tween<Offset>(begin: Offset.zero, end: const Offset(-0.06, 0))
          .chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    return SlideTransition(
      position: slideAway,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(position: slideIn, child: child),
      ),
    );
  }
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
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const TpPageTransitionsBuilder(),
      },
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: TpColors.navy,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: TpColors.navy,
      displayColor: TpColors.navy,
    ),
  );
}
