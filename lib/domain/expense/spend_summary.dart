import 'expense_category.dart';
import 'expense_extractor.dart';

/// Minimal view of an expense for aggregation. Pure Dart.
class SpendEntry {
  const SpendEntry({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.category,
    required this.date,
    this.isExcluded = false,
    this.isDuplicate = false,
  });

  final int id;
  final int amountMinor;
  final String currency;
  final ExpenseType type;
  final ExpenseCategory category;
  final DateTime date;
  final bool isExcluded;

  /// Suspected duplicate not yet confirmed by the user.
  final bool isDuplicate;

  /// Counted in spend: an expense the user hasn't excluded, and not a
  /// suspected duplicate.
  bool get countsAsSpend => type == ExpenseType.expense && !isExcluded && !isDuplicate;
  bool get countsAsIncome => type == ExpenseType.income && !isExcluded && !isDuplicate;
}

class CategorySpend {
  const CategorySpend(this.category, this.amountMinor, this.count);
  final ExpenseCategory category;
  final int amountMinor;
  final int count;
}

/// One month of spend, in the primary currency unless noted.
class MonthSpend {
  const MonthSpend({
    required this.month,
    required this.currency,
    required this.totalMinor,
    required this.previousTotalMinor,
    required this.byCategory,
    required this.daily,
    required this.totalsByCurrency,
    required this.incomeByCurrency,
    required this.count,
  });

  final DateTime month;
  final String currency;
  final int totalMinor;
  final int previousTotalMinor;

  /// Largest first; only categories with spend.
  final List<CategorySpend> byCategory;

  /// Index 0 = day 1 of the month.
  final List<int> daily;

  /// Every currency spent this month, primary first, then by amount.
  final List<(String, int)> totalsByCurrency;
  final List<(String, int)> incomeByCurrency;
  final int count;

  /// Percent change vs last month, or null when last month had no spend.
  double? get changePct =>
      previousTotalMinor == 0 ? null : (totalMinor - previousTotalMinor) * 100 / previousTotalMinor;

  bool get isEmpty => count == 0 && incomeByCurrency.isEmpty;
}

DateTime monthStart(DateTime d) => DateTime(d.year, d.month);
DateTime nextMonth(DateTime d) => DateTime(d.year, d.month + 1);
DateTime previousMonth(DateTime d) => DateTime(d.year, d.month - 1);
int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

/// Most frequent currency among counted expenses, or null.
String? mostFrequentCurrency(Iterable<SpendEntry> entries) {
  final n = <String, int>{};
  for (final e in entries) {
    if (e.countsAsSpend) n[e.currency] = (n[e.currency] ?? 0) + 1;
  }
  if (n.isEmpty) return null;
  return (n.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
}

MonthSpend summarizeMonth(Iterable<SpendEntry> all, DateTime month, String primaryCurrency) {
  final start = monthStart(month);
  final end = nextMonth(start);
  final prevStart = previousMonth(start);
  bool inRange(DateTime d, DateTime a, DateTime b) => !d.isBefore(a) && d.isBefore(b);

  final byCur = <String, int>{};
  final incomeByCur = <String, int>{};
  final byCat = <ExpenseCategory, (int, int)>{};
  final daily = List<int>.filled(daysInMonth(start), 0);
  var prev = 0;
  var count = 0;

  for (final e in all) {
    if (inRange(e.date, start, end)) {
      if (e.countsAsSpend) {
        count++;
        byCur[e.currency] = (byCur[e.currency] ?? 0) + e.amountMinor;
        if (e.currency == primaryCurrency) {
          final (a, n) = byCat[e.category] ?? (0, 0);
          byCat[e.category] = (a + e.amountMinor, n + 1);
          daily[e.date.day - 1] += e.amountMinor;
        }
      } else if (e.countsAsIncome) {
        incomeByCur[e.currency] = (incomeByCur[e.currency] ?? 0) + e.amountMinor;
      }
    } else if (inRange(e.date, prevStart, start) && e.countsAsSpend && e.currency == primaryCurrency) {
      prev += e.amountMinor;
    }
  }

  List<(String, int)> ordered(Map<String, int> m) => [
        for (final e in (m.entries.toList()
          ..sort((a, b) {
            if (a.key == primaryCurrency) return -1;
            if (b.key == primaryCurrency) return 1;
            return b.value.compareTo(a.value);
          })))
          (e.key, e.value),
      ];

  final cats = [for (final e in byCat.entries) CategorySpend(e.key, e.value.$1, e.value.$2)]
    ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

  return MonthSpend(
    month: start,
    currency: primaryCurrency,
    totalMinor: byCur[primaryCurrency] ?? 0,
    previousTotalMinor: prev,
    byCategory: cats,
    daily: daily,
    totalsByCurrency: ordered(byCur),
    incomeByCurrency: ordered(incomeByCur),
    count: count,
  );
}
