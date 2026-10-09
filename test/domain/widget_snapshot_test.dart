import 'package:flutter_test/flutter_test.dart';
import 'package:snap_lio/core/utils/format.dart';
import 'package:snap_lio/domain/expense/expense_category.dart';
import 'package:snap_lio/domain/expense/expense_extractor.dart';
import 'package:snap_lio/domain/expense/spend_summary.dart';
import 'package:snap_lio/domain/widgets/widget_snapshot.dart';

void main() {
  SpendEntry e(int amount, DateTime d) =>
      SpendEntry(id: amount, amountMinor: amount, currency: 'PKR', type: ExpenseType.expense, category: ExpenseCategory.food, date: d);

  test('month spend, change vs last month, latest receipt, clean, links', () {
    final spend = summarizeMonth([e(4520000, DateTime(2026, 10, 3)), e(4000000, DateTime(2026, 9, 10))], DateTime(2026, 10, 9), 'PKR');
    final w = buildWidgetSnapshot(
      spend: spend,
      latest: const LatestReceipt(250000, 'PKR', 'Ali Khan'),
      cleanableBytes: 180 * 1024 * 1024,
      unreadLinks: 3,
      formatBytes: formatBytes,
    );
    expect(w['spend_label'], 'October spend');
    expect(w['spend_total'], 'Rs 45,200');
    expect(w['spend_change'], '▲ 13% vs Sep');
    expect(w['spend_dir'], 'up');
    expect(w['receipt_value'], 'Rs 2,500');
    expect(w['receipt_label'], 'Ali Khan');
    expect(w['clean_value'], '180 MB');
    expect(w['links_value'], '3');
    expect(w['links_label'], 'unread links');
  });

  test('empty state reads well', () {
    final w = buildWidgetSnapshot(
      spend: summarizeMonth(const [], DateTime(2026, 10, 9), 'PKR'),
      latest: null,
      cleanableBytes: 0,
      unreadLinks: 1,
      formatBytes: formatBytes,
    );
    expect(w['spend_total'], 'Rs 0');
    expect(w['spend_change'], 'Nothing tracked yet');
    expect(w['spend_dir'], 'flat');
    expect(w['receipt_value'], '—');
    expect(w['receipt_label'], 'No receipts yet');
    expect(w['clean_value'], '0 MB');
    expect(w['links_label'], 'unread link');
  });
}
