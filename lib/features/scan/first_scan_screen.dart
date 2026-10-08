import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_ring.dart';
import '../../domain/models.dart';
import '../../services/scan_service.dart';

/// Live first scan: progress ring, "Sorting X of Y", category chips counting
/// up, then a short celebration and auto-navigation to Home.
class FirstScanScreen extends ConsumerStatefulWidget {
  const FirstScanScreen({super.key});

  @override
  ConsumerState<FirstScanScreen> createState() => _FirstScanScreenState();
}

class _FirstScanScreenState extends ConsumerState<FirstScanScreen> {
  bool _finished = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    setState(() {
      _failed = false;
      _finished = false;
    });
    final service = ref.read(scanServiceProvider);
    await service.scan();
    if (!mounted) return;
    if (service.current.phase == ScanPhase.failed) {
      setState(() => _failed = true);
      return;
    }
    Haptics.medium();
    setState(() => _finished = true);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = ref.watch(scanProgressProvider).value ?? ScanProgress.idle;
    final total = p.total;
    final discovering = p.phase == ScanPhase.discovering || (p.phase == ScanPhase.idle && !_finished);

    final String headline;
    final String sub;
    if (_failed) {
      headline = 'Scan interrupted';
      sub = 'Something went wrong while reading your screenshots.';
    } else if (_finished) {
      headline = total == 0 ? 'All set' : '${formatCount(total)} screenshots sorted ✨';
      sub = total == 0 ? 'New screenshots will show up here automatically.' : 'Everything stayed on your phone.';
    } else if (discovering) {
      headline = 'Finding your screenshots';
      sub = 'Looking through your gallery…';
    } else {
      headline = 'Sorting ${formatCount(p.processed)} of ${formatCount(total)}';
      sub = 'Reading text on-device. You can keep using your phone.';
    }

    final cats = ScreenshotCategory.values.where((cat) => (p.counts[cat] ?? 0) > 0).toList();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  ProgressRing(
                    progress: _finished ? 1 : (discovering ? 0.02 : p.fraction),
                    active: !_finished && !_failed,
                    size: 220,
                    child: AnimatedSwitcher(
                      duration: Motion.medium,
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: child)),
                      child: _finished
                          ? const Icon(Icons.check_rounded, key: ValueKey('done'), size: 72, color: Brand.sky)
                          : Column(
                              key: const ValueKey('pct'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${(p.fraction * 100).round()}%', style: context.text.displayMedium),
                                Text(discovering ? 'starting' : 'sorted', style: context.text.labelSmall),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  AnimatedSwitcher(
                    duration: Motion.medium,
                    child: Text(headline, key: ValueKey(headline.split(' ').first + _finished.toString()), textAlign: TextAlign.center, style: context.text.headlineSmall),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(sub, textAlign: TextAlign.center, style: context.text.bodyMedium),
                  const SizedBox(height: Space.lg),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final cat in cats) _CountChip(key: ValueKey(cat), category: cat, count: p.counts[cat] ?? 0),
                    ],
                  ),
                  const Spacer(flex: 3),
                  if (_failed)
                    GradientButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: _start)
                  else if (_finished)
                    SoftButton(label: 'Continue', expand: true, onPressed: () => context.go(Routes.home))
                  else
                    Text('Your screenshots never leave this device.', style: context.text.labelSmall?.copyWith(color: c.textTertiary)),
                  const SizedBox(height: Space.lg),
                ],
              ),
            ),
          ),
          if (_finished && !_failed)
            Positioned.fill(
              child: ConfettiBurst(colors: [for (final cat in ScreenshotCategory.values) CategoryStyle.of(cat).color, Brand.sky]),
            ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({super.key, required this.category, required this.count});

  final ScreenshotCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final s = CategoryStyle.of(category);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: s.tint(context),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: s.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 15, color: s.color),
          const SizedBox(width: 6),
          Text(category.label, style: context.text.labelMedium?.copyWith(color: s.color)),
          const SizedBox(width: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(end: count.toDouble()),
            duration: const Duration(milliseconds: 500),
            builder: (context, v, _) => Text(
              formatCount(v.round()),
              style: context.text.labelMedium?.copyWith(color: context.colors.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
    if (context.reduceMotion) return chip;
    return chip.animate().scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut, duration: 600.ms).fadeIn(duration: 200.ms);
  }
}
