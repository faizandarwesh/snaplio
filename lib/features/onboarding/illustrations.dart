import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../domain/models.dart';

/// Shared looping controller for an onboarding illustration. Runs only while
/// its page is active, and shows the final frame when animations are disabled.
abstract class _LoopingArtState<T extends StatefulWidget> extends State<T> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: loop);

  Duration get loop;
  bool get active;

  /// Value used when reduce-motion is on.
  double get staticValue => 0.7;

  void _sync() {
    if (context.reduceMotion) {
      c.value = staticValue;
      c.stop();
    } else if (active) {
      if (!c.isAnimating) c.repeat();
    } else {
      c.stop();
      c.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  double interval(double t, double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
}

/// A tiny stylised screenshot.
class _MiniShot extends StatelessWidget {
  const _MiniShot({
    required this.accent,
    this.width = 92,
    this.height = 150,
    this.lines = const [],
    this.highlighted = 0,
  });

  final Color accent;
  final double width;
  final double height;
  final List<String> lines;
  final double highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color.lerp(c.border, Brand.violet, highlighted)!,
          width: 1 + highlighted,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.08), blurRadius: 18, offset: const Offset(0, 8)),
          if (highlighted > 0) BoxShadow(color: Brand.violet.withValues(alpha: 0.45 * highlighted), blurRadius: 28),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 10, width: width * 0.45, decoration: BoxDecoration(color: accent.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          if (lines.isEmpty)
            for (final w in const [0.9, 0.7, 0.8, 0.5])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(height: 6, width: (width - 16) * w, decoration: BoxDecoration(color: c.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(3))),
              )
          else
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(l, maxLines: 1, overflow: TextOverflow.clip, softWrap: false, style: context.text.labelSmall?.copyWith(fontSize: 9, color: c.textPrimary)),
              ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- 1. Find

class FindAnythingArt extends StatefulWidget {
  const FindAnythingArt({super.key, required this.active});
  final bool active;
  @override
  State<FindAnythingArt> createState() => _FindAnythingArtState();
}

class _FindAnythingArtState extends _LoopingArtState<FindAnythingArt> {
  @override
  Duration get loop => const Duration(milliseconds: 4200);
  @override
  bool get active => widget.active;

  static const _query = 'wifi password';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: this.c,
      builder: (context, _) {
        final t = this.c.value;
        final typed = (interval(t, 0.05, 0.45) * _query.length).round();
        final hl = interval(t, 0.48, 0.6, Curves.easeOutBack) * (1 - interval(t, 0.92, 1.0));
        final dim = interval(t, 0.48, 0.6) * (1 - interval(t, 0.92, 1.0));
        double float(int i) => math.sin((t + i * 0.27) * 2 * math.pi) * 5;

        Widget shot(int i, double dx, double dy, double angle, Color accent, {List<String> lines = const [], bool match = false}) {
          return Positioned(
            left: dx,
            top: dy + float(i),
            child: Transform.rotate(
              angle: angle * (1 - (match ? hl : 0)),
              child: Transform.scale(
                scale: match ? 1 + 0.1 * hl : 1,
                child: Opacity(
                  opacity: match ? 1 : 1 - 0.55 * dim,
                  child: _MiniShot(accent: accent, lines: lines, highlighted: match ? hl.clamp(0, 1) : 0),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              shot(0, 6, 92, -0.12, CategoryStyle.of(ScreenshotCategory.receipts).color),
              shot(2, 200, 100, 0.1, CategoryStyle.of(ScreenshotCategory.orders).color),
              shot(3, 58, 150, 0.06, CategoryStyle.of(ScreenshotCategory.chats).color),
              shot(4, 160, 160, -0.08, CategoryStyle.of(ScreenshotCategory.links).color),
              shot(1, 104, 96, 0.04, CategoryStyle.of(ScreenshotCategory.notes).color,
                  match: true, lines: const ['Home WiFi', 'Network: Home_5G', 'Password:', 'sunflower2026']),
              // Search bar
              Positioned(
                left: 20,
                right: 20,
                top: 10,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Color.lerp(c.border, Brand.violet, interval(t, 0.02, 0.1) * (1 - interval(t, 0.92, 1)))!),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.08), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 20, color: c.textSecondary),
                      const SizedBox(width: 10),
                      Text(_query.substring(0, typed), style: context.text.bodyLarge),
                      if ((t * 8).floor().isEven || typed < _query.length)
                        Container(width: 2, height: 18, margin: const EdgeInsets.only(left: 1), color: Brand.violet),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- 2. Act

class ActInOneTapArt extends StatefulWidget {
  const ActInOneTapArt({super.key, required this.active});
  final bool active;
  @override
  State<ActInOneTapArt> createState() => _ActInOneTapArtState();
}

class _ActInOneTapArtState extends _LoopingArtState<ActInOneTapArt> {
  @override
  Duration get loop => const Duration(milliseconds: 3800);
  @override
  bool get active => widget.active;

  static const _chips = [
    ('Open link', Icons.open_in_new_rounded, Color(0xFF6B9EF2)),
    ('Call', Icons.call_rounded, Color(0xFF4DBDB3)),
    ('WhatsApp', Icons.chat_rounded, Color(0xFF5BBF8A)),
    ('Copy OTP', Icons.copy_rounded, Color(0xFF9B87F5)),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: this.c,
      builder: (context, _) {
        final t = this.c.value;
        final out = 1 - interval(t, 0.9, 1.0);
        final underline = interval(t, 0.08, 0.25, Curves.easeOut) * out;

        Widget entity(String text, Color color) => Stack(
              children: [
                Text(text, style: context.text.bodyMedium?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600)),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(height: 2, width: text.length * 7.6 * underline, color: color),
                ),
              ],
            );

        return SizedBox(
          width: 300,
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.08), blurRadius: 30, offset: const Offset(0, 12))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(radius: 14, backgroundColor: Brand.sky.withValues(alpha: 0.25), child: const Text('A', style: TextStyle(fontWeight: FontWeight.w700, color: Brand.sky))),
                      const SizedBox(width: 8),
                      Text('Ali Khan', style: context.text.titleSmall),
                    ]),
                    const SizedBox(height: 12),
                    Text('Order is here 👉', style: context.text.bodyMedium),
                    entity('daraz.pk/order/7781', const Color(0xFF6B9EF2)),
                    const SizedBox(height: 6),
                    Text('Call me on', style: context.text.bodyMedium),
                    entity('0300-1234567', const Color(0xFF4DBDB3)),
                  ],
                ),
              ),
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < _chips.length; i++)
                    Transform.scale(
                      scale: interval(t, 0.22 + i * 0.09, 0.5 + i * 0.09, Curves.elasticOut) * out,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _chips[i].$3.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: _chips[i].$3.withValues(alpha: 0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_chips[i].$2, size: 14, color: _chips[i].$3),
                          const SizedBox(width: 6),
                          Text(_chips[i].$1, style: context.text.labelMedium?.copyWith(color: _chips[i].$3)),
                        ]),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------- 3. Clean

