import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/shell.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/shimmer.dart';
import '../../core/widgets/states.dart';
import '../../data/expense_repository.dart';
import '../../domain/expense/csv_export.dart';
import '../../domain/expense/money.dart';
import '../../domain/expense/spend_summary.dart';
import 'spend_providers.dart';
import 'spend_widgets.dart';

class SpendScreen extends ConsumerStatefulWidget {
  const SpendScreen({super.key});

  @override
  ConsumerState<SpendScreen> createState() => _SpendScreenState();
}

class _SpendScreenState extends ConsumerState<SpendScreen> {
  /// +1 when moving to a later month, -1 for earlier (drives the slide).
  int _direction = 0;

  void _go(int dir) {
    final n = ref.read(spendMonthProvider.notifier);
    if (dir > 0 && !n.canGoNext) return;
    Haptics.selection();
    setState(() => _direction = dir);
    dir > 0 ? n.next() : n.previous();
  }

  Future<void> _export(DateTime month) async {
    final list = ref.read(monthExpensesProvider(month)).value ?? const <ExpenseView>[];
    final rows = [
      for (final x in list)
        if (!x.row.date.isBefore(month))
          CsvExpense(
            date: x.row.date,
            type: x.row.type,
            amountMinor: x.row.amountMinor,
            currency: x.row.currency,
            payee: x.row.payee,
            category: x.category.label,
            note: x.row.note,
            transactionId: x.row.transactionId,
            source: x.row.source,
            excluded: x.row.isExcluded,
          ),
    ];
    if (rows.isEmpty) {
      _snack('Nothing to export for ${DateFormat.yMMMM().format(month)}');
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SnapLio-spend-${DateFormat('yyyy-MM').format(month)}.csv');
    await file.writeAsString(expensesToCsv(rows));
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'SnapLio spend · ${DateFormat.yMMMM().format(month)}',
    ));
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickCurrency() async {
    final current = ref.read(settingsProvider).defaultCurrency;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Default currency', style: context.text.titleLarge),
              const SizedBox(height: 4),
              Text('Used when a receipt doesn\'t show one, and for your Spend totals.', style: context.text.bodyMedium),
              const SizedBox(height: Space.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in supportedCurrencies)
                    FilterPill(label: '${currencySymbols[c]} · $c', selected: c == current, onTap: () => Navigator.pop(context, c)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await ref.read(settingsProvider.notifier).setCurrency(picked);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(spendMonthProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    final canNext = ref.read(spendMonthProvider.notifier).canGoNext;

    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: navBarClearance(context) - Space.lg),
        child: FloatingActionButton.extended(
          heroTag: 'add-expense',
          onPressed: () {
            Haptics.light();
            context.push(Routes.expenseNew);
          },
          backgroundColor: Brand.violet,
          foregroundColor: Colors.white,
          elevation: 2,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add'),
        ),
      ),
      body: GestureDetector(
        // Swipe anywhere horizontally to change month.
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 300) return;
          _go(v < 0 ? 1 : -1);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(Space.screen, topPad + Space.lg, Space.xs, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(child: Text('Spend', style: context.text.displaySmall)),
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      icon: Icon(Icons.more_vert_rounded, color: context.colors.textSecondary),
                      onSelected: (v) => v == 'csv' ? _export(month) : _pickCurrency(),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'csv', child: ListTile(leading: Icon(Icons.ios_share_rounded), title: Text('Export CSV'), dense: true)),
                        PopupMenuItem(value: 'cur', child: ListTile(leading: Icon(Icons.currency_exchange_rounded), title: Text('Default currency'), dense: true)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.xs, Space.xs, Space.xs, 0),
              sliver: SliverToBoxAdapter(
                child: _MonthSwitcher(month: month, direction: _direction, canNext: canNext, onPrev: () => _go(-1), onNext: () => _go(1)),
              ),
            ),
            _MonthBody(month: month, direction: _direction),
            SliverToBoxAdapter(child: SizedBox(height: navBarClearance(context) + 56)),
          ],
        ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.month, required this.direction, required this.canNext, required this.onPrev, required this.onNext});

  final DateTime month;
  final int direction;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = month.year == DateTime.now().year ? DateFormat.MMMM().format(month) : DateFormat.yMMMM().format(month);
    return Row(
      children: [
        IconButton(onPressed: onPrev, tooltip: 'Previous month', icon: Icon(Icons.chevron_left_rounded, color: c.textSecondary)),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.medium,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: Offset(0.25 * direction, 0), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Motion.enter)),
                child: child,
              ),
            ),
            child: Text(label, key: ValueKey(month), textAlign: TextAlign.center, style: context.text.titleMedium),
          ),
        ),
        IconButton(
          onPressed: canNext ? onNext : null,
          tooltip: 'Next month',
          icon: Icon(Icons.chevron_right_rounded, color: canNext ? c.textSecondary : c.textTertiary.withValues(alpha: 0.4)),
        ),
      ],
    );
  }
}

