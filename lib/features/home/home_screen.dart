import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/shell.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/asset_thumb.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/shimmer.dart';
import '../../core/widgets/states.dart';
import '../../data/screenshot_repository.dart';
import '../../services/gallery_service.dart';
import '../../services/scan_service.dart';

/// Staggered entrance only on the very first build of Home.
bool _homeAnimated = false;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final bool _animate = !_homeAnimated;

  @override
  void initState() {
    super.initState();
    _homeAnimated = true;
  }

  Future<void> _refresh() async {
    final access = await ref.read(galleryAccessProvider.notifier).refresh();
    if (!access.canRead) return;
    // Fire-and-forget: the live banner shows progress, the spinner just acks.
    ref.read(scanServiceProvider).scan();
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  Widget _enter(Widget w, int i) {
    if (!_animate || context.reduceMotion) return w;
    return w.animate().fadeIn(delay: Motion.stagger * i * 2, duration: Motion.slow).moveY(begin: 16, end: 0, curve: Motion.enter);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(libraryStatsProvider);
    final cats = ref.watch(categoryStatsProvider);
    final recent = ref.watch(recentScreenshotsProvider);
    final scan = ref.watch(scanProgressProvider).value ?? ScanProgress.idle;
    final access = ref.watch(galleryAccessProvider).value;
    final total = stats.value?.total ?? 0;
    final loading = stats.isLoading || cats.isLoading;

    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        edgeOffset: topPad,
        color: Brand.violet,
        backgroundColor: context.colors.surfaceElevated,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(Space.screen, topPad + Space.lg, Space.screen, 0),
              sliver: SliverList.list(children: [
                _enter(_Header(stats: stats.value), 0),
                const SizedBox(height: Space.md),
                _enter(const _SearchPill(), 1),
                if (access == GalleryAccess.limited) ...[
                  const SizedBox(height: Space.md),
                  const _PartialAccessBanner(),
                ],
                AnimatedSize(
                  duration: Motion.medium,
                  curve: Motion.enter,
                  child: scan.isRunning
                      ? Padding(padding: const EdgeInsets.only(top: Space.md), child: _ScanBanner(progress: scan))
                      : const SizedBox(width: double.infinity),
                ),
              ]),
            ),
            if (loading)
              const SliverToBoxAdapter(child: _HomeSkeleton())
            else if (stats.hasError || cats.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(onRetry: () {
                  ref.invalidate(libraryStatsProvider);
                  ref.invalidate(categoryStatsProvider);
                }),
              )
            else if (total == 0 && !scan.isRunning)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.screenshot_monitor_rounded,
                  title: 'No screenshots yet',
                  message: 'Take a screenshot and pull down to refresh — it\'ll be sorted in seconds.',
                  actionLabel: 'Scan again',
                  onAction: _refresh,
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, 0),
                  child: _enter(const _StorageCard(), 2),
                ),
              ),
              const SliverToBoxAdapter(child: SectionHeader('Categories')),
              _CategoryGrid(stats: cats.value ?? const [], animate: _animate),
              SliverToBoxAdapter(
                child: SectionHeader(
                  'Recent',
                  trailing: Text('${formatCount(total)} total', style: context.text.labelSmall),
                ),
              ),
              SliverToBoxAdapter(child: _RecentStrip(rows: recent.value ?? const [])),
            ],
            SliverToBoxAdapter(child: SizedBox(height: navBarClearance(context))),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stats});
  final LibraryStats? stats;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting(), style: context.text.displaySmall),
              const SizedBox(height: 4),
              Text(
                s == null ? ' ' : '${formatCount(s.total)} screenshots · ${formatBytes(s.bytes)}',
                style: context.text.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchPill extends ConsumerWidget {
  const _SearchPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Hero(
      tag: 'search-pill',
      child: Pressable(
        semanticLabel: 'Search screenshots',
        onTap: () {
          ref.read(searchFocusRequestProvider.notifier).request();
          StatefulNavigationShell.of(context).goBranch(1);
        },
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: c.textSecondary),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text('Search text in screenshots', style: context.text.bodyLarge?.copyWith(color: c.textTertiary), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartialAccessBanner extends ConsumerWidget {
  const _PartialAccessBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const amber = Color(0xFFE8A951);
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xs, Space.sm),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.12),
        borderRadius: Radii.mdAll,
        border: Border.all(color: amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: amber, size: 20),
          const SizedBox(width: Space.sm),
          Expanded(child: Text('SnapLio can only see some screenshots', style: context.text.bodyMedium?.copyWith(color: context.colors.textPrimary))),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: amber, minimumSize: const Size(48, 48)),
            onPressed: () async {
              final gallery = ref.read(galleryServiceProvider);
              final current = await ref.read(galleryAccessProvider.notifier).request();
              if (current == GalleryAccess.limited) await gallery.presentLimitedPicker();
              final a = await ref.read(galleryAccessProvider.notifier).refresh();
              if (a.canRead) ref.read(scanServiceProvider).scan();
            },
            child: const Text('Allow all'),
          ),
        ],
      ),
    );
  }
}

