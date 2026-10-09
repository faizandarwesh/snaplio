import 'package:flutter_test/flutter_test.dart';
import 'package:snap_lio/domain/analyzer.dart';
import 'package:snap_lio/domain/expense/expense_extractor.dart';
import 'package:snap_lio/domain/models.dart';
import 'package:snap_lio/domain/notifications/smart_notifications.dart';
import 'package:snap_lio/domain/text_utils.dart';

void main() {
  const analyzer = ScreenshotAnalyzer();
  final now = DateTime(2026, 10, 9, 12);
  const on = SmartSettings();

  ShotInfo shot(String id, String text, {ShotExpense? expense, String file = 'Screenshot_1.png'}) {
    final a = analyzer.analyze(fileName: file, text: text);
    return ShotInfo(assetId: id, category: a.category, entities: a.entities, words: wordCount(text), at: now, expense: expense);
  }

  group('what gets a notification', () {
    test('OTP → "Code 482913" with Copy', () {
      final n = noticeFor(shot('1', 'Your verification code is 482913. Do not share it.'), on)!;
      expect(n.kind, SmartKind.otp);
      expect(n.title, 'Code 482913');
      expect(n.actions.single.type, SmartActionType.copy);
      expect(n.actions.single.value, '482913');
      expect(n.link, 'snaplio://screenshot/1');
    });

    test('receipt → amount + payee, View and Not an expense', () {
      const x = ShotExpense(id: 7, amountMinor: 250000, currency: 'PKR', payee: 'Ali Khan', type: ExpenseType.expense, likelyDuplicate: false);
      final n = noticeFor(shot('2', 'JazzCash\nTransaction Successful\nRs. 2,500\nSent to Ali Khan', expense: x), on)!;
      expect(n.title, 'Rs 2,500 to Ali Khan · added to Spend');
      expect(n.actions.map((a) => a.type), [SmartActionType.view, SmartActionType.notExpense]);
      expect(n.actions.last.expenseId, 7);
    });

    test('link → host in title, Open + Copy', () {
      final n = noticeFor(shot('3', 'https://www.example.com/article/42'), on)!;
      expect(n.title, 'Link saved · example.com');
      expect(n.actions.map((a) => a.type), [SmartActionType.open, SmartActionType.copy]);
      expect(n.actions.first.assetId, '3', reason: 'Open records the link as read');
    });

    test('short address screenshot → Open in Maps', () {
      final n = noticeFor(shot('4', 'House 12, Street 5, Sector F-7, Islamabad'), on)!;
      expect(n.kind, SmartKind.address);
      expect(n.actions.single.value, startsWith('geo:0,0?q='));
    });

    test('phone number → Call + WhatsApp', () {
      final n = noticeFor(shot('5', 'Rider\n0300-1234567'), on)!;
      expect(n.title, '0300-1234567');
      expect(n.actions.map((a) => a.value), ['tel:+923001234567', 'https://wa.me/923001234567']);
    });

    test('chats, memes and notes never notify', () {
      expect(noticeFor(shot('6', 'Call me at 0300-1234567', file: 'Screenshot_20261008-145012_WhatsApp.jpg'), on), isNull);
      expect(noticeFor(shot('7', 'lol'), on), isNull);
      expect(
        noticeFor(shot('8', List.filled(60, 'meeting notes about the quarterly plan and goals').join(' ')), on),
        isNull,
      );
    });

    test('per-type toggles and the master switch', () {
      expect(noticeFor(shot('9', 'Your OTP is 4821'), const SmartSettings(otp: false)), isNull);
      expect(noticeFor(shot('9', 'Your OTP is 4821'), SmartSettings.off), isNull);
    });
  });

  group('bursts', () {
    const planner = NotificationPlanner();

    test('up to 3 in a minute: one notification each', () {
      final p = planner.plan(
        log: const [],
        shots: [shot('1', 'Your OTP is 4821'), shot('2', 'https://flutter.dev'), shot('3', 'lol')],
        settings: on,
        now: now,
      );
      expect(p.post, hasLength(2));
      expect(p.summary, isNull);
      expect(p.log, hasLength(3));
    });

    test('the 4th within 60 s collapses everything into one summary', () {
      final first = planner.plan(
        log: const [],
        shots: [shot('1', 'Your OTP is 4821'), shot('2', 'https://flutter.dev'), shot('3', 'lol')],
        settings: on,
        now: now,
      );
      final second = planner.plan(log: first.log, shots: [shot('4', 'haha')], settings: on, now: now.add(const Duration(seconds: 20)));
      expect(second.post, isEmpty);
      expect(second.summary!.title, '4 screenshots sorted · 1 code, 1 link');
      expect(second.cancel, unorderedEquals([notificationIdFor('1'), notificationIdFor('2')]));

      // A 5th one still updates the summary.
      final third = planner.plan(log: second.log, shots: [shot('5', 'hmm')], settings: on, now: now.add(const Duration(seconds: 30)));
      expect(third.summary!.title, startsWith('5 screenshots sorted'));
    });

    test('old entries fall out of the window', () {
      final first = planner.plan(
        log: const [],
        shots: [shot('1', 'Your OTP is 4821'), shot('2', 'https://flutter.dev'), shot('3', 'lol')],
        settings: on,
        now: now,
      );
      final later = planner.plan(log: first.log, shots: [shot('4', 'Your OTP is 9911')], settings: on, now: now.add(const Duration(minutes: 2)));
      expect(later.summary, isNull);
      expect(later.post.single.title, 'Code 9911');
    });

    test('a screenshot already handled is never notified twice', () {
      final first = planner.plan(log: const [], shots: [shot('1', 'Your OTP is 4821')], settings: on, now: now);
      final again = planner.plan(log: first.log, shots: [shot('1', 'Your OTP is 4821')], settings: on, now: now);
      expect(again.post, isEmpty);
    });

    test('a burst of memes stays silent', () {
      final p = planner.plan(log: const [], shots: [for (var i = 0; i < 5; i++) shot('$i', 'lol')], settings: on, now: now);
      expect(p.post, isEmpty);
      expect(p.summary, isNull);
    });

    test('burst log round-trips', () {
      final l = [BurstEntry('1', ScreenshotCategory.otp, now, notified: true)];
      final back = BurstEntry.decode(BurstEntry.encode(l)).single;
      expect(back.assetId, '1');
      expect(back.notified, isTrue);
      expect(BurstEntry.decode('garbage'), isEmpty);
    });
  });
}
