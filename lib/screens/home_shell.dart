import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import '../utils/nav.dart';
import '../utils/session.dart';
import '../widgets/api_builder.dart';
import '../widgets/app_drawer.dart';
import 'account/profile_tab.dart';
import 'admin/admin_screens.dart';
import 'support/support_screen.dart';
import 'flows/flows.dart';
import 'home_tab.dart';
import 'services_tab.dart';

/// Loads the customer and the server's catalog, then shows the app. Every screen inside can
/// rely on `appState.me` and `appState.cat` being present.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    appNotifications.start();
  }

  @override
  void dispose() {
    appNotifications.stop();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        appState.loadCatalog(),
        appState.refreshUser(),
      ]);
      if (appState.user == null && apiClient.hasToken) {
        throw const ApiException(0, 'We could not load your account. Check your connection and try again.');
      }
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: TpColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || appState.user == null || appState.catalog == null) {
      return Scaffold(
        backgroundColor: TpColors.background,
        body: SafeArea(
          child: ErrorRetry(
            message: _error == null ? 'We could not load your account.' : errorMessage(_error!),
            onRetry: _load,
          ),
        ),
      );
    }
    return const _ShellBody();
  }
}

class _ShellBody extends StatefulWidget {
  const _ShellBody();

  @override
  State<_ShellBody> createState() => _ShellBodyState();
}

class _ShellBodyState extends State<_ShellBody> {
  int _tab = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _go(int i) => setState(() => _tab = i);

  /// Runs after the drawer has closed.
  void _onDrawer(DrawerDest dest) {
    switch (dest) {
      case DrawerDest.home:
        _go(0);
      case DrawerDest.services:
        _go(1);
      case DrawerDest.pos:
        _go(2);
      case DrawerDest.account:
        _go(3);
      case DrawerDest.transactions:
        openScreen(context, const TransactionHistoryScreen());
      case DrawerDest.support:
        openScreen(context, const SupportScreen());
      case DrawerDest.admin:
        openScreen(context, const AdminDashboardScreen());
      case DrawerDest.logout:
        confirmLogout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Back on Services, POS or Account returns to Home before leaving the app.
    return PopScope(
      canPop: _tab == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final scaffold = _scaffoldKey.currentState;
        if (scaffold != null && scaffold.isDrawerOpen) {
          scaffold.closeDrawer();
        } else {
          _go(0);
        }
      },
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: TpColors.background,
      drawer: AppDrawer(currentTab: _tab, onSelect: _onDrawer),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            HomeTab(onOpenTab: _go),
            ServicesTab(onOpenTab: _go),
            const PosTab(),
            ProfileTab(onOpenTab: _go),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(index: _tab, onTap: _go),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Services'),
    (Icons.desktop_windows_outlined, Icons.desktop_windows_rounded, 'POS'),
    (Icons.person_outline, Icons.person_rounded, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14233F).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    outlined: _items[i].$1,
                    filled: _items[i].$2,
                    label: _items[i].$3,
                    selected: i == index,
                    onTap: () {
                      if (i != index) HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.outlined,
    required this.filled,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData outlined;
  final IconData filled;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? TpColors.primary : TpColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: selected ? 60 : 36,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? TpColors.tint : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: Icon(selected ? filled : outlined, size: 24, color: color),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
