import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav.dart';
import '../../utils/session.dart';
import '../../widgets/account_header.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_widgets.dart';
import '../../widgets/motion.dart';
import '../../widgets/premium.dart';
import '../admin/admin_screens.dart';
import '../flows/flows.dart';
import '../support/support_screen.dart';
import 'account_screens.dart';

/// The Account tab: profile card and a grouped menu.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.onOpenTab});

  /// Switches the bottom navigation (0 Home, 1 Services, 2 POS, 3 Account).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const FadeSlideIn(child: AccountHeader()),
        const SizedBox(height: 16),
        FadeSlideIn(delay: const Duration(milliseconds: 80), child: const _ProfileCard()),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: MenuGroup(
            label: 'ACCOUNT',
            children: [
              MenuTile(
                icon: Icons.person_outline,
                title: 'Personal details',
                tone: TpTone.blue,
                subtitle: 'Name, phone, email',
                onTap: () => openScreen(context, const PersonalDetailsScreen()),
              ),
              MenuTile(
                icon: Icons.shield_outlined,
                title: 'Security & PIN',
                tone: TpTone.teal,
                subtitle: 'Password, PIN, Face ID',
                onTap: () => openScreen(context, const SecurityScreen()),
              ),
              MenuTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                tone: TpTone.amber,
                onTap: () => openScreen(context, const NotificationsScreen()),
              ),
              MenuTile(
                icon: Icons.credit_card_outlined,
                title: 'Cards',
                tone: TpTone.purple,
                subtitle: 'Virtual and physical',
                onTap: () => openScreen(context, const CardsScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          child: MenuGroup(
            label: 'ACTIVITY',
            children: [
              MenuTile(
                icon: Icons.receipt_long_outlined,
                title: 'Transactions',
                tone: TpTone.blue,
                subtitle: 'History and receipts',
                onTap: () => openScreen(context, const TransactionHistoryScreen()),
              ),
              MenuTile(
                icon: Icons.desktop_windows_outlined,
                title: 'POS services',
                tone: TpTone.green,
                subtitle: 'Terminals and settlements',
                onTap: () => onOpenTab(2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 320),
          child: MenuGroup(
            label: 'HELP',
            children: [
              MenuTile(
                icon: Icons.headset_mic_outlined,
                title: 'Help & support',
                tone: TpTone.rose,
                subtitle: 'Chat, call or read the FAQ',
                onTap: () => openScreen(context, const SupportScreen()),
              ),
              MenuTile(
                icon: Icons.info_outline,
                title: 'About TrustPay',
                tone: TpTone.blue,
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'TrustPay',
                  applicationVersion: '1.0.0',
                ),
              ),
            ],
          ),
        ),
        if (kIsAdmin) ...[
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 380),
            child: MenuGroup(
              label: 'STAFF',
              children: [
                MenuTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin console',
                tone: TpTone.purple,
                  subtitle: 'Users, approvals, volume',
                  onTap: () => openScreen(context, const AdminDashboardScreen()),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 440),
          child: PressScale(
            scale: 0.97,
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TpColors.danger,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFF3C9C9)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ),
        if (kShowIllustrativeNote)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: Text(
                'Illustrative account · TrustPay 1.0.0',
                style: TextStyle(fontSize: 12, color: TpColors.muted),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Avatar(name: kAccountName, size: 64, light: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kAccountName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const GoldChip(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(kTier, style: TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account number', style: TextStyle(fontSize: 12, color: TpColors.muted)),
                      Text(
                        kAccountNumber,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy account number',
                  icon: const Icon(Icons.copy_rounded, color: TpColors.primary, size: 20),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: kAccountNumber));
                    HapticFeedback.selectionClick();
                    showMessage(context, 'Account number copied');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
