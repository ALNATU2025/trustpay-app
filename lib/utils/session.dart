import 'package:flutter/material.dart';

import '../screens/auth_pager.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'nav.dart';

/// Asks "Log out?" and, if confirmed, returns to Login. Login slides in from
/// the left, the reverse of logging in.
Future<void> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Log out?', style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text(
        'You will need your password to sign in again.',
        style: TextStyle(color: TpColors.muted, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Stay signed in'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: TpColors.danger),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await appState.signOut();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    SwipeRoute<void>(page: const AuthPager(), fromRight: false),
    (_) => false,
  );
}
