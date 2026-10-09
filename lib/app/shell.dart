import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/tokens.dart';
import '../core/haptics.dart';
import '../features/recap/recap_providers.dart';
import '../features/smart/smart_actions.dart';
import 'deep_links.dart';
import '../services/scan_service.dart';
import 'providers.dart';

/// App shell: tab content + floating frosted pill navigation that hides on
/// scroll-down and returns on scroll-up. Also drives incremental scans on
/// launch and on resume.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _navVisible = ValueNotifier(true);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
      ref.read(spendBackfillProvider.notifier).runIfNeeded();
      ref.read(smartActionsProvider.notifier).onAppStart();
      ref.read(recapControllerProvider.notifier).onAppStart();
      ref.read(deepLinkProvider).markReady();
      ref.read(widgetSyncProvider).schedule();
    });
  }

  Future<void> _onResume() async {
    // The background job may have written while we were away.
    await ref.read(smartActionsProvider.notifier).onResume();
    ref.read(widgetSyncProvider).schedule();
    final access = await ref.read(galleryAccessProvider.notifier).refresh();
    if (access.canRead) _startScan();
  }

  void _startScan() => ref.read(scanServiceProvider).scan();

  @override
  void dispose() {
    _lifecycle.dispose();
    _navVisible.dispose();
    super.dispose();
  }

  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n.direction == ScrollDirection.reverse && n.metrics.pixels > 24) {
      _navVisible.value = false;
    } else if (n.direction == ScrollDirection.forward) {
      _navVisible.value = true;
    }
    return false;
  }

  void _onTab(int i) {
    if (i == widget.shell.currentIndex) {
      // Re-tap returns the branch to its root.
      widget.shell.goBranch(i, initialLocation: true);
      return;
    }
    Haptics.selection();
    _navVisible.value = true;
    widget.shell.goBranch(i);
  }

  @override
  Widget build(BuildContext context) {
    // A finished scan changes MB-to-clean, links and receipts on the widgets.
    ref.listen(scanProgressProvider.select((p) => p.value?.phase), (prev, next) {
      if (next == ScanPhase.done && prev != ScanPhase.done) ref.read(widgetSyncProvider).schedule();
    });
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<UserScrollNotification>(onNotification: _onScroll, child: widget.shell),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _navVisible,
              builder: (context, visible, child) {
                final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
                final show = visible && !keyboard;
                return AnimatedSlide(
                  offset: show ? Offset.zero : const Offset(0, 1.6),
                  duration: Motion.medium,
                  curve: Motion.enter,
                  child: AnimatedOpacity(opacity: show ? 1 : 0, duration: Motion.fast, child: child),
                );
              },
              child: FloatingNavBar(currentIndex: widget.shell.currentIndex, onTap: _onTab),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _items = [
  _NavItem('Home', Icons.home_outlined, Icons.home_rounded),
  _NavItem('Search', Icons.search_rounded, Icons.manage_search_rounded),
  _NavItem('Spend', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
  _NavItem('Clean', Icons.cleaning_services_outlined, Icons.cleaning_services_rounded),
];

/// Bottom padding the tab screens should reserve for the floating nav.
double navBarClearance(BuildContext context) => MediaQuery.paddingOf(context).bottom + 96;

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, bottom + Space.sm),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: Radii.lgAll,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: c.navGlass,
                borderRadius: Radii.lgAll,
                border: Border.all(color: c.border),
              ),
              padding: const EdgeInsets.all(6),
              child: LayoutBuilder(
                builder: (context, box) {
                  final slot = box.maxWidth / _items.length;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: Motion.slow,
                        curve: Curves.easeOutBack,
                        left: slot * currentIndex,
                        top: 0,
                        bottom: 0,
                        width: slot,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Brand.violet.withValues(alpha: context.isDark ? 0.22 : 0.14),
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < _items.length; i++)
                            Expanded(child: _NavButton(item: _items[i], active: i == currentIndex, onTap: () => onTap(i))),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? (context.isDark ? Colors.white : Brand.violet) : c.textSecondary;
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: Motion.fast,
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: Icon(active ? item.activeIcon : item.icon, key: ValueKey(active), color: color, size: 24),
            ),
            AnimatedSize(
              duration: Motion.fast,
              curve: Motion.enter,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-fades + slightly lifts between shell branches (each keeps its state).
class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return Stack(
      children: [
        for (var i = 0; i < children.length; i++)
          _Branch(active: i == currentIndex, reduce: reduce, child: children[i]),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({required this.active, required this.reduce, required this.child});

  final bool active;
  final bool reduce;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final d = reduce ? Duration.zero : Motion.medium;
    return IgnorePointer(
      ignoring: !active,
      child: TickerMode(
        enabled: active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: d,
          curve: Motion.enter,
          child: AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.015),
            duration: d,
            curve: Motion.enter,
            child: ExcludeSemantics(excluding: !active, child: child),
          ),
        ),
      ),
    );
  }
}
