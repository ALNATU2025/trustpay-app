import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/debounce.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/api_builder.dart';
import '../../widgets/common.dart';
import '../../widgets/flow_widgets.dart';
import '../../widgets/menu_widgets.dart';
import '../../widgets/motion.dart';
import 'admin_money_screens.dart';

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Compact number for chart labels: 950, 12.5k, 1.2M.
String _short(double v) {
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (v >= 1e5) return '${(v / 1e3).toStringAsFixed(0)}k';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}

/// Staff overview: volume, key numbers, a weekly chart and shortcuts. Only staff can open it.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = appState.user;
    if (me == null || !me.isStaff) {
      return const PlainScaffold(
        title: 'Admin console',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: Text(
              'This area is for TrustPay staff only.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TpColors.muted),
            ),
          ),
        ),
      );
    }
    return PlainScaffold(
      title: 'Admin console',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: TpColors.tint, borderRadius: BorderRadius.circular(20)),
        child: Text(
          me.isAdmin ? 'ADMIN' : 'SUPPORT',
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: TpColors.primary),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ApiBuilder<AdminStats>(
            load: api.adminStats,
            builder: (context, stats, reload) => _Stats(stats: stats),
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
                icon: Icons.receipt_long_outlined,
                title: 'All transactions',
                subtitle: 'Every payment, filter and review',
                onTap: () => openScreen(context, const AdminTransactionsScreen()),
              ),
              MenuTile(
                icon: Icons.storefront_outlined,
                title: 'Merchants & POS',
                subtitle: 'Terminals, POS payments and payouts',
                onTap: () => openScreen(context, const AdminPosScreen()),
              ),
              MenuTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Tiers & limits',
                subtitle: 'Daily and balance limits for each tier',
                onTap: () => openScreen(context, const AdminTiersScreen()),
              ),
              MenuTile(
                icon: Icons.fact_check_outlined,
                title: 'Approvals',
                subtitle: 'KYC, POS terminals, limits',
                onTap: () => openScreen(context, const AdminApprovalsScreen()),
              ),
              MenuTile(
                icon: Icons.support_agent_outlined,
                title: 'Support tickets',
                subtitle: 'Reply to customers and close requests',
                onTap: () => openScreen(context, const AdminTicketsScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final up = stats.changePct >= 0;
    final maxWeek = stats.week.fold<double>(0, (m, w) => math.max(m, w.$2));
    final scale = maxWeek > 0 ? maxWeek : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: TpGradients.premium,
            borderRadius: BorderRadius.circular(24),
            boxShadow: TpShadows.glow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's volume", style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 6),
              CountUpText(
                value: stats.volumeToday,
                format: (v) => formatLeone(v, decimals: 0),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${up ? '▲' : '▼'} ${stats.changePct.abs().toStringAsFixed(1)}% vs yesterday '
                  '(${formatLeone(stats.volumeYesterday, decimals: 0)})',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _Kpi(icon: Icons.people_outline, label: 'Total users', value: formatInt(stats.totalUsers))),
            const SizedBox(width: 12),
            Expanded(child: _Kpi(icon: Icons.bolt_outlined, label: 'Active today', value: formatInt(stats.activeToday))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _Kpi(
                    icon: Icons.fact_check_outlined, label: 'Pending approvals', value: formatInt(stats.pendingApprovals))),
            const SizedBox(width: 12),
            Expanded(
                child: _Kpi(
                    icon: Icons.support_agent_outlined, label: 'Open tickets', value: formatInt(stats.openTickets))),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
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
              Text(
                stats.week.isEmpty
                    ? 'Leones per day'
                    : 'Leones per day · highest ${formatLeone(maxWeek, decimals: 0)}',
                style: const TextStyle(fontSize: 12, color: TpColors.muted),
              ),
              const SizedBox(height: 16),
              if (stats.week.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No activity yet.', style: TextStyle(color: TpColors.muted)),
                )
              else
                SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < stats.week.length; i++)
                        Expanded(
                          child: _Bar(
                            label: stats.week[i].$1,
                            value: stats.week[i].$2,
                            max: scale,
                            index: i,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
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
    return Tooltip(
      message: '$label: ${formatLeone(value)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(_short(value), style: const TextStyle(fontSize: 10, color: TpColors.muted)),
          const SizedBox(height: 4),
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
      ),
    );
  }
}

// ------------------------------------------------------------------ users

Color _statusColor(String status) => switch (status) {
      'active' => TpColors.green,
      'suspended' => TpColors.danger,
      _ => const Color(0xFFB7791F),
    };

