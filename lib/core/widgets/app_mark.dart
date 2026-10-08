import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// The SnapLio mark drawn in code (matches the launcher icon): a gradient tile
/// with two stacked "screenshot" cards.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 88, this.glow = 0});

  final double size;

  /// 0..1 — strength of the soft brand glow behind the mark.
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: Brand.gradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          if (glow > 0)
            BoxShadow(
              color: Brand.violet.withValues(alpha: 0.55 * glow),
              blurRadius: size * 0.7 * glow,
              spreadRadius: size * 0.05 * glow,
            ),
        ],
      ),
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final u = s.width / 100;
    final c = Offset(s.width / 2, s.height / 2);
    RRect card(Offset center) => RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 40 * u, height: 54 * u),
          Radius.circular(7 * u),
        );
    canvas.drawRRect(card(c + Offset(7 * u, -6 * u)), Paint()..color = Colors.white.withValues(alpha: 0.45));
    final front = c + Offset(-5 * u, 5 * u);
    canvas.drawRRect(card(front), Paint()..color = Colors.white);
    final line = Paint()..color = Brand.violet;
    for (final (dy, hw) in const [(-12.0, 12.0), (-3.0, 9.0), (6.0, 12.0)]) {
      final left = front.dx - 12 * u;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, front.dy + dy * u - 2.2 * u, hw * 2 * u, 4.4 * u),
          Radius.circular(2.2 * u),
        ),
        line,
      );
    }
    canvas.drawCircle(c + Offset(7 * u, 20 * u), 3.6 * u, Paint()..color = Brand.sky);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
