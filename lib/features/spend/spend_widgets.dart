import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/widgets/asset_thumb.dart';
import '../../core/widgets/pressable.dart';
import '../../data/expense_repository.dart';
import '../../domain/expense/expense_category.dart';
import '../../domain/expense/expense_extractor.dart';
import '../../domain/expense/money.dart';
import '../../domain/expense/spend_summary.dart';

/// Small spend-category label with its accent.
class SpendCategoryChip extends StatelessWidget {
  const SpendCategoryChip(this.category, {super.key, this.dense = true, this.onTap});

  final ExpenseCategory category;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = SpendStyle.color(category);
    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 3 : 7),
      decoration: BoxDecoration(color: SpendStyle.tint(context, category), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(SpendStyle.icon(category), size: dense ? 12 : 15, color: color),
          const SizedBox(width: 4),
          Text(category.label, style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: dense ? 12 : 16, color: color),
          ],
        ],
      ),
    );
    return onTap == null ? chip : Pressable(onTap: onTap, child: chip);
  }
}

/// Animated money value (count-up), respecting reduce-motion.
class MoneyCountUp extends StatelessWidget {
  const MoneyCountUp(this.minor, this.currency, {super.key, this.style});

  final int minor;
  final String currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = (style ?? context.text.displaySmall)?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    if (context.reduceMotion) return Text(formatMoneyMinor(minor, currency), style: s);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: minor.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        formatMoneyMinor((v / kMinorFactor).round() * kMinorFactor, currency),
        style: s,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}

