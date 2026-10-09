import 'package:flutter_test/flutter_test.dart';
import 'package:snap_lio/core/utils/format.dart';
import 'package:snap_lio/domain/expense/expense_category.dart';
import 'package:snap_lio/domain/expense/expense_extractor.dart';
import 'package:snap_lio/domain/expense/spend_summary.dart';
import 'package:snap_lio/domain/models.dart';
import 'package:snap_lio/domain/recap/weekly_recap.dart';

void main() {
  group('schedule', () {
    const s = RecapSchedule(); // Sunday 19:00
    // 2026-10-11 is a Sunday.
    test('last / next occurrence', () {
      expect(s.lastOccurrence(DateTime(2026, 10, 11, 19, 30)), DateTime(2026, 10, 11, 19));
      expect(s.lastOccurrence(DateTime(2026, 10, 11, 18, 59)), DateTime(2026, 10, 4, 19));
      expect(s.lastOccurrence(DateTime(2026, 10, 14, 9)), DateTime(2026, 10, 11, 19));
      expect(s.nextOccurrence(DateTime(2026, 10, 9, 12)), DateTime(2026, 10, 11, 19));
    });

    test('due once per week, after the time has passed', () {
      expect(s.due(DateTime(2026, 10, 11, 18), DateTime(2026, 10, 4, 19)), isNull);
      expect(s.due(DateTime(2026, 10, 11, 19, 5), DateTime(2026, 10, 4, 19)), DateTime(2026, 10, 11, 19));
      expect(s.due(DateTime(2026, 10, 11, 23), DateTime(2026, 10, 11, 19)), isNull, reason: 'already sent');
      expect(s.due(DateTime(2026, 10, 11, 20), null), DateTime(2026, 10, 11, 19));
    });

    test('too stale or disabled → nothing', () {
      expect(s.due(DateTime(2026, 10, 14, 20), DateTime(2026, 10, 4, 19)), isNull);
      expect(const RecapSchedule(enabled: false).due(DateTime(2026, 10, 11, 20), null), isNull);
    });

    test('custom day and time', () {
      const fri = RecapSchedule(weekday: DateTime.friday, hour: 9, minute: 30);
      expect(fri.lastOccurrence(DateTime(2026, 10, 11, 12)), DateTime(2026, 10, 9, 9, 30));
      final (a, b) = RecapSchedule.weekFor(DateTime(2026, 10, 9, 9, 30));
      expect(a, DateTime(2026, 10, 2, 9, 30));
      expect(b, DateTime(2026, 10, 9, 9, 30));
    });
  });

  group('compute', () {
    final start = DateTime(2026, 10, 4, 19);
    final end = DateTime(2026, 10, 11, 19);
    SpendEntry e(int amount, DateTime d, {ExpenseCategory c = ExpenseCategory.food, ExpenseType t = ExpenseType.expense, bool excluded = false, String cur = 'PKR'}) =>
        SpendEntry(id: amount, amountMinor: amount, currency: cur, type: t, category: c, date: d, isExcluded: excluded);

    test('counts only this week and only real spend', () {
      final r = computeWeeklyRecap(
        start: start,
        end: end,
        shots: [
          RecapShot(DateTime(2026, 10, 5), ScreenshotCategory.chats, 'WhatsApp'),
          RecapShot(DateTime(2026, 10, 6), ScreenshotCategory.receipts, 'JazzCash'),
          RecapShot(DateTime(2026, 10, 7), ScreenshotCategory.chats, 'WhatsApp'),
          RecapShot(DateTime(2026, 10, 1), ScreenshotCategory.chats, 'WhatsApp'), // last week
        ],
        spend: [
          e(800000, DateTime(2026, 10, 6)),
          e(440000, DateTime(2026, 10, 7), c: ExpenseCategory.bills),
          e(999999, DateTime(2026, 10, 7), t: ExpenseType.income),
          e(500000, DateTime(2026, 10, 8), excluded: true),
          e(1299, DateTime(2026, 10, 8), cur: 'USD'),
          e(100000, DateTime(2026, 10, 1)),
        ],
        unreadLinks: const [RecapLink('9', 'https://www.example.com/a', 'example.com/a')],
        cleanableBytes: 180 * 1024 * 1024,
        currency: 'PKR',
      );
      expect(r.screenshots, 3);
      expect(r.receipts, 2);
      expect(r.spentMinor, 1240000);
      expect(r.topCategory, ExpenseCategory.food);
      expect(r.topSourceApp, 'WhatsApp');
      expect(r.topSourceAppCount, 2);
      expect(r.unreadLinks, 1);
      expect(r.links.single.host, 'example.com');
      expect(r.worthNotifying, isTrue);
      expect(r.summaryLine(formatBytes), '3 screenshots · Rs 12,400 spent · 1 unread link · 180 MB to clean');

      final back = WeeklyRecap.decode(r.encode());
      expect(back.spentMinor, r.spentMinor);
      expect(back.topCategory, ExpenseCategory.food);
      expect(back.links.single.url, 'https://www.example.com/a');
      expect(back.weekStart, start);
    });

    test('quiet week is not worth a notification', () {
      final r = computeWeeklyRecap(start: start, end: end, shots: const [], spend: const [], unreadLinks: const [], cleanableBytes: 0, currency: 'PKR');
      expect(r.worthNotifying, isFalse);
      expect(r.summaryLine(formatBytes), '0 screenshots');
    });
  });
}
