import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'menu_widgets.dart';

/// Where a drawer item goes. The shell decides how to open each one.
enum DrawerDest { home, services, account, transactions, pos, support, admin, logout }

/// Side menu opened from the menu button on Home, Services, POS and Account.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentTab, required this.onSelect});

  /// Active bottom tab: 0 Home, 1 Services, 2 POS, 3 Account.
  final int currentTab;
  final ValueChanged<DrawerDest> onSelect;

  @override
  Widget build(BuildContext context) {
    void pick(DrawerDest d) {
      Navigator.pop(context); // close the drawer first
      onSelect(d);
    }

    Widget item(IconData icon, String label, DrawerDest d, {int? tab, bool danger = false}) {
      return _DrawerItem(
        icon: icon,
        label: label,
        selected: tab != null && tab == currentTab,
        danger: danger,
        onTap: () => pick(d),
      );
    }

    return Drawer(
      backgroundColor: TpColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: TpGradients.premium,
                borderRadius: BorderRadius.circular(24),
                boxShadow: TpShadows.glow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Avatar(name: appState.me.fullName, size: 52, light: true),
                  const SizedBox(height: 12),
                  Text(
                    appState.me.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TrustPay · ${appState.me.accountNumber}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  item(Icons.home_outlined, 'Home', DrawerDest.home, tab: 0),
                  item(Icons.grid_view_outlined, 'Services', DrawerDest.services, tab: 1),
                  item(Icons.person_outline, 'Account', DrawerDest.account, tab: 3),
                  item(Icons.receipt_long_outlined, 'Transactions', DrawerDest.transactions),
                  item(Icons.desktop_windows_outlined, 'POS', DrawerDest.pos, tab: 2),
                  item(Icons.headset_mic_outlined, 'Help & support', DrawerDest.support),
                  if (appState.isAdmin)
                    item(Icons.admin_panel_settings_outlined, 'Admin console', DrawerDest.admin),
                ],
              ),
            ),
            const Divider(height: 1, color: TpColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: item(Icons.logout, 'Log out', DrawerDest.logout, danger: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? TpColors.danger
        : selected
            ? TpColors.primary
            : TpColors.navy;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? TpColors.tint : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
