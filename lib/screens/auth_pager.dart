import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/common.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Login and Sign up side by side. Drag sideways, or tap "Create account" /
/// "Log in", and the pages swipe past each other.
class AuthPager extends StatefulWidget {
  const AuthPager({super.key, this.initialPage = 0});

  /// 0 shows Login, 1 shows Sign up.
  final int initialPage;

  @override
  State<AuthPager> createState() => _AuthPagerState();
}

class _AuthPagerState extends State<AuthPager> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _controller = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) {
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        PageView(
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (i) {
            FocusManager.instance.primaryFocus?.unfocus();
            HapticFeedback.selectionClick();
            setState(() => _page = i);
          },
          children: [
            _KeepAlive(child: LoginScreen(onSwitch: () => _go(1))),
            _KeepAlive(child: SignUpScreen(onSwitch: () => _go(0))),
          ],
        ),
        // Two dots under the header show which page you are on.
        Positioned(
          top: top + 70,
          left: 0,
          right: 0,
          child: IgnorePointer(child: PageDots(count: 2, index: _page)),
        ),
      ],
    );
  }
}

/// Keeps a page's typed text when you swipe away and back.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
