import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/states.dart';
import '../../data/recap_repository.dart';
import '../../domain/models.dart';
import '../../domain/recap/weekly_recap.dart';
import '../spend/spend_widgets.dart';
import 'recap_providers.dart';

/// Story-style weekly recap: full-screen cards, progress bar on top, tap to
/// advance (left third goes back), hold to pause, auto-advance.
class RecapStoryScreen extends ConsumerWidget {
  const RecapStoryScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(recapProvider(id));
    return switch (r) {
      AsyncData(:final value) when value != null => _Story(stored: value),
      AsyncData() => Scaffold(
          appBar: AppBar(),
          body: const EmptyState(icon: Icons.history_rounded, title: 'Recap not found', message: 'It may be from an older install.'),
        ),
      AsyncError() => Scaffold(appBar: AppBar(), body: const ErrorState()),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _Page {
  const _Page(this.color, this.builder);
  final Color color;
  final Widget Function(BuildContext context) builder;
}

class _Story extends ConsumerStatefulWidget {
  const _Story({required this.stored});
  final StoredRecap stored;

  @override
  ConsumerState<_Story> createState() => _StoryState();
}

class _StoryState extends ConsumerState<_Story> with SingleTickerProviderStateMixin {
  static const _perPage = Duration(seconds: 6);
  late final AnimationController _progress = AnimationController(vsync: this, duration: _perPage)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _next();
    });
  int _index = 0;
  late List<_Page> _pages;

