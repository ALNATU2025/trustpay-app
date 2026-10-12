import 'package:flutter/material.dart';

/// Back to the first route (Home).
void goHome(BuildContext context) =>
    Navigator.of(context).popUntil((route) => route.isFirst);

Future<T?> openScreen<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));

Future<T?> replaceScreen<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute(builder: (_) => screen),
    );

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Full-width swipe: the new page slides in from the right (or the left when
/// [fromRight] is false) while the page underneath slides away a little, like
/// turning a page. Used for Login, Sign up and Home.
class SwipeRoute<T> extends PageRouteBuilder<T> {
  SwipeRoute({
    required Widget page,
    bool fromRight = true,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final dx = fromRight ? 1.0 : -1.0;
            final enter = animation.drive(
              Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            );
            final exit = secondaryAnimation.drive(
              Tween<Offset>(begin: Offset.zero, end: Offset(-dx * 0.3, 0))
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            );
            return SlideTransition(
              position: exit,
              child: SlideTransition(
                position: enter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            );
          },
        );
}