/// "▲ 12% vs September", colored subtly.
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({super.key, required this.pct, required this.previousMonth});

  final double? pct;
  final DateTime previousMonth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name = DateFormat.MMMM().format(previousMonth);
    if (pct == null) {
      return Text('Nothing tracked in $name', style: context.text.bodySmall);
    }
    final p = pct!;
    final flat = p.abs() < 0.5;
    final color = flat ? c.textSecondary : (p > 0 ? SpendStyle.up : SpendStyle.down);
    final arrow = flat ? '■' : (p > 0 ? '▲' : '▼');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(
        flat ? 'Same as $name' : '$arrow ${p.abs().round()}% vs $name',
        style: context.text.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

/// One transaction row: thumbnail, payee, category, amount.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, required this.onTap});

  final ExpenseView expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = expense.row;
    final income = expense.type == ExpenseType.income;
    final excluded = r.isExcluded;
    final amountStyle = context.text.titleSmall?.copyWith(
      color: excluded ? c.textTertiary : (income ? SpendStyle.income : c.textPrimary),
      decoration: excluded ? TextDecoration.lineThrough : null,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Opacity(
        opacity: excluded ? 0.55 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 52,
                child: r.assetId != null
                    ? AssetThumb(r.assetId!, radius: 10, size: 120)
                    : Container(
                        decoration: BoxDecoration(color: SpendStyle.tint(context, expense.category), borderRadius: BorderRadius.circular(10)),
                        child: Icon(SpendStyle.icon(expense.category), size: 20, color: SpendStyle.color(expense.category)),
                      ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      r.payee ?? (income ? 'Money received' : 'Payment'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyLarge?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SpendCategoryChip(expense.category),
                        if (excluded)
                          Text('Not an expense', style: context.text.labelSmall)
                        else if (expense.needsReview)
                          _ReviewDot(duplicate: expense.isDuplicate),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.xs),
              Text('${income ? '+' : ''}${formatMoneyMinor(r.amountMinor, r.currency)}', style: amountStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewDot extends StatelessWidget {
  const _ReviewDot({required this.duplicate});
  final bool duplicate;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFE8A951);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: amber, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(duplicate ? 'Possible duplicate' : 'Needs review', style: context.text.labelSmall?.copyWith(color: amber)),
      ],
    );
  }
}

/// Donut of spend per category; tapping a slice toggles the list filter.
class SpendDonut extends StatelessWidget {
  const SpendDonut({super.key, required this.spend, required this.selected, required this.onSelect});

  final MonthSpend spend;
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final cats = spend.byCategory;
    final c = context.colors;
    return Row(
      children: [
        SizedBox.square(
          dimension: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: cats.length > 1 ? 2.5 : 0,
                  centerSpaceRadius: 42,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final i = response?.touchedSection?.touchedSectionIndex ?? -1;
                      if (i >= 0 && i < cats.length) {
                        Haptics.selection();
                        onSelect(cats[i].category);
                      }
                    },
                  ),
                  sections: [
                    for (final s in cats)
                      PieChartSectionData(
                        value: s.amountMinor.toDouble(),
                        color: SpendStyle.color(s.category).withValues(alpha: selected == null || selected == s.category ? 1 : 0.28),
                        radius: selected == s.category ? 24 : 18,
                        showTitle: false,
                      ),
                  ],
                ),
                duration: Motion.slow,
                curve: Motion.enter,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${cats.length}', style: context.text.titleLarge),
                  Text(cats.length == 1 ? 'category' : 'categories', style: context.text.labelSmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            children: [
              for (final s in cats.take(5))
                Pressable(
                  scale: 0.98,
                  onTap: () => onSelect(s.category),
                  child: AnimatedOpacity(
                    duration: Motion.fast,
                    opacity: selected == null || selected == s.category ? 1 : 0.45,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: SpendStyle.color(s.category), borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.category.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
                          ),
                          Text(
                            '${(s.amountMinor * 100 / math.max(1, spend.totalMinor)).round()}%',
                            style: context.text.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (cats.length > 5)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('+${cats.length - 5} more', style: context.text.labelSmall),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mini bar chart: spend per day of the month.
class DailyBars extends StatelessWidget {
  const DailyBars({super.key, required this.daily, required this.currency, required this.month});

  final List<int> daily;
  final String currency;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    final maxV = daily.fold<int>(0, math.max).toDouble();
    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          maxY: maxV <= 0 ? 1 : maxV * 1.15,
          alignment: BarChartAlignment.spaceBetween,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, meta) {
                  final d = v.toInt() + 1;
                  if (d != 1 && d % 7 != 0 && d != daily.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('$d', style: context.text.labelSmall?.copyWith(fontSize: 10, color: c.textTertiary)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => c.surfaceElevated,
              tooltipBorder: BorderSide(color: c.border),
              tooltipBorderRadius: BorderRadius.circular(10),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${DateFormat.MMMd().format(DateTime(month.year, month.month, group.x + 1))}\n',
                context.text.labelSmall!,
                children: [
                  TextSpan(text: formatMoneyMinor(rod.toY.round(), currency), style: context.text.labelMedium?.copyWith(color: c.textPrimary)),
                ],
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < daily.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: daily[i].toDouble(),
                    width: 5,
                    borderRadius: BorderRadius.circular(3),
                    color: isCurrent && i + 1 == now.day ? Brand.sky : Brand.violet.withValues(alpha: daily[i] > 0 ? 0.85 : 0.0),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxV <= 0 ? 1 : maxV * 1.15,
                      color: c.border,
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: Motion.slow,
        curve: Motion.enter,
      ),
    );
  }
}

/// Tiny cumulative-spend line for the Home card.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.color = Brand.violet, this.height = 36});

  final List<int> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: RepaintBoundary(child: CustomPaint(painter: _SparkPainter(values, color), size: Size.infinite)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.fold<int>(0, math.max).toDouble();
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = maxV <= 0 ? size.height - 2 : size.height - 2 - (size.height - 4) * values[i] / maxV;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.color != color;
}

/// Running total by day, up to today for the current month.
List<int> cumulative(List<int> daily, DateTime month) {
  final now = DateTime.now();
  final upTo = month.year == now.year && month.month == now.month ? now.day : daily.length;
  var sum = 0;
  return [for (var i = 0; i < upTo; i++) sum += daily[i]];
}
