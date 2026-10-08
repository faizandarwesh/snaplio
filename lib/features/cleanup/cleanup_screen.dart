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
import '../../domain/cleanup_rules/cleanup_rules.dart';

extension CleanupKindStyle on CleanupKind {
  IconData get icon => switch (this) {
        CleanupKind.oldOtps => Icons.password_rounded,
        CleanupKind.duplicates => Icons.copy_all_rounded,
        CleanupKind.deliveredOrders => Icons.inventory_2_outlined,
        CleanupKind.large => Icons.photo_size_select_large_rounded,
        CleanupKind.old => Icons.history_rounded,
      };

  Color get color => switch (this) {
        CleanupKind.oldOtps => const Color(0xFF9B87F5),
        CleanupKind.duplicates => const Color(0xFF6B9EF2),
        CleanupKind.deliveredOrders => const Color(0xFFE8A951),
        CleanupKind.large => const Color(0xFFEE7B6E),
        CleanupKind.old => const Color(0xFF8D9AB0),
      };
}

class CleanupScreen extends ConsumerWidget {
  const CleanupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(cleanupReportProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(Space.screen, topPad + Space.lg, Space.screen, Space.md),
            sliver: SliverToBoxAdapter(child: Text('Clean up', style: context.text.displaySmall)),
          ),
          ...switch (report) {
            AsyncData(:final value) when value.suggestions.isEmpty => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.auto_awesome_rounded,
                    title: 'All tidy ✨',
                    message: 'No old codes, duplicates or forgotten screenshots right now. We\'ll keep an eye out.',
                  ),
                ),
              ],
            AsyncData(:final value) => [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                  sliver: SliverToBoxAdapter(child: _HeroCard(report: value)),
                ),
                const SliverToBoxAdapter(child: SectionHeader('Suggestions')),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                  sliver: SliverList.separated(
                    itemCount: value.suggestions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                    itemBuilder: (context, i) {
                      final card = _SuggestionCard(suggestion: value.suggestions[i]);
                      if (context.reduceMotion) return card;
                      return card.animate().fadeIn(delay: Motion.stagger * i * 2, duration: Motion.slow).moveY(begin: 12, end: 0, curve: Motion.enter);
                    },
                  ),
                ),
              ],
            AsyncError() => [
                SliverFillRemaining(hasScrollBody: false, child: ErrorState(onRetry: () => ref.invalidate(cleanupReportProvider))),
              ],
            _ => [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                  sliver: SliverList.list(children: const [
                    ShimmerBox(height: 150, radius: Radii.md),
                    SizedBox(height: Space.lg),
                    ShimmerBox(height: 96, radius: Radii.md),
                    SizedBox(height: Space.sm),
                    ShimmerBox(height: 96, radius: Radii.md),
                  ]),
                ),
              ],
          },
          SliverToBoxAdapter(child: SizedBox(height: navBarClearance(context))),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.report});
  final CleanupReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        borderRadius: Radii.mdAll,
        gradient: LinearGradient(
          colors: [Brand.violet.withValues(alpha: 0.28), Brand.sky.withValues(alpha: 0.14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Brand.violet.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You can free', style: context.text.bodyLarge?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: 2),
          CountUp(
            report.reclaimableBytes,
            format: (v) => formatBytes(v.round()),
            style: context.text.displayMedium,
          ),
          const SizedBox(height: Space.xs),
          Text(
            'across ${formatCount(report.reclaimableCount)} screenshots you probably don\'t need.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: Space.md),
          Row(children: [
            Icon(Icons.verified_user_outlined, size: 16, color: context.colors.success),
            const SizedBox(width: 6),
            Expanded(child: Text('You review everything before it\'s deleted.', style: context.text.labelSmall)),
          ]),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});
  final CleanupSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final c = context.colors;
    return Pressable(
      semanticLabel: '${s.kind.title}, ${s.count} screenshots',
      onTap: () => context.push(Routes.review(s.kind)),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(color: c.surface, borderRadius: Radii.mdAll, border: Border.all(color: c.border)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: s.kind.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(s.kind.icon, color: s.kind.color),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.kind.title, style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text(s.kind.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    '${formatCount(s.count)} · ${formatBytes(s.totalBytes)}',
                    style: context.text.labelMedium?.copyWith(color: s.kind.color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            _MiniStack(ids: s.assetIds.take(3).toList()),
            Icon(Icons.chevron_right_rounded, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _MiniStack extends StatelessWidget {
  const _MiniStack({required this.ids});
  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 56,
      child: Stack(
        children: [
          for (var i = ids.length - 1; i >= 0; i--)
            Positioned(
              left: i * 12.0,
              top: 2,
              child: Container(
                width: 32,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colors.surface, width: 1.5),
                ),
                child: AssetThumb(ids[i], radius: 7, size: 120),
              ),
            ),
        ],
      ),
    );
  }
}