class _MonthBody extends ConsumerWidget {
  const _MonthBody({required this.month, required this.direction});
  final DateTime month;
  final int direction;

  Widget _enter(BuildContext context, Widget w, int i) {
    if (context.reduceMotion) return w;
    return w
        .animate(key: ValueKey('$month-$i'))
        .fadeIn(delay: Motion.stagger * i * 2, duration: Motion.slow)
        .moveX(begin: 18.0 * direction, end: 0, curve: Motion.enter);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spend = ref.watch(monthSpendProvider(month));
    final list = ref.watch(monthExpensesProvider(month));
    final review = ref.watch(needsReviewProvider).value ?? const <ExpenseView>[];
    final filter = ref.watch(spendFilterProvider);

    if (spend.isLoading && !spend.hasValue) return const SliverToBoxAdapter(child: _SpendSkeleton());
    if (spend.hasError) {
      return SliverFillRemaining(hasScrollBody: false, child: ErrorState(onRetry: () => ref.invalidate(monthExpensesProvider(month))));
    }
    final s = spend.requireValue;
    final items = [
      for (final x in list.value ?? const <ExpenseView>[])
        if (!x.row.date.isBefore(month) && (filter == null || x.category == filter)) x,
    ];

    if (s.isEmpty && items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          children: [
            if (review.isNotEmpty) Padding(padding: const EdgeInsets.all(Space.screen), child: _ReviewCard(count: review.length)),
            const Expanded(
              child: EmptyState(
                icon: Icons.receipt_long_rounded,
                accent: Color(0xFF5BBF8A),
                title: 'No spend this month',
                message: 'Take a screenshot of any payment receipt and it shows up here automatically.',
              ),
            ),
          ],
        ),
      );
    }

    final cards = <Widget>[
      _HeroCard(spend: s),
      if (review.isNotEmpty) _ReviewCard(count: review.length),
      if (s.byCategory.isNotEmpty)
        _Card(
          title: 'Where it went',
          child: SpendDonut(spend: s, selected: filter, onSelect: ref.read(spendFilterProvider.notifier).toggle),
        ),
      if (s.count > 0) _Card(title: 'Daily', child: DailyBars(daily: s.daily, currency: s.currency, month: month)),
    ];

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          sliver: SliverList.separated(
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) => _enter(context, cards[i], i),
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(
            'Transactions',
            trailing: filter == null
                ? Text('${items.length}', style: context.text.labelSmall)
                : FilterPill(
                    label: '${filter.label}  ✕',
                    selected: true,
                    accent: SpendStyle.color(filter),
                    onTap: ref.read(spendFilterProvider.notifier).clear,
                  ),
          ),
        ),
        _TransactionList(items: items),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(color: c.surface, borderRadius: Radii.mdAll, border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleSmall),
          const SizedBox(height: Space.sm),
          child,
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.spend});
  final MonthSpend spend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final others = spend.totalsByCurrency.where((t) => t.$1 != spend.currency).toList();
    return Container(
      padding: const EdgeInsets.all(Space.md + 4),
      decoration: BoxDecoration(
        borderRadius: Radii.mdAll,
        border: Border.all(color: c.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.violet.withValues(alpha: context.isDark ? 0.22 : 0.12), c.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spent', style: context.text.labelMedium),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyCountUp(spend.totalMinor, spend.currency, style: context.text.displayMedium),
          ),
          const SizedBox(height: Space.xs),
          ChangeBadge(pct: spend.changePct, previousMonth: previousMonth(spend.month)),
          if (others.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final (cur, minor) in others)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: c.surfaceElevated, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.border)),
                    child: Text('+ ${formatMoneyMinor(minor, cur)}', style: context.text.labelMedium?.copyWith(color: c.textPrimary)),
                  ),
              ],
            ),
          ],
          if (spend.incomeByCurrency.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Divider(height: 1, color: c.border),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                const Icon(Icons.south_west_rounded, size: 16, color: SpendStyle.income),
                const SizedBox(width: 6),
                Text('Income', style: context.text.labelMedium),
                const Spacer(),
                Flexible(
                  child: Text(
                    spend.incomeByCurrency.map((t) => formatMoneyMinor(t.$2, t.$1)).join(' · '),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(color: SpendStyle.income),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFE8A951);
    return Pressable(
      onTap: () => context.push(Routes.spendReview),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: amber.withValues(alpha: 0.12),
          borderRadius: Radii.mdAll,
          border: Border.all(color: amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.fact_check_outlined, color: amber, size: 22),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count need${count == 1 ? 's' : ''} a quick look', style: context.text.titleSmall),
                  Text('Swipe to confirm or skip', style: context.text.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: amber),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.items});
  final List<ExpenseView> items;

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          child: Text('Nothing in this category yet.', style: context.text.bodyMedium),
        ),
      );
    }
    // Flatten into headers + rows.
    final entries = <Object>[];
    DateTime? lastDay;
    for (final x in items) {
      final d = DateTime(x.row.date.year, x.row.date.month, x.row.date.day);
      if (d != lastDay) {
        entries.add(d);
        lastDay = d;
      }
      entries.add(x);
    }
    final c = context.colors;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.screen),
      sliver: SliverList.builder(
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          if (e is DateTime) {
            final dayTotal = items
                .where((x) => x.entry.countsAsSpend && x.row.currency == ref.read(settingsProvider).defaultCurrency && DateUtils.isSameDay(x.row.date, e))
                .fold<int>(0, (s, x) => s + x.row.amountMinor);
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : Space.md, bottom: Space.xxs, left: 4, right: 4),
              child: Row(
                children: [
                  Expanded(child: Text(_dayLabel(e), style: context.text.labelMedium?.copyWith(color: c.textSecondary))),
                  if (dayTotal > 0)
                    Text(formatMoneyMinor(dayTotal, ref.read(settingsProvider).defaultCurrency), style: context.text.labelSmall),
                ],
              ),
            );
          }
          final x = e as ExpenseView;
          return _SwipeToExclude(
            key: ValueKey(x.row.id),
            expense: x,
            child: ExpenseTile(expense: x, onTap: () => context.push(Routes.expense(x.row.id))),
          );
        },
      ),
    );
  }
}

