import 'package:flutter/material.dart';

import '../screens/account/account_screens.dart';
import '../theme/app_theme.dart';
import '../utils/nav.dart';
import 'common.dart';
import 'motion.dart';

/// Menu button, logo, "PERSONAL ACCOUNT / Hello, Ada" and the notification bell.
/// Must sit inside the Home shell so the menu button can open its drawer.
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
          icon: Icons.menu_rounded,
          tooltip: 'Menu',
          onTap: () => Scaffold.maybeOf(context)?.openDrawer(),
        ),
        const SizedBox(width: 10),
        const TpLogo(height: 44),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERSONAL ACCOUNT',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, letterSpacing: 0.4, color: TpColors.muted),
              ),
              SizedBox(height: 2),
              Text('Hello, Ada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _RoundButton(
              icon: Icons.notifications_none,
              tooltip: 'Notifications',
              onTap: () => openScreen(context, const NotificationsScreen()),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: IgnorePointer(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: TpColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.9,
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: const Color(0x2214233F),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: TpColors.navy, semanticLabel: tooltip),
          ),
        ),
      ),
    );
  }
}
