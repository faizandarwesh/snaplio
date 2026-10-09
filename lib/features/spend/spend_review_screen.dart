import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/widgets/asset_thumb.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/states.dart';
import '../../data/expense_repository.dart';
import '../../domain/expense/money.dart';
import 'spend_providers.dart';
import 'spend_widgets.dart';

/// Quick swipe review of low-confidence / possible-duplicate expenses:
/// right = looks right, left = not an expense, tap = edit.
class SpendReviewScreen extends ConsumerStatefulWidget {
  const SpendReviewScreen({super.key});

  @override
  ConsumerState<SpendReviewScreen> createState() => _SpendReviewScreenState();
}

class _SpendReviewScreenState extends ConsumerState<SpendReviewScreen> {
  /// Snapshot taken on open so cards don't jump while the DB catches up.
  List<ExpenseView>? _queue;
  final _done = <int>{};
  int _reviewed = 0;

  List<ExpenseView> get _remaining => [for (final x in _queue ?? const <ExpenseView>[]) if (!_done.contains(x.row.id)) x];

  Future<void> _decide(ExpenseView x, bool keep) async {
    setState(() {
      _done.add(x.row.id);
      _reviewed++;
    });
    keep ? Haptics.light() : Haptics.medium();
    final s = ref.read(expenseServiceProvider);
    keep ? await s.confirm(x.row.id) : await s.setExcluded(x.row.id, true);
    if (_remaining.isEmpty) Haptics.medium();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(needsReviewProvider);
    if (_queue == null && live.hasValue) _queue = live.requireValue;
    final c = context.colors;
    final remaining = _remaining;
    final total = _queue?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(total == 0 ? 'Review' : 'Review · ${(total - remaining.length + (remaining.isEmpty ? 0 : 1)).clamp(1, total)} of $total'),
      ),
      body: _queue == null
          ? const Center(child: CircularProgressIndicator())
          : remaining.isEmpty
              ? Stack(
                  children: [
                    EmptyState(
                      icon: Icons.task_alt_rounded,
                      accent: c.success,
                      title: 'All caught up ✨',
                      message: _reviewed == 0 ? 'Nothing needs a look right now.' : 'Your Spend totals are up to date.',
                      actionLabel: 'Done',
                      onAction: () => context.pop(),
                    ),
                    if (_reviewed > 0)
                      Positioned.fill(
                        child: IgnorePointer(child: ConfettiBurst(colors: [for (final cat in SpendStyle.palette) cat, Brand.sky], count: 40)),
                      ),
                  ],
                )
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(Space.screen),
                          child: Stack(
                            children: [
                              if (remaining.length > 1)
                                Positioned.fill(
                                  child: Transform.translate(
                                    offset: const Offset(0, 14),
                                    child: Transform.scale(scale: 0.94, child: _ReviewCard(expense: remaining[1], dimmed: true)),
                                  ),
                                ),
                              Positioned.fill(
                                child: Dismissible(
                                  key: ValueKey(remaining.first.row.id),
                                  onDismissed: (d) => _decide(remaining.first, d == DismissDirection.startToEnd),
                                  background: _SwipeHint(keep: true),
                                  secondaryBackground: _SwipeHint(keep: false),
                                  child: Pressable(
                                    scale: 0.99,
                                    onTap: () => context.push(Routes.expense(remaining.first.row.id)),
                                    child: _ReviewCard(expense: remaining.first),
                                  ),
                                )
                                    .animate(key: ValueKey('in-${remaining.first.row.id}'))
                                    .fadeIn(duration: Motion.fast)
                                    .scale(begin: const Offset(0.96, 0.96), curve: Motion.enter, duration: Motion.medium),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: SoftButton(
                                label: 'Not an expense',
                                icon: Icons.close_rounded,
                                color: c.danger,
                                expand: true,
                                onPressed: () => _decide(remaining.first, false),
                              ),
                            ),
                            const SizedBox(width: Space.xs),
                            Expanded(
                              child: SoftButton(
                                label: 'Looks right',
                                icon: Icons.check_rounded,
                                color: c.success,
                                expand: true,
                                onPressed: () => _decide(remaining.first, true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('Tap the card to edit', style: context.text.labelSmall),
                      const SizedBox(height: Space.sm),
                    ],
                  ),
                ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.keep});
  final bool keep;

  @override
  Widget build(BuildContext context) {
    final color = keep ? context.colors.success : context.colors.danger;
    return Container(
      alignment: keep ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: Radii.lgAll),
      child: Icon(keep ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 40),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.expense, this.dimmed = false});
  final ExpenseView expense;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = expense.row;
    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: Radii.lgAll,
          border: Border.all(color: c.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: r.assetId == null
                  ? Center(child: Icon(SpendStyle.icon(expense.category), size: 64, color: SpendStyle.color(expense.category)))
                  : AssetThumb(r.assetId!, radius: 0, size: 700, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (expense.isDuplicate)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: Text('Possible duplicate of another payment', style: context.text.labelMedium?.copyWith(color: const Color(0xFFE8A951))),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(formatMoneyMinor(r.amountMinor, r.currency), style: context.text.headlineMedium),
                        ),
                      ),
                      SpendCategoryChip(expense.category, dense: false),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.payee ?? 'Unknown payee',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge?.copyWith(color: r.payee == null ? c.textTertiary : c.textPrimary),
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
