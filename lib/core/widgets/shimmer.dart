import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Lightweight shimmer: one shared animation per box, disabled when the user
/// turned animations off.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.radius = 0, this.width, this.height});

  final double radius;
  final double? width;
  final double? height;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = c.surfaceElevated;
    final hi = context.isDark ? const Color(0xFF282833) : const Color(0xFFEDEDF2);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 - 0.5;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 2, -0.3),
                end: Alignment(1 + t * 2, 0.3),
                colors: [base, hi, base],
                stops: const [0.25, 0.5, 0.75],
              ),
            ),
          );
        },
      ),
    );
  }
}
