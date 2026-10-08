import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/widgets/pressable.dart';
import 'illustrations.dart';

class _Page {
  const _Page(this.title, this.body);
  final String title;
  final String body;
}

const _pages = [
  _Page('Find anything', 'Search every screenshot by the words inside it — Wi-Fi passwords, addresses, that one receipt.'),
  _Page('Act in one tap', 'Links, numbers and codes become buttons. Open, call, WhatsApp or copy in a single tap.'),
  _Page('Clean up, privately', 'Spot old OTPs, duplicates and delivered orders, and free up space. All on your phone.'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    final access = await ref.read(galleryAccessProvider.notifier).refresh();
    if (!mounted) return;
    context.go(access.canRead ? Routes.firstScan : Routes.permission);
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: Motion.slow, curve: Motion.enter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  duration: Motion.fast,
                  opacity: last ? 0 : 1,
                  child: TextButton(
                    onPressed: last ? null : _finish,
                    style: TextButton.styleFrom(minimumSize: const Size(64, 48), foregroundColor: c.textSecondary),
                    child: const Text('Skip'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) {
                  Haptics.selection();
                  setState(() => _page = i);
                },
                itemBuilder: (context, i) => _OnboardingPage(page: _pages[i], index: i, active: i == _page),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, Space.lg),
              child: Column(
                children: [
                  PillIndicator(count: _pages.length, index: _page),
                  const SizedBox(height: Space.lg),
                  GradientButton(
                    label: last ? 'Get started' : 'Next',
                    icon: last ? Icons.arrow_forward_rounded : null,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page, required this.index, required this.active});

  final _Page page;
  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final art = switch (index) {
      0 => FindAnythingArt(active: active),
      1 => ActInOneTapArt(active: active),
      _ => CleanUpArt(active: active),
    };
    final reduce = context.reduceMotion;
    Widget enter(Widget w, int i) =>
        reduce || !active ? w : w.animate(key: ValueKey('$index-$i-$active')).fadeIn(delay: (80 * i).ms, duration: 400.ms).moveY(begin: 14, end: 0, curve: Motion.enter);

    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: art),
                const SizedBox(height: Space.xl),
                enter(Text(page.title, textAlign: TextAlign.center, style: context.text.displaySmall), 0),
                const SizedBox(height: Space.sm),
                enter(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(page.body, textAlign: TextAlign.center, style: context.text.bodyLarge?.copyWith(color: context.colors.textSecondary)),
                  ),
                  1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dots that morph into a gradient pill for the active page.
class PillIndicator extends StatelessWidget {
  const PillIndicator({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.slow,
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: i == index ? Brand.gradient : null,
              color: i == index ? null : context.colors.textTertiary.withValues(alpha: 0.4),
            ),
          ),
      ],
    );
  }
}
