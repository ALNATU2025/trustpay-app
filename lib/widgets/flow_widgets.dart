import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';
import 'motion.dart';

/// White card of "label ........ value" rows.
class DetailsCard extends StatelessWidget {
  const DetailsCard({super.key, required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: TpShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(fontSize: 14, color: TpColors.muted),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Big coloured panel with a label, a large value and an optional widget below.
class AmountBanner extends StatelessWidget {
  const AmountBanner({
    super.key,
    required this.label,
    required this.value,
    this.background = TpColors.primary,
    this.labelColor = Colors.white70,
    this.valueColor = Colors.white,
    this.valueSize = 32,
    this.center = false,
    this.child,
  });

  final String label;
  final String value;
  final Color background;
  final Color labelColor;
  final Color valueColor;
  final double valueSize;
  final bool center;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background == TpColors.primary ? null : background,
        gradient: background == TpColors.primary ? TpGradients.primary : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: background == TpColors.primary ? TpShadows.glow : null,
      ),
      child: Column(
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 14),
            child!,
          ],
        ],
      ),
    );
  }
}

class SuccessBadge extends StatelessWidget {
  const SuccessBadge({super.key});

  @override
  Widget build(BuildContext context) => const AnimatedCheck(size: 72);
}

/// Big centred result block: badge, headline and a muted line.
class ResultHeader extends StatelessWidget {
  const ResultHeader({super.key, required this.headline, required this.detail});

  final String headline;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SuccessBadge(),
        const SizedBox(height: 16),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: TpColors.muted, height: 1.4),
        ),
      ],
    );
  }
}

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    this.onChanged,
  });

  final List<String> labels;
  final int index;

  /// Null makes the tabs read-only.
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TpColors.tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onChanged == null ? null : () => onChanged!(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: i == index ? TpColors.primary : TpColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Selectable box with an optional icon (categories, networks).
class ChoiceBox extends StatelessWidget {
  const ChoiceBox({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? TpColors.primary : TpColors.navy;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            height: icon != null ? 84 : 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? TpColors.primary : TpColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: TpColors.primary, size: 26),
                  const SizedBox(height: 8),
                ],
                Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tile with icon, title, subtitle and a check (selected) or chevron.
class SelectTile extends StatelessWidget {
  const SelectTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? TpColors.primary : TpColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                IconBox(icon: icon, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 13, height: 1.3, color: TpColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_outline : Icons.chevron_right,
                  color: TpColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TpDropdown extends StatelessWidget {
  const TpDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: TpColors.primary),
          decoration: tpDecoration(),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

/// White rounded button with a blue label (Copy, Show details, Share...).
class TpWhiteButton extends StatelessWidget {
  const TpWhiteButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: TpColors.primary),
                const SizedBox(width: 8),
              ],
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

/// Plain white card with padding.
class WhiteCard extends StatelessWidget {
  const WhiteCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

/// Read-only PIN boxes, filled by [NumberKeypad].
class PinDisplay extends StatelessWidget {
  const PinDisplay({super.key, required this.length, required this.value});

  final int length;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: i <= value.length ? TpColors.primary : TpColors.border,
                  width: i <= value.length ? 1.5 : 1,
                ),
              ),
              child: Text(
                i < value.length ? '•' : '',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class NumberKeypad extends StatelessWidget {
  const NumberKeypad({super.key, required this.onDigit, required this.onDelete});

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  Widget _key({required Widget child, VoidCallback? onTap, String? label}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Semantics(
          button: onTap != null,
          label: label,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: SizedBox(height: 44, child: Center(child: child)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _digit(String d) => _key(
        onTap: () => onDigit(d),
        child: Text(d, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [_digit('1'), _digit('2'), _digit('3')]),
        Row(children: [_digit('4'), _digit('5'), _digit('6')]),
        Row(children: [_digit('7'), _digit('8'), _digit('9')]),
        Row(
          children: [
            _key(child: const SizedBox.shrink()),
            _digit('0'),
            _key(
              onTap: onDelete,
              label: 'Delete',
              child: const Icon(Icons.backspace_outlined, color: TpColors.navy),
            ),
          ],
        ),
      ],
    );
  }
}

/// Icon + title/subtitle + trailing text, with a divider underneath.
class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.trailingColor = TpColors.navy,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                IconBox(icon: icon, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: TpColors.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trailing,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: trailingColor),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: TpColors.border),
      ],
    );
  }
}

/// Small dark terminal drawing used on the POS screens.
class TerminalIcon extends StatelessWidget {
  const TerminalIcon({super.key, this.width = 84, this.height = 120});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1F3F),
        borderRadius: BorderRadius.circular(width * 0.2),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE9F0FE),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6EE7B7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
