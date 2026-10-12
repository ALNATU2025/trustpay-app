import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_widgets.dart';
import '../../widgets/motion.dart';
import '../flows/flows.dart';

// All numbers on the admin screens are sample data. Replace them with data
// from your admin API, and make that API check the staff role on every call.

/// Staff overview: volume, key numbers, a weekly chart and shortcuts.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const _week = [
    ('Mon', 12.4),
    ('Tue', 15.1),
    ('Wed', 11.8),
    ('Thu', 17.3),
    ('Fri', 21.6),
    ('Sat', 14.2),
    ('Sun', 18.4),
  ];

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Admin console',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: TpColors.tint, borderRadius: BorderRadius.circular(20)),
        child: const Text(
          'STAFF',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: TpColors.primary),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: TpGradients.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: TpShadows.glow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's volume", style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 6),
                CountUpText(
                  value: 18420000,
                  format: (v) => formatNaira(v, decimals: 0),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('▲ 8.4% vs yesterday', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _Kpi(icon: Icons.people_outline, label: 'Total users', value: '12,480')),
              SizedBox(width: 12),
              Expanded(child: _Kpi(icon: Icons.bolt_outlined, label: 'Active today', value: '3,214')),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _Kpi(icon: Icons.fact_check_outlined, label: 'Pending approvals', value: '4')),
              SizedBox(width: 12),
              Expanded(child: _Kpi(icon: Icons.support_agent_outlined, label: 'Open tickets', value: '14')),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: TpShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Volume this week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Text('₦ millions', style: TextStyle(fontSize: 12, color: TpColors.muted)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < _week.length; i++)
                        Expanded(child: _Bar(label: _week[i].$1, value: _week[i].$2, max: 22, index: i)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          MenuGroup(
            label: 'MANAGE',
            children: [
              MenuTile(
                icon: Icons.people_outline,
                title: 'Users',
                subtitle: 'Search, view and suspend accounts',
                onTap: () => openScreen(context, const AdminUsersScreen()),
              ),
              MenuTile(
                icon: Icons.fact_check_outlined,
                title: 'Approvals',
                subtitle: 'KYC, POS terminals, limits',
                onTap: () => openScreen(context, const AdminApprovalsScreen()),
              ),
              MenuTile(
                icon: Icons.receipt_long_outlined,
                title: 'All transactions',
                onTap: () => openScreen(context, const TransactionHistoryScreen()),
              ),
            ],
          ),
          if (kShowIllustrativeNote)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Illustrative data · All amounts in NGN',
                    style: TextStyle(fontSize: 12, color: TpColors.muted)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: TpShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(icon: icon, size: 36),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.max, required this.index});

  final String label;
  final double value;
  final double max;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value / max),
              duration: Duration(milliseconds: 600 + index * 90),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => FractionallySizedBox(
                heightFactor: t.clamp(0.02, 1.0),
                child: Container(
                  width: 22,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2B7BFF), Color(0xFF0560E4)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: TpColors.muted)),
      ],
    );
  }
}

// ------------------------------------------------------------------ users

class _AdminUser {
  _AdminUser(this.name, this.phone, this.tier, this.status);

  final String name;
  final String phone;
  final String tier;
  String status; // Active, Suspended or Pending KYC
}

/// Searchable user list. Tap a user to see details and suspend or reactivate.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _users = [
    _AdminUser('Ada Okafor', '0803 456 7890', 'Tier 2', 'Active'),
    _AdminUser('Chidi Okafor', '0802 111 2233', 'Tier 3', 'Active'),
    _AdminUser('Tolu Adebayo', '0805 222 3344', 'Tier 2', 'Active'),
    _AdminUser('Ngozi Eze', '0807 333 4455', 'Tier 1', 'Pending KYC'),
    _AdminUser('Ibrahim Musa', '0809 444 5566', 'Tier 2', 'Suspended'),
    _AdminUser('Funke Bello', '0810 555 6677', 'Tier 1', 'Pending KYC'),
    _AdminUser('Emeka Nwosu', '0812 666 7788', 'Tier 3', 'Active'),
  ];
  String _query = '';

  Color _statusColor(String s) => switch (s) {
        'Active' => TpColors.green,
        'Suspended' => TpColors.danger,
        _ => const Color(0xFFB7791F),
      };

  void _open(_AdminUser u) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(name: u.name, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      Text(u.phone, style: const TextStyle(color: TpColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('${u.tier} · ${u.status}', style: TextStyle(fontWeight: FontWeight.w700, color: _statusColor(u.status))),
            const SizedBox(height: 20),
            if (u.status != 'Pending KYC')
              PrimaryButton(
                label: u.status == 'Suspended' ? 'Reactivate account' : 'Suspend account',
                onPressed: () {
                  // TODO: call your admin API, then update the list.
                  setState(() => u.status = u.status == 'Suspended' ? 'Active' : 'Suspended');
                  Navigator.pop(sheetContext);
                  showMessage(context, '${u.name} is now ${u.status.toLowerCase()}');
                },
              )
            else
              const InfoBanner(
                text: 'This user has not finished identity verification. Review it under Approvals.',
                icon: Icons.info_outline,
              ),
            const SizedBox(height: 8),
            SecondaryButton(label: 'Close', onPressed: () => Navigator.pop(sheetContext)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = _users
        .where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || u.phone.replaceAll(' ', '').contains(q.replaceAll(' ', '')))
        .toList();
    return PlainScaffold(
      title: 'Users',
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search name or phone',
              hintStyle: const TextStyle(color: TpColors.muted),
              prefixIcon: const Icon(Icons.search, color: TpColors.muted),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No users match your search.', style: TextStyle(color: TpColors.muted)),
            )
          else
            MenuGroup(
              children: [
                for (final u in shown)
                  InkWell(
                    onTap: () => _open(u),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Avatar(name: u.name, size: 40),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                Text('${u.phone} · ${u.tier}',
                                    style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(u.status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              u.status,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(u.status)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- approvals

class _Approval {
  const _Approval(this.icon, this.title, this.detail);

  final IconData icon;
  final String title;
  final String detail;
}

/// Requests waiting for a decision. Approve or reject removes them from the list.
class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  final _items = <_Approval>[
    const _Approval(Icons.badge_outlined, 'KYC · Ngozi Eze', 'National ID submitted today, 09:12'),
    const _Approval(Icons.badge_outlined, 'KYC · Funke Bello', 'Driver’s licence submitted yesterday'),
    const _Approval(Icons.desktop_windows_outlined, 'POS terminal · Ada Stores', 'Requested 1 terminal, Ikeja branch'),
    const _Approval(Icons.trending_up, 'Limit increase · Emeka Nwosu', 'Tier 3 daily limit to ₦10,000,000'),
  ];

  void _decide(_Approval a, bool approve) {
    // TODO: send the decision to your admin API.
    setState(() => _items.remove(a));
    showMessage(context, '${a.title} ${approve ? 'approved' : 'rejected'}');
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Approvals',
      child: _items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    AnimatedCheck(size: 64),
                    SizedBox(height: 8),
                    Text('All caught up', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('No requests are waiting.', style: TextStyle(color: TpColors.muted)),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                for (final a in List.of(_items))
                  Container(
                    key: ValueKey(a.title),
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: TpShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBox(icon: a.icon, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  Text(a.detail, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _decide(a, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: TpColors.danger,
                                  side: const BorderSide(color: Color(0xFFF3C9C9)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _decide(a, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: TpColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
