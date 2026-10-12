import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

/// The small "Illustrative data · All amounts in NGN" line from the designs.
/// Set to false before release.
const bool kShowIllustrativeNote = true;

class TpLogo extends StatelessWidget {
  const TpLogo({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/trustpay_logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'TrustPay',
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(16);
    return PressScale(
      enabled: enabled,
      scale: 0.97,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: TpGradients.primary,
            borderRadius: radius,
            boxShadow: enabled ? TpShadows.glow : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      onPressed!();
                    }
                  : null,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 10),
                      Icon(trailingIcon, size: 20, color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: onPressed != null,
      scale: 0.97,
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: TpColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: TpColors.border),
            ),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          onPressed: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: Text(label),
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.verified_user_outlined,
    this.background = TpColors.tint,
    this.accent = TpColors.primary,
    this.textColor = TpColors.navy,
  });

  final String text;
  final IconData icon;
  final Color background;
  final Color accent;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.35, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class IconBox extends StatelessWidget {
  const IconBox({super.key, required this.icon, this.size = 44, this.color = TpColors.primary});

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2F7FF), Color(0xFFDCE8FD)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? TpColors.primary : TpColors.dot,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class IllustrativeNote extends StatelessWidget {
  const IllustrativeNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: Center(
        child: Text(
          'Illustrative data · All amounts in NGN',
          style: TextStyle(fontSize: 12, color: TpColors.muted),
        ),
      ),
    );
  }
}

/// Back button + centred logo + Help link.
class FlowHeader extends StatelessWidget {
  const FlowHeader({
    super.key,
    this.showBack = true,
    this.onBack,
    this.onHelp,
    this.rightLabel = 'Help',
  });

  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Align(
              alignment: Alignment.centerLeft,
              child: showBack
                  ? PressScale(
                      scale: 0.9,
                      child: Material(
                        color: Colors.white,
                        elevation: 1.5,
                        shadowColor: const Color(0x2214233F),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onBack ?? () => Navigator.maybePop(context),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.chevron_left, color: TpColors.navy),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const Expanded(child: Center(child: TpLogo(height: 52))),
          SizedBox(
            width: 72,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onHelp ?? () {},
                style: TextButton.styleFrom(
                  foregroundColor: TpColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 40),
                ),
                child: Text(
                  rightLabel,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration tpDecoration({String? hint, Widget? suffix, String? prefixText}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: TpColors.muted),
    counterText: '',
    filled: true,
    fillColor: Colors.white,
    suffixIcon: suffix,
    prefixText: prefixText,
    prefixStyle: const TextStyle(fontSize: 15, color: TpColors.navy),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(TpColors.border),
    enabledBorder: border(TpColors.border),
    focusedBorder: border(TpColors.primary, 1.5),
    errorBorder: border(TpColors.danger),
    focusedErrorBorder: border(TpColors.danger, 1.5),
  );
}

class TpField extends StatefulWidget {
  const TpField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.digitsOnly = false,
    this.allowDecimal = false,
    this.prefixText,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final bool digitsOnly;
  final bool allowDecimal;
  final String? prefixText;
  final ValueChanged<String>? onChanged;

  @override
  State<TpField> createState() => _TpFieldState();
}

class _TpFieldState extends State<TpField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final Widget? suffix = widget.isPassword
        ? IconButton(
            tooltip: _obscure ? 'Show' : 'Hide',
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: TpColors.primary,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          )
        : widget.suffix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          maxLength: widget.maxLength,
          inputFormatters: widget.digitsOnly
              ? [FilteringTextInputFormatter.digitsOnly]
              : widget.allowDecimal
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                  : null,
          style: const TextStyle(fontSize: 15),
          decoration: tpDecoration(
            hint: widget.hint,
            suffix: suffix,
            prefixText: widget.prefixText,
          ),
        ),
      ],
    );
  }
}
