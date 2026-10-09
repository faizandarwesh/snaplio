import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/shimmer.dart';
import '../../core/widgets/states.dart';
import '../../data/recap_repository.dart';
import 'recap_providers.dart';

/// Past weekly recaps, newest first.
class RecapHistoryScreen extends ConsumerWidget {
  const RecapHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(recapsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Past weeks')),
      body: switch (all) {
        AsyncData(:final value) when value.isEmpty => const EmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'No recaps yet',
            message: 'Your first weekly recap arrives on the day and time you picked in Settings.',
          ),
        AsyncData(:final value) => ListView.separated(
            padding: EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, MediaQuery.paddingOf(context).bottom + Space.xl),
            itemCount: value.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) {
              final tile = RecapTile(stored: value[i]);
              if (context.reduceMotion) return tile;
              return tile.animate().fadeIn(delay: Motion.stagger * i, duration: Motion.slow).moveY(begin: 10, end: 0, curve: Motion.enter);
            },
          ),
        AsyncError() => ErrorState(onRetry: () => ref.invalidate(recapsProvider)),
        _ => const Padding(padding: EdgeInsets.all(Space.screen), child: ShimmerBox(height: 84, radius: Radii.md)),
      },
    );
  }
}

class RecapTile extends StatelessWidget {
  const RecapTile({super.key, required this.stored, this.highlight = false});
  final StoredRecap stored;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = stored.recap;
    final end = r.weekEnd.subtract(const Duration(minutes: 1));
    return Pressable(
      onTap: () => context.push(Routes.recap('${stored.id}')),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          borderRadius: Radii.mdAll,
          border: Border.all(color: highlight ? Brand.violet.withValues(alpha: 0.35) : c.border),
          gradient: highlight
              ? LinearGradient(colors: [Brand.violet.withValues(alpha: context.isDark ? 0.28 : 0.14), Brand.sky.withValues(alpha: 0.10)])
              : null,
          color: highlight ? null : c.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(gradient: Brand.gradient, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    highlight ? 'Your week in screenshots' : '${DateFormat.MMMd().format(r.weekStart)} – ${DateFormat.MMMd().format(end)}',
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(r.summaryLine(formatBytes), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Home: the fresh recap, for 48 hours after it's generated.
class RecapHomeCard extends ConsumerWidget {
  const RecapHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(freshRecapProvider);
    if (r == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, 0),
      child: RecapTile(stored: r, highlight: true),
    );
  }
}
