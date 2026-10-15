import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/notification_service.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/menu_widgets.dart';

IconData _iconFor(String type) => switch (type) {
      'funding' => Icons.south_west,
      'payment' => Icons.north_east,
      'signup' || 'welcome' => Icons.person_add_alt_1_outlined,
      'approval' => Icons.fact_check_outlined,
      'maintenance' => Icons.build_circle_outlined,
      'feature' => Icons.auto_awesome_outlined,
      'message' => Icons.chat_bubble_outline,
      'alert' => Icons.warning_amber_rounded,
      _ => Icons.notifications_none,
    };

/// The inbox: everything TrustPay told you (money received, approvals, messages, updates).
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _items = <Map<String, dynamic>>[];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await api.notifications(page: 1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(r.items);
        _page = r.page;
        _hasMore = r.hasMore;
        _loading = false;
      });
      // Opening the inbox counts as reading it.
      api.markNotificationsRead().then((_) => appNotifications.markedRead()).catchError((_) {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _more() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final r = await api.notifications(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(r.items);
        _page = r.page;
        _hasMore = r.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
        showMessage(context, errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlainScaffold(
      title: 'Notifications',
      child: _loading
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator())
          : _error != null
              ? Column(children: [Text(_error!, style: const TextStyle(color: TpColors.danger)), TextButton(onPressed: _load, child: const Text('Try again'))])
              : _items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text('No notifications yet.', style: TextStyle(color: TpColors.muted))),
                    )
                  : Column(
                      children: [
                        MenuGroup(
                          children: [
                            for (final n in _items)
                              Padding(
                                key: ValueKey(asStr(n['id'])),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(_iconFor(asStr(n['type'])), color: TpColors.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(asStr(n['title']), style: TextStyle(fontSize: 15, fontWeight: n['read'] == true ? FontWeight.w600 : FontWeight.w800)),
                                          if (asStr(n['body']).isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(asStr(n['body']), style: const TextStyle(fontSize: 13.5, color: TpColors.muted, height: 1.3)),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            tryParseDate(n['createdAt']) == null ? '' : formatShortDateTime(tryParseDate(n['createdAt'])!.toLocal()),
                                            style: const TextStyle(fontSize: 12, color: TpColors.muted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (n['read'] != true)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8, top: 4),
                                        child: CircleAvatar(radius: 4, backgroundColor: TpColors.primary),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (_hasMore) ...[
                          const SizedBox(height: 12),
                          _loadingMore ? const CircularProgressIndicator() : OutlinedButton(onPressed: _more, child: const Text('Load more')),
                        ],
                      ],
                    ),
    );
  }
}