class _ScanBanner extends StatelessWidget {
  const _ScanBanner({required this.progress});
  final ScanProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = progress;
    final label = p.phase == ScanPhase.discovering
        ? 'Looking for new screenshots…'
        : 'Sorting ${formatCount(p.processed)} of ${formatCount(p.total)}';
    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(color: c.surface, borderRadius: Radii.smAll, border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: Space.xs),
            Expanded(child: Text(label, style: context.text.labelMedium)),
          ]),
          const SizedBox(height: Space.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: p.phase == ScanPhase.discovering ? null : p.fraction,
              minHeight: 3,
              backgroundColor: c.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends ConsumerWidget {
  const _StorageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final stats = ref.watch(libraryStatsProvider).value ?? LibraryStats.empty;
    final cats = ref.watch(categoryStatsProvider).value ?? const [];
    final report = ref.watch(cleanupReportProvider).value;
    final totalBytes = cats.fold<int>(0, (s, c) => s + c.bytes);

    return Container(
      padding: const EdgeInsets.all(Space.md + 4),
      decoration: BoxDecoration(color: c.surface, borderRadius: Radii.mdAll, border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatBytes(stats.bytes), style: context.text.headlineMedium),
              const SizedBox(width: Space.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('used by screenshots', style: context.text.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 10,
              child: totalBytes == 0
                  ? ColoredBox(color: c.border)
                  : Row(
                      children: [
                        for (final s in cats.where((s) => s.bytes > 0))
                          Expanded(
                            flex: math.max(1, (s.bytes * 1000 / totalBytes).round()),
                            child: Container(
                              margin: const EdgeInsets.only(right: 2),
                              color: CategoryStyle.of(s.category).color,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          if (report != null && report.reclaimableBytes > 0) ...[
            const SizedBox(height: Space.md),
            Pressable(
              onTap: () => StatefulNavigationShell.of(context).goBranch(2),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
                decoration: BoxDecoration(
                  color: Brand.violet.withValues(alpha: 0.1),
                  borderRadius: Radii.smAll,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 18, color: Brand.violet),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: formatBytes(report.reclaimableBytes), style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' can be cleaned'),
                        ]),
                        style: context.text.bodyMedium?.copyWith(color: c.textPrimary),
                      ),
                    ),
                    Text('Review', style: context.text.labelMedium?.copyWith(color: Brand.violet)),
                    const Icon(Icons.chevron_right_rounded, color: Brand.violet),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.stats, required this.animate});
  final List<CategoryStat> stats;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final visible = stats.where((s) => s.count > 0).toList();
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    if (visible.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          child: Text('Categories appear as screenshots are sorted.', style: context.text.bodyMedium),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.screen),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Space.sm,
          crossAxisSpacing: Space.sm,
          mainAxisExtent: 150 * scale,
        ),
        itemCount: visible.length,
        itemBuilder: (context, i) {
          final tile = RepaintBoundary(child: CategoryTile(stat: visible[i]));
          if (!animate || context.reduceMotion) return tile;
          return tile
              .animate()
              .fadeIn(delay: Motion.stagger * (i + 6), duration: Motion.slow)
              .scale(begin: const Offset(0.96, 0.96), curve: Motion.enter);
        },
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.stat});
  final CategoryStat stat;

  @override
  Widget build(BuildContext context) {
    final s = CategoryStyle.of(stat.category);
    return Pressable(
      semanticLabel: '${stat.category.label}, ${stat.count} screenshots',
      onTap: () => context.push(Routes.category(stat.category)),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: s.tint(context),
          borderRadius: Radii.mdAll,
          border: Border.all(color: s.color.withValues(alpha: 0.14)),
        ),
        child: Stack(
          children: [
            Positioned(right: -4, top: -2, child: _PreviewStack(ids: stat.previewIds)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: s.color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const Spacer(),
                Text(formatCount(stat.count), style: context.text.headlineSmall),
                Text(stat.category.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelMedium?.copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewStack extends StatelessWidget {
  const _PreviewStack({required this.ids});
  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) return const SizedBox.shrink();
    final shown = ids.take(3).toList().reversed.toList();
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              right: (shown.length - 1 - i) * 12.0,
              top: (shown.length - 1 - i) * 4.0,
              child: Transform.rotate(
                angle: (i - (shown.length - 1) / 2) * 0.09,
                child: Container(
                  width: 34,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.background, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: AssetThumb(shown[i], radius: 7, size: 120),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentStrip extends StatelessWidget {
  const _RecentStrip({required this.rows});
  final List<ScreenshotRow> rows;

  @override
  Widget build(BuildContext context) {
    final ids = [for (final r in rows) r.assetId];
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.screen),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
        itemBuilder: (context, i) {
          final r = rows[i];
          return Pressable(
            onTap: () => context.push(Routes.detail(r.assetId), extra: DetailArgs(ids: ids, heroScope: 'recent')),
            child: SizedBox(
              width: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'recent-${r.assetId}',
                      child: AssetThumb(r.assetId, radius: Radii.sm, size: 240),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(relativeDate(r.createdAt), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelSmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, 0),
      child: Column(
        children: [
          const ShimmerBox(height: 130, radius: Radii.md),
          const SizedBox(height: Space.lg),
          for (var r = 0; r < 3; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(children: const [
                Expanded(child: ShimmerBox(height: 140, radius: Radii.md)),
                SizedBox(width: Space.sm),
                Expanded(child: ShimmerBox(height: 140, radius: Radii.md)),
              ]),
            ),
        ],
      ),
    );
  }
}
