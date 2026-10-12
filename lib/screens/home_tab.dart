import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/account_header.dart';
import '../utils/nav.dart';
import '../widgets/common.dart';
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
  _Txn('From Chidi Okafor', 'Bank transfer · 10:24', 25000, Icons.south_west),
  _Txn('Ikeja Electric', 'Bill payment · 09:18', -12500, Icons.flash_on_outlined),
  _Txn('To Tolu Adebayo', 'Bank transfer · Yesterday', -8000, Icons.north_east),
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
  static const _balance = 248500.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const AccountHeader(),
        const SizedBox(height: 16),
        _BalanceCard(
          hidden: _hidden,
          balance: _balance,
          onToggle: () => setState(() => _hidden = !_hidden),
          onSend: () => openScreen(context, const SendBankScreen()),
          onAdd: () => openScreen(context, const AddMoneyScreen()),
        ),
        const SizedBox(height: 20),
        Row(
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _EssentialTile(
                icon: Icons.account_balance_outlined,
                label: 'Transfer',
                onTap: () => openScreen(context, const SendBankScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EssentialTile(
                icon: Icons.smartphone_outlined,
                label: 'Airtime/data',
                onTap: () => openScreen(context, const AirtimeDataScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EssentialTile(
                icon: Icons.receipt_long_outlined,
                label: 'Pay bills',
                onTap: () => openScreen(context, const PayBillScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                _TxnRow(txn: _transactions[i], showDivider: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Material(
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
        if (kShowIllustrativeNote)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: Text(
                'Illustrative account · All amounts in NGN',
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TpColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available balance', style: TextStyle(fontSize: 14, color: Colors.white70)),
              IconButton(
                tooltip: hidden ? 'Show balance' : 'Hide balance',
                visualDensity: VisualDensity.compact,
                onPressed: onToggle,
                icon: Icon(
                  hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hidden ? '₦ ••••••' : formatNaira(balance),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'TrustPay account · 0123454821',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 14),
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
    return Material(
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
    );
  }
}

class _EssentialTile extends StatelessWidget {
  const _EssentialTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              IconBox(icon: icon, size: 40),
              const SizedBox(height: 14),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
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
            IconBox(icon: txn.icon, size: 40),
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
              formatNaira(txn.amount, showSign: true),
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
