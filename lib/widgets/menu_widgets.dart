import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';
import 'motion.dart';

/// Round white back button used on plain pages.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, this.icon = Icons.chevron_left, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.9,
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: const Color(0x2214233F),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap ?? () => Navigator.maybePop(context),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: TpColors.navy),
          ),
        ),
      ),
    );
  }
}

/// Page with a back button, a title and a scrolling body. For screens that
/// have no step buttons (Profile pages, Support, Admin).
class PlainScaffold extends StatelessWidget {
  const PlainScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.bottom,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  /// Optional fixed area under the scrolling body (a button or a text box).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TpColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  const RoundBackButton(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: FadeSlideIn(offset: 14, child: child),
              ),
            ),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// One tappable row: icon tile, title, optional subtitle and a chevron.
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.tone,
  });

  /// Colour family for the icon tile.
  final TpTone? tone;

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Replaces the chevron (for a Switch, a badge, ...).
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? TpColors.danger : TpColors.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconBox(icon: icon, size: 40, color: color, tone: danger ? null : tone),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: danger ? TpColors.danger : TpColors.navy,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right, color: TpColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Small caps label above a white card of [MenuTile]s with dividers.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, this.label, required this.children});

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 0, 8),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: TpColors.muted,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: TpShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: Colors.white,
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 68, color: TpColors.border),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Initials in a circle, e.g. "AO" for "Aminata Kamara".
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 56, this.light = false});

  final String name;
  final double size;

  /// White circle with blue letters, for use on the blue profile card.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: light ? null : TpGradients.primary,
        color: light ? Colors.white : null,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: light ? TpColors.primary : Colors.white,
        ),
      ),
    );
  }
}
