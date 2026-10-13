import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/account_header.dart';
import '../utils/nav.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'flows/flows.dart';
import 'support/support_screen.dart';

class _Service {
  const _Service(this.icon, this.title, this.subtitle, this.tone);

  final IconData icon;
  final String title;
  final String subtitle;
  final TpTone tone;
}

const _services = [
  _Service(Icons.send_outlined, 'Send money', 'To a TrustPay user', TpTone.blue),
  _Service(Icons.add, 'Add money', 'Fund your account', TpTone.green),
  _Service(Icons.account_balance_outlined, 'Bank transfer', 'To any bank', TpTone.blue),
  _Service(Icons.smartphone_outlined, 'Airtime & data', 'Stay connected', TpTone.purple),
  _Service(Icons.receipt_long_outlined, 'Bill payments', 'Power, TV & more', TpTone.amber),
  _Service(Icons.credit_card_outlined, 'Virtual card', 'For online payments', TpTone.teal),
  _Service(Icons.wallet_outlined, 'Physical card', 'Pay wherever you go', TpTone.rose),
  _Service(Icons.desktop_windows_outlined, 'POS services', 'Collect & manage sales', TpTone.green),
];

/// Screen 13: All services.
class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key, required this.onOpenTab});

  /// Switches the bottom navigation (0 Home, 1 Services, 2 POS, 3 Profile).
  final ValueChanged<int> onOpenTab;

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  String _query = '';

  void _open(_Service s) {
    switch (s.title) {
      case 'Send money':
        openScreen(context, const SendToUserScreen());
      case 'Bank transfer':
        openScreen(context, const SendBankScreen());
      case 'Add money':
        openScreen(context, const AddMoneyScreen());
      case 'Airtime & data':
        openScreen(context, const AirtimeDataScreen());
      case 'Bill payments':
        openScreen(context, const PayBillScreen());
      case 'Virtual card':
        openScreen(context, const CardsScreen());
      case 'Physical card':
        openScreen(context, const CardsScreen(initialTab: 1));
      case 'POS services':
        widget.onOpenTab(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? _services
        : _services
            .where((s) => s.title.toLowerCase().contains(q) || s.subtitle.toLowerCase().contains(q))
            .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const AccountHeader(),
        const SizedBox(height: 20),
        const Text('All services', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
          'Everything you need. In one place.',
          style: TextStyle(fontSize: 15, color: TpColors.muted),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search services',
            hintStyle: const TextStyle(color: TpColors.muted),
            prefixIcon: const Icon(Icons.search, color: TpColors.muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('No services match your search.', style: TextStyle(color: TpColors.muted)),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              for (var i = 0; i < items.length; i++)
                FadeSlideIn(
                  key: ValueKey(items[i].title),
                  delay: Duration(milliseconds: 40 * i),
                  offset: 14,
                  child: _ServiceCard(service: items[i], onTap: () => _open(items[i])),
                ),
            ],
          ),
        const SizedBox(height: 16),
        Material(
          color: TpColors.tint,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => openScreen(context, const SupportChatScreen()),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.headset_mic_outlined, color: TpColors.primary),
                  SizedBox(width: 14),
                  Text(
                    'Need a hand? Chat with support',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
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
                'Illustrative account · All amounts in Leones (SLE)',
                style: TextStyle(fontSize: 12, color: TpColors.muted),
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final _Service service;
  final VoidCallback onTap;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconBox(icon: service.icon, size: 40, tone: service.tone),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: TpColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