  WeeklyRecap get _r => widget.stored.recap;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.reduceMotion) _progress.forward();
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i < 0) {
      _progress.forward(from: 0);
      return;
    }
    if (i >= _pages.length) {
      _close();
      return;
    }
    Haptics.selection();
    setState(() => _index = i);
    if (context.reduceMotion) {
      _progress.value = 0;
    } else {
      _progress.forward(from: 0);
    }
  }

  void _next() => _go(_index + 1);

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  String get _range {
    final a = _r.weekStart;
    final b = _r.weekEnd.subtract(const Duration(minutes: 1));
    return '${DateFormat.MMMd().format(a)} – ${DateFormat.MMMd().format(b)}';
  }

  List<_Page> _buildPages() {
    final r = _r;
    return [
      _Page(Brand.violet, (context) => _Big(
            kicker: 'Your week · $_range',
            value: CountUp(r.screenshots, style: _numStyle(context), format: (v) => formatCount(v.round())),
            title: r.screenshots == 1 ? 'screenshot taken' : 'screenshots taken',
            footer: r.topSourceApp == null ? null : 'Most of them from ${r.topSourceApp} (${r.topSourceAppCount})',
          )),
      if (r.spentMinor > 0)
        _Page(r.topCategory == null ? SpendStyle.income : SpendStyle.color(r.topCategory!), (context) => _Big(
              kicker: 'Spend',
              value: MoneyCountUp(r.spentMinor, r.currency, style: _numStyle(context)),
              title: 'spent across ${r.receipts} receipt${r.receipts == 1 ? '' : 's'}',
              footer: r.topCategory == null ? null : 'Mostly ${r.topCategory!.label} ${r.topCategory!.emoji}',
            )),
      if (r.unreadLinks > 0)
        _Page(CategoryStyle.of(ScreenshotCategory.links).color, (context) => _LinksPage(recap: r, onOpen: _openLink)),
      if (r.cleanableBytes >= 1024 * 1024)
        _Page(const Color(0xFFEE7B6E), (context) => _Big(
              kicker: 'Storage',
              value: Text(formatBytes(r.cleanableBytes), style: _numStyle(context)),
              title: 'ready to clean',
              footer: 'Old codes, duplicates and forgotten screenshots',
              action: _StoryButton(
                label: 'Review & clean',
                icon: Icons.cleaning_services_rounded,
                onTap: () {
                  context.go(Routes.clean);
                },
              ),
            )),
      _Page(Brand.sky, (context) => _Big(
            kicker: 'That\'s a wrap',
            value: Text('✨', style: _numStyle(context)),
            title: 'That\'s your week',
            footer: 'Everything stayed on your phone. See you next week!',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StoryButton(label: 'Past weeks', icon: Icons.history_rounded, onTap: () => context.push(Routes.recapHistory)),
                const SizedBox(width: Space.xs),
                _StoryButton(label: 'Done', icon: Icons.check_rounded, onTap: _close),
              ],
            ),
          )),
    ];
  }

  Future<void> _openLink(RecapLink l) async {
    _progress.stop();
    await ref.read(repositoryProvider).markLinkOpened(l.assetId, l.url);
    await launchUrl(Uri.parse(l.url), mode: LaunchMode.externalApplication);
  }

  TextStyle _numStyle(BuildContext context) =>
      context.text.displayLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()]);

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B10),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _go(d.localPosition.dx < MediaQuery.sizeOf(context).width / 3 ? _index - 1 : _index + 1),
          onLongPressStart: (_) => _progress.stop(),
          onLongPressEnd: (_) {
            if (!context.reduceMotion) _progress.forward();
          },
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 400) _close();
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: Motion.slow,
                  curve: Motion.enter,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [page.color.withValues(alpha: 0.85), Color.lerp(page.color, const Color(0xFF0B0B10), 0.75)!],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Space.lg, 56, Space.lg, Space.lg),
                    child: AnimatedSwitcher(
                      duration: Motion.slow,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: child),
                      ),
                      child: KeyedSubtree(key: ValueKey(_index), child: page.builder(context)),
                    ),
                  ),
                ),
              ),
              if (_index == _pages.length - 1)
                const Positioned.fill(child: IgnorePointer(child: ConfettiBurst(colors: [Colors.white, Brand.sky, Brand.violet], count: 50))),
              // Progress bar + close.
              Positioned(
                top: top + Space.xs,
                left: Space.sm,
                right: Space.xxs,
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) => Row(
                          children: [
                            for (var i = 0; i < _pages.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      minHeight: 3,
                                      value: i < _index ? 1 : (i == _index ? (context.reduceMotion ? 1 : _progress.value) : 0),
                                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _close,
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.kicker, required this.value, required this.title, this.footer, this.action});

  final String kicker;
  final Widget value;
  final String title;
  final String? footer;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final dim = Colors.white.withValues(alpha: 0.75);
    final children = <Widget>[
      Text(kicker.toUpperCase(), style: context.text.labelMedium?.copyWith(color: dim, letterSpacing: 1.4)),
      const SizedBox(height: Space.md),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
      Text(title, style: context.text.headlineSmall?.copyWith(color: white)),
      if (footer != null) ...[
        const SizedBox(height: Space.md),
        Text(footer!, style: context.text.bodyLarge?.copyWith(color: dim)),
      ],
      if (action != null) ...[const SizedBox(height: Space.xl), action!],
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: context.reduceMotion
          ? children
          : [
              for (var i = 0; i < children.length; i++)
                children[i].animate().fadeIn(delay: (80 * i).ms, duration: Motion.slow).moveY(begin: 14, end: 0, curve: Motion.enter),
            ],
    );
  }
}

class _LinksPage extends StatelessWidget {
  const _LinksPage({required this.recap, required this.onOpen});
  final WeeklyRecap recap;
  final ValueChanged<RecapLink> onOpen;

  @override
  Widget build(BuildContext context) {
    final n = recap.unreadLinks;
    return _Big(
      kicker: 'Saved for later',
      value: CountUp(n, style: context.text.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
      title: '${n == 1 ? 'link' : 'links'} waiting for you',
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in recap.links)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Pressable(
                onTap: () => onOpen(l),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: Radii.smAll),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(l.host, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyLarge?.copyWith(color: Colors.white)),
                      ),
                      const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryButton extends StatelessWidget {
  const _StoryButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF111118)),
            const SizedBox(width: Space.xs),
            Text(label, style: context.text.labelLarge?.copyWith(color: const Color(0xFF111118))),
          ],
        ),
      ),
    );
  }
}
