import 'package:flutter/material.dart';

/// Lets non-widget code (the API client) navigate and show snackbars, for
/// example to send the user to Login when the session expires.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
