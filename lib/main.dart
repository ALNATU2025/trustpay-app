import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'screens/account_ready_screen.dart';
import 'screens/auth_pager.dart';
import 'screens/home_shell.dart';
import 'screens/identity_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/api.dart';
import 'theme/app_theme.dart';
import 'utils/keys.dart';
import 'utils/nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Render's free tier sleeps; start waking the server before the first screen is drawn.
  apiClient.warmUp();
  runApp(const TrustPayApp());
}

class TrustPayApp extends StatelessWidget {
  const TrustPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustPay',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: buildTheme(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // Keep layouts intact on every phone: a little smaller text on narrow
        // screens, and the system text size limited to a comfortable range.
        final narrow = media.size.width < 360 ? 0.92 : 1.0;
        final system = media.textScaler.scale(1.0).clamp(0.9, 1.15).toDouble();
        // On tablets and web, keep the app at phone width in the middle.
        final width = math.min(media.size.width, 480.0);
        return ColoredBox(
          color: TpColors.background,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: MediaQuery(
                data: media.copyWith(
                  size: Size(width, media.size.height),
                  textScaler: TextScaler.linear(system * narrow),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/intro': (_) => const IntroScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/otp': (_) => const OtpScreen(),
        '/identity': (_) => const IdentityScreen(),
        '/ready': (_) => const AccountReadyScreen(),
      },
      // Login, Sign up and Home use the swipe transition.
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return SwipeRoute<void>(page: const AuthPager(), settings: settings);
          case '/signup':
            return SwipeRoute<void>(page: const AuthPager(initialPage: 1), settings: settings);
          case '/home':
            return SwipeRoute<void>(page: const HomeShell(), settings: settings);
        }
        return null;
      },
    );
  }
}
