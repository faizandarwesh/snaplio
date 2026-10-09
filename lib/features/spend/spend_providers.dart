import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/expense_repository.dart';
import '../../domain/expense/expense_category.dart';
import '../../domain/expense/spend_summary.dart';

/// The month Spend is showing (first day, local time).
class SpendMonth extends Notifier<DateTime> {
  @override
  DateTime build() => monthStart(DateTime.now());

  bool get canGoNext => state.isBefore(monthStart(DateTime.now()));

  void next() {
    if (canGoNext) state = nextMonth(state);
  }

  void previous() => state = previousMonth(state);
  void set(DateTime m) => state = monthStart(m);
}

final spendMonthProvider = NotifierProvider<SpendMonth, DateTime>(SpendMonth.new);

/// Category filter for the transaction list (null = all).
class SpendFilter extends Notifier<ExpenseCategory?> {
  @override
  ExpenseCategory? build() {
    ref.watch(spendMonthProvider);
    return null;
  }

  void toggle(ExpenseCategory c) => state = state == c ? null : c;
  void clear() => state = null;
}

final spendFilterProvider = NotifierProvider<SpendFilter, ExpenseCategory?>(SpendFilter.new);

/// Expenses of [month] and the month before (for the comparison), newest first.
final monthExpensesProvider = StreamProvider.autoDispose.family<List<ExpenseView>, DateTime>(
  (ref, month) => ref.watch(expenseRepositoryProvider).watchRange(previousMonth(month), nextMonth(month)),
);

final monthSpendProvider = Provider.autoDispose.family<AsyncValue<MonthSpend>, DateTime>((ref, month) {
  final currency = ref.watch(settingsProvider.select((s) => s.defaultCurrency));
  return ref.watch(monthExpensesProvider(month)).whenData(
        (list) => summarizeMonth([for (final x in list) x.entry], month, currency),
      );
});

final needsReviewProvider = StreamProvider<List<ExpenseView>>(
  (ref) => ref.watch(expenseRepositoryProvider).watchNeedsReview(),
);

final expenseProvider = StreamProvider.autoDispose.family<ExpenseView?, int>(
  (ref, id) => ref.watch(expenseRepositoryProvider).watchOne(id),
);

final expenseForAssetProvider = StreamProvider.autoDispose.family<ExpenseView?, String>(
  (ref, assetId) => ref.watch(expenseRepositoryProvider).watchForAsset(assetId),
);
