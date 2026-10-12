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