class CleanUpArt extends StatefulWidget {
  const CleanUpArt({super.key, required this.active});
  final bool active;
  @override
  State<CleanUpArt> createState() => _CleanUpArtState();
}

class _CleanUpArtState extends _LoopingArtState<CleanUpArt> {
  @override
  Duration get loop => const Duration(milliseconds: 4400);
  @override
  bool get active => widget.active;
  @override
  double get staticValue => 0.85;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accents = [
      CategoryStyle.of(ScreenshotCategory.otp).color,
      CategoryStyle.of(ScreenshotCategory.orders).color,
      CategoryStyle.of(ScreenshotCategory.images).color,
    ];
    return AnimatedBuilder(
      animation: this.c,
      builder: (context, _) {
        final t = this.c.value;
        final reset = 1 - interval(t, 0.94, 1.0);
        final dissolve = interval(t, 0.12, 0.5, Curves.easeIn);
        final fill = interval(t, 0.3, 0.8, Curves.easeOutCubic) * reset;
        final cardsBack = interval(t, 0.94, 1.0);

        return SizedBox(
          width: 300,
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 130,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _ParticlePainter(progress: dissolve * reset, colors: accents)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Opacity(
                              opacity: ((1 - dissolve) * reset + cardsBack).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 1 - 0.25 * dissolve * reset,
                                child: _MiniShot(accent: accents[i], width: 70, height: 116),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.lg),
              Container(
                width: 250,
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${(2.3 * fill).toStringAsFixed(1)} GB freed', style: context.text.titleLarge),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(children: [
                        Container(height: 10, color: c.border),
                        FractionallySizedBox(
                          widthFactor: 0.04 + 0.86 * fill,
                          child: Container(height: 10, decoration: const BoxDecoration(gradient: Brand.gradient)),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: c.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_rounded, size: 14, color: c.success),
                  const SizedBox(width: 6),
                  Text('Never leaves your phone', style: context.text.labelMedium?.copyWith(color: c.success)),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;
  static final _rand = math.Random(7);
  static final _seeds = List.generate(54, (_) => (_rand.nextDouble(), _rand.nextDouble(), _rand.nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final paint = Paint();
    for (var i = 0; i < _seeds.length; i++) {
      final card = i % 3;
      final (a, d, s) = _seeds[i];
      final origin = Offset(size.width / 2 + (card - 1) * 82.0, size.height / 2);
      final angle = a * 2 * math.pi;
      final dist = 30 + d * 70;
      final p = Curves.easeOut.transform(progress);
      final pos = origin + Offset(math.cos(angle), math.sin(angle) - 0.4) * dist * p;
      paint.color = colors[card].withValues(alpha: (1 - progress) * 0.9);
      canvas.drawCircle(pos, 1.5 + s * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
