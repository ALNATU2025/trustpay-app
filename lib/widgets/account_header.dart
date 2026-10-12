import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// Logo, "PERSONAL ACCOUNT / Hello, Ada" and the notification bell.
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const TpLogo(height: 56),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERSONAL ACCOUNT',
                style: TextStyle(fontSize: 12, letterSpacing: 0.4, color: TpColors.muted),
              ),
              SizedBox(height: 2),
              Text('Hello, Ada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.notifications_none, color: TpColors.navy),
            ),
          ),
        ),
      ],
    );
  }
}