/// Searchable user list. Tap a user to see details; admins can suspend or reactivate.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _debounce = Debouncer();
  final _users = <AdminUser>[];
  String _query = '';
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final round = ++_round;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final res = await api.adminUsers(q: _query.trim().isEmpty ? null : _query.trim(), page: 1);
      if (!mounted || round != _round) return;
      setState(() {
        _users
          ..clear()
          ..addAll(res.items);
        _page = res.page;
        _hasMore = res.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || round != _round) return;
      setState(() {
        _error = errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _more() async {
    if (_loadingMore || !_hasMore) return;
    final round = _round;
    setState(() => _loadingMore = true);
    try {
      final res = await api.adminUsers(q: _query.trim().isEmpty ? null : _query.trim(), page: _page + 1);
      if (!mounted || round != _round) return;
      setState(() {
        _users.addAll(res.items);
        _page = res.page;
        _hasMore = res.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || round != _round) return;
      setState(() => _loadingMore = false);
      showMessage(context, errorMessage(e));
    }
  }

  Future<void> _changeStatus(AdminUser u) async {
    final suspend = u.status != 'suspended';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(suspend ? 'Suspend account?' : 'Reactivate account?'),
        content: Text(suspend
            ? '${u.name} will not be able to sign in or make payments until you reactivate the account.'
            : '${u.name} will be able to sign in and make payments again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(suspend ? 'Suspend' : 'Reactivate'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final updated = await api.setUserStatus(u.id, suspend ? 'suspended' : 'active');
      if (!mounted) return;
      setState(() {
        final i = _users.indexWhere((x) => x.id == u.id);
        if (i >= 0) _users[i] = _users[i].copyWith(status: updated.status);
      });
      showMessage(context, '${u.name} is now ${updated.status == 'suspended' ? 'suspended' : 'active'}');
    } catch (e) {
      if (!mounted) return;
      showMessage(context, errorMessage(e));
    }
  }

  void _open(AdminUser u) {
    final canChange = appState.me.isAdmin && u.status != 'pending_kyc';
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
            Text('${u.tier} · ${u.statusLabel}',
                style: TextStyle(fontWeight: FontWeight.w700, color: _statusColor(u.status))),
            const SizedBox(height: 20),
            if (u.status == 'pending_kyc')
              const InfoBanner(
                text: 'This user has not finished identity verification. Review it under Approvals.',
                icon: Icons.info_outline,
              )
            else if (canChange)
              PrimaryButton(
                label: u.status == 'suspended' ? 'Reactivate account' : 'Suspend account',
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _changeStatus(u);
                },
              ),
            if (u.status != 'pending_kyc') ...[
              const SizedBox(height: 8),
              SecondaryButton(
                label: 'Open profile · funding · transactions',
                onPressed: () {
                  Navigator.pop(sheetContext);
                  openScreen(context, AdminUserDetailScreen(userId: u.id));
                },
              ),
            ],
            const SizedBox(height: 8),
            SecondaryButton(label: 'Close', onPressed: () => Navigator.pop(sheetContext)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Users',
      child: Column(
        children: [
          TextField(
            onChanged: (v) {
              _query = v;
              _debounce.run(_load);
            },
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
          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator())
          else if (_error != null)
            ErrorRetry(message: _error!, onRetry: _load)
          else if (_users.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No users match your search.', style: TextStyle(color: TpColors.muted)),
            )
          else ...[
            MenuGroup(
              children: [
                for (final u in _users)
                  InkWell(
                    key: ValueKey(u.id),
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
                              u.statusLabel,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(u.status)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (_hasMore) ...[
              const SizedBox(height: 14),
              _loadingMore
                  ? const CircularProgressIndicator()
                  : SecondaryButton(label: 'Load more', onPressed: _more),
            ],
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- approvals

IconData _approvalIcon(String type) => switch (type) {
      'kyc' => Icons.badge_outlined,
      'pos' => Icons.desktop_windows_outlined,
      'limit' => Icons.trending_up,
      'tier' => Icons.workspace_premium_outlined,
      _ => Icons.fact_check_outlined,
    };

/// Asks for the reason when a request is rejected.
class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();
  String? _problem;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject this request?'),
      content: TextField(
        controller: _reason,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Reason (the customer may see this)',
          errorText: _problem,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final text = _reason.text.trim();
            if (text.isEmpty) {
              setState(() => _problem = 'Please give a reason');
              return;
            }
            Navigator.pop(context, text);
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

/// Requests waiting for a decision. After a decision the list is loaded again.
class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  final _busy = <String>{};

  Future<void> _decide(Approval a, bool approve, Future<void> Function() reload) async {
    String? reason;
    if (!approve) {
      reason = await showDialog<String>(context: context, builder: (_) => const _ReasonDialog());
      if (reason == null || !mounted) return;
    }
    setState(() => _busy.add(a.id));
    try {
      await api.decideApproval(a.id, approve: approve, reason: reason);
      if (!mounted) return;
      showMessage(context, '${a.title} ${approve ? 'approved' : 'rejected'}');
      await reload();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy.remove(a.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Approvals',
      child: ApiBuilder<List<Approval>>(
        load: api.adminApprovals,
        builder: (context, items, reload) {
          if (items.isEmpty) {
            return const Padding(
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
            );
          }
          return Column(
            children: [
              for (final a in items)
                Container(
                  key: ValueKey(a.id),
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
                          IconBox(icon: _approvalIcon(a.type), size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(a.detail, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                                if (a.createdAt != null)
                                  Text(formatShortDateTime(a.createdAt!),
                                      style: const TextStyle(fontSize: 12, color: TpColors.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (a.documentId.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => openScreen(context, AdminDocumentScreen(documentId: a.documentId)),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('View document'),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _busy.contains(a.id) ? null : () => _decide(a, false, reload),
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
                              onPressed: _busy.contains(a.id) ? null : () => _decide(a, true, reload),
                              style: FilledButton.styleFrom(
                                backgroundColor: TpColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _busy.contains(a.id)
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- tickets

/// Customer support tickets, open or closed.
class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final status = _tab == 0 ? 'open' : 'closed';
    return PlainScaffold(
      title: 'Support tickets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedTabs(labels: const ['Open', 'Closed'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 16),
          ApiBuilder<PagedList<Ticket>>(
            key: ValueKey(status),
            load: () => api.adminTickets(status: status),
            builder: (context, page, reload) {
              if (page.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No $status tickets.', style: const TextStyle(color: TpColors.muted)),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MenuGroup(
                    children: [
                      for (final t in page.items)
                        MenuTile(
                          icon: t.isOpen ? Icons.mark_unread_chat_alt_outlined : Icons.check_circle_outline,
                          title: t.topic.isNotEmpty ? t.topic : 'Ticket',
                          subtitle: [
                            [
                              t.reference,
                              if (t.customer != null) t.customer!,
                            ].join(' · '),
                            if (t.lastMessage != null) t.lastMessage!,
                          ].join('\n'),
                          onTap: () async {
                            await openScreen(context, AdminTicketThreadScreen(ticketId: t.id));
                            await reload();
                          },
                        ),
                    ],
                  ),
                  if (page.hasMore)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Showing the latest tickets only.',
                          style: TextStyle(fontSize: 12, color: TpColors.muted)),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A ticket's conversation for staff, with a reply box and a close button.
class AdminTicketThreadScreen extends StatefulWidget {
  const AdminTicketThreadScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<AdminTicketThreadScreen> createState() => _AdminTicketThreadScreenState();
}

class _AdminTicketThreadScreenState extends State<AdminTicketThreadScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  TicketThread? _thread;
  final _messages = <ChatMessage>[];
  String? _loadError;
  bool _loading = true;
  bool _sending = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final thread = await api.adminTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _thread = thread;
        _messages
          ..clear()
          ..addAll(thread.messages);
        _loading = false;
      });
      _toEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = errorMessage(e);
        _loading = false;
      });
    }
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _reply() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final m = await api.adminReply(widget.ticketId, text);
      if (!mounted) return;
      setState(() {
        _messages.add(m);
        _sending = false;
      });
      _controller.clear();
      _toEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showMessage(context, errorMessage(e));
    }
  }

  Future<void> _close() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close this ticket?'),
        content: const Text('The customer will not be able to reply to a closed ticket.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Close ticket')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _closing = true);
    try {
      await api.adminCloseTicket(widget.ticketId);
      if (!mounted) return;
      showMessage(context, 'Ticket closed');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _closing = false);
      showMessage(context, errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final open = thread?.ticket.isOpen ?? false;
    final title = thread == null || thread.ticket.topic.isEmpty ? 'Ticket' : thread.ticket.topic;
    final sub = thread == null
        ? ''
        : [
            thread.ticket.reference,
            if (thread.ticket.customer != null) thread.ticket.customer!,
            _capitalize(thread.ticket.status),
          ].where((s) => s.isNotEmpty).join(' · ');

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (thread == null) {
      body = ErrorRetry(message: _loadError ?? 'Could not load the ticket.', onRetry: _load);
    } else {
      body = ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        itemCount: _messages.length,
        itemBuilder: (context, i) {
          final m = _messages[i];
          final staff = !m.fromUser;
          return Align(
            alignment: staff ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
              decoration: BoxDecoration(
                color: staff ? TpColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.text,
                      style: TextStyle(fontSize: 15, height: 1.35, color: staff ? Colors.white : TpColors.navy)),
                  const SizedBox(height: 4),
                  Text(formatShortDateTime(m.createdAt),
                      style: TextStyle(fontSize: 11, color: staff ? Colors.white70 : TpColors.muted)),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: TpColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  const RoundBackButton(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        if (sub.isNotEmpty)
                          Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                      ],
                    ),
                  ),
                  if (thread != null && open)
                    TextButton(
                      onPressed: _closing ? null : _close,
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            Expanded(child: body),
            if (thread != null && open)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_sending,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _reply(),
                        decoration: tpDecoration(hint: 'Write a reply'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: TpColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _sending ? null : _reply,
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (thread != null)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text('This ticket is closed.', style: TextStyle(color: TpColors.muted)),
              ),
          ],
        ),
      ),
    );
  }
}
