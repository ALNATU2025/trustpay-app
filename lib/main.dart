import 'package:flutter/material.dart';

import 'screens/account_ready_screen.dart';
import 'screens/auth_pager.dart';
import 'screens/home_shell.dart';
import 'screens/identity_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'utils/nav.dart';

void main() => runApp(const TrustPayApp());

class TrustPayApp extends StatelessWidget {
  const TrustPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustPay',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
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