/// Swipe left to mark "not an expense" (or back), with undo.
class _SwipeToExclude extends ConsumerWidget {
  const _SwipeToExclude({super.key, required this.expense, required this.child});
  final ExpenseView expense;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final excluded = expense.row.isExcluded;
    final color = excluded ? c.success : c.danger;
    return Dismissible(
      key: ValueKey('swipe-${expense.row.id}-$excluded'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.35},
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.lg),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: Radii.mdAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(excluded ? 'Count it' : 'Not an expense', style: context.text.labelMedium?.copyWith(color: color)),
            const SizedBox(width: 6),
            Icon(excluded ? Icons.undo_rounded : Icons.remove_circle_outline_rounded, color: color),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        Haptics.medium();
        final service = ref.read(expenseServiceProvider);
        await service.setExcluded(expense.row.id, !excluded);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(excluded ? 'Counted again' : '${expense.row.payee ?? 'Payment'} won\'t count as spend'),
              action: SnackBarAction(label: 'Undo', onPressed: () => service.setExcluded(expense.row.id, excluded)),
            ));
        }
        // The row stays (restyled), so never actually dismiss.
        return false;
      },
      child: child,
    );
  }
}

class _SpendSkeleton extends StatelessWidget {
  const _SpendSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Space.screen),
      child: Column(
        children: [
          ShimmerBox(height: 150, radius: Radii.md),
          SizedBox(height: Space.sm),
          ShimmerBox(height: 170, radius: Radii.md),
          SizedBox(height: Space.sm),
          ShimmerBox(height: 64, radius: Radii.sm),
          SizedBox(height: Space.xs),
          ShimmerBox(height: 64, radius: Radii.sm),
          SizedBox(height: Space.xs),
          ShimmerBox(height: 64, radius: Radii.sm),
        ],
      ),
    );
  }
}
