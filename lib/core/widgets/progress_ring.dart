import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Gradient progress ring with a soft rotating sheen while [active].
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 220,
    this.stroke = 14,
    this.active = true,
    this.child,
  });

  final double progress;
  final double size;
  final double stroke;
  final bool active;
  final Widget? child;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  void _sync() {
    if (widget.active && !context.reduceMotion) {
      if (!_sheen.isAnimating) _sheen.repeat();
    } else {
      _sheen.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = context.colors.border;
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, p, child) => AnimatedBuilder(
          animation: _sheen,
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: _RingPainter(progress: p, stroke: widget.stroke, track: track, sheen: widget.active ? _sheen.value : -1),
            child: SizedBox.square(dimension: widget.size, child: Center(child: child)),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.stroke, required this.track, required this.sheen});

  final double progress;
  final double stroke;
  final Color track;
  final double sheen;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track);

    if (progress <= 0) return;
    final sweep = math.pi * 2 * progress;
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: const [Brand.violet, Brand.sky, Brand.violet],
      transform: const GradientRotation(-math.pi / 2),
    );
    // Glow
    canvas.drawArc(r, -math.pi / 2, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = Colors.white.withValues(alpha: 0.5));
    canvas.drawArc(r, -math.pi / 2, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect));

    if (sheen >= 0) {
      final a = -math.pi / 2 + sweep * sheen;
      canvas.drawArc(r, a, 0.35, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35));
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.sheen != sheen || old.track != track;
}

/// One-shot burst of confetti-like particles.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.colors, this.count = 70});
  final List<Color> colors;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rand = math.Random();
    _particles = List.generate(widget.count, (i) {
      final angle = rand.nextDouble() * math.pi * 2;
      final speed = 180 + rand.nextDouble() * 260;
      return _Particle(
        velocity: Offset(math.cos(angle), math.sin(angle) - 0.6) * speed,
        color: widget.colors[i % widget.colors.length],
        size: 3 + rand.nextDouble() * 4,
        spin: rand.nextDouble() * 6,
        rect: rand.nextBool(),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!context.reduceMotion && !_c.isAnimating && _c.value == 0) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_particles, _c.value)),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({required this.velocity, required this.color, required this.size, required this.spin, required this.rect});
  final Offset velocity;
  final Color color;
  final double size;
  final double spin;
  final bool rect;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);
  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final secs = t * 1.8;
    final paint = Paint();
    for (final p in particles) {
      final pos = center + p.velocity * secs * (1 - t * 0.35) + Offset(0, 220 * secs * secs);
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * secs * 3);
      if (p.rect) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size * 1.8, height: p.size), const Radius.circular(1.5)), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
