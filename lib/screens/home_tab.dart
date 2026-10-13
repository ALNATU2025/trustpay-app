import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/account_header.dart';
import '../utils/nav.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/premium.dart';
import 'flows/flows.dart';

class _Txn {
  const _Txn(this.title, this.meta, this.amount, this.icon);

  final String title;
  final String meta;
  final double amount;
  final IconData icon;
}

// Sample data from the design. Replace with data from your API.
const _transactions = [
  _Txn('From Mohamed Sesay', 'Bank transfer · 10:24', 1250, Icons.south_west),
  _Txn('EDSA Cash Power', 'Bill payment · 09:18', -625, Icons.flash_on_outlined),
  _Txn('To Fatmata Conteh', 'Bank transfer · Yesterday', -400, Icons.north_east),
];

class _Essential {
  const _Essential(this.icon, this.label, this.tone, this.open);

  final IconData icon;
  final String label;
  final TpTone tone;
  final void Function(BuildContext) open;
}

final _essentials = <_Essential>[
  _Essential(Icons.account_balance_outlined, 'Transfer', TpTone.blue,
      (c) => openScreen(c, const SendBankScreen())),
  _Essential(Icons.flash_on_outlined, 'Pay bills', TpTone.amber,
      (c) => openScreen(c, const PayBillScreen())),
  _Essential(Icons.credit_card_outlined, 'Cards', TpTone.teal,
      (c) => openScreen(c, const CardsScreen())),
];

/// Screen 12: Home.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onOpenTab});

  /// Switches the bottom navigation (0 Home, 1 Services, 2 POS, 3 Profile).
  final ValueChanged<int> onOpenTab;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _hidden = false;
  static const _balance = 12450.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const FadeSlideIn(child: AccountHeader()),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _BalanceCard(
            hidden: _hidden,
            balance: _balance,
            onToggle: () => setState(() => _hidden = !_hidden),
            onSend: () => showSendOptions(context),
            onAdd: () => openScreen(context, const AddMoneyScreen()),
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your everyday essentials',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () => widget.onOpenTab(1),
                child: const Text(
                  'All services',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TpColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _essentials.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 220 + i * 60),
                  child: _EssentialTile(
                    icon: _essentials[i].icon,
                    label: _essentials[i].label,
                    tone: _essentials[i].tone,
                    onTap: () => _essentials[i].open(context),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 400),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: TpShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent transactions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    TextButton(
                      onPressed: () => openScreen(context, const TransactionHistoryScreen()),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(48, 36)),
                      child: const Text(
                        'See all',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TpColors.primary),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'TODAY · 11 OCTOBER',
                  style: TextStyle(fontSize: 12, letterSpacing: 0.4, color: TpColors.muted),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < _transactions.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 480 + i * 80),
                    offset: 12,
                    child: _TxnRow(txn: _transactions[i], showDivider: true),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 700),
          child: PressScale(
            scale: 0.98,
            child: Material(
              color: TpColors.greenTint,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => widget.onOpenTab(2),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.desktop_windows_outlined, color: TpColors.green, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'A little more for your business',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Explore POS services and collect payments.',
                              style: TextStyle(fontSize: 13, color: TpColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: TpColors.green),
                    ],
                  ),
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
                'Illustrative account · All amounts in Leones (SLE)',
                style: TextStyle(fontSize: 12, color: TpColors.muted),
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.hidden,
    required this.balance,
    required this.onToggle,
    required this.onSend,
    required this.onAdd,
  });

  final bool hidden;
  final double balance;
  final VoidCallback onToggle;
  final VoidCallback onSend;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    const balanceStyle = TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: Colors.white,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GoldChip(),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Available balance', style: TextStyle(fontSize: 14, color: Colors.white70)),
              ),
              IconButton(
                tooltip: hidden ? 'Show balance' : 'Hide balance',
                visualDensity: VisualDensity.compact,
                onPressed: onToggle,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    key: ValueKey(hidden),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: hidden
                  ? const Text('Le ••••••', key: ValueKey('hidden'), style: balanceStyle)
                  : CountUpText(
                      key: const ValueKey('shown'),
                      value: balance,
                      format: (v) => formatLeone(v),
                      style: balanceStyle,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'TrustPay account · 0123454821',
              style: TextStyle(fontSize: 12, letterSpacing: 0.2, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CardAction(icon: Icons.north_east, label: 'Send money', onTap: onSend),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardAction(icon: Icons.add, label: 'Add money', onTap: onAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: TpColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TpColors.primary,
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

class _EssentialTile extends StatelessWidget {
  const _EssentialTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = TpTone.blue,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final TpTone tone;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.95,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: TpShadows.card,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBox(icon: icon, size: 40, tone: tone),
                  const SizedBox(height: 14),
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn, required this.showDivider});

  final _Txn txn;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final credit = txn.amount > 0;
    return Column(
      children: [
        Row(
          children: [
            IconBox(icon: txn.icon, size: 40, tone: credit ? TpTone.green : TpTone.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txn.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(txn.meta, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                ],
              ),
            ),
            Text(
              formatLeone(txn.amount, showSign: true),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: credit ? TpColors.green : TpColors.navy,
              ),
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: TpColors.border),
          ),
      ],
    );
  }
}
