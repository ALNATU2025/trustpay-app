import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Deep blue panel with fine arcs and a soft highlight, like a premium bank
/// card. Use it for the balance card and other hero blocks.
class PremiumPanel extends StatelessWidget {
  const PremiumPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        gradient: TpGradients.premium,
        borderRadius: shape,
        boxShadow: TpShadows.glow,
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: CustomPaint(
          painter: _ArcsPainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _ArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 1.02, -size.height * 0.05);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.07);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(center, 70 + i * 46.0, line);
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.16), Colors.white.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.55));
    canvas.drawCircle(center, size.width * 0.55, glow);
  }

  @override
  bool shouldRepaint(_ArcsPainter old) => false;
}

/// Small gold "card chip" used as a premium detail.
class GoldChip extends StatelessWidget {
  const GoldChip({super.key, this.width = 36, this.height = 26});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE08A), Color(0xFFD9A441)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomPaint(painter: _ChipLines()),
    );
  }
}

class _ChipLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), p);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), p);
  }

  @override
  bool shouldRepaint(_ChipLines old) => false;
}
