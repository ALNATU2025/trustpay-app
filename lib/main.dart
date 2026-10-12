import 'package:flutter/material.dart';

import 'screens/account_ready_screen.dart';
import 'screens/home_shell.dart';
import 'screens/identity_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

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
        '/signup': (_) => const SignUpScreen(),
        '/otp': (_) => const OtpScreen(),
        '/identity': (_) => const IdentityScreen(),
        '/ready': (_) => const AccountReadyScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeShell(),
      },
    );
  }
}
