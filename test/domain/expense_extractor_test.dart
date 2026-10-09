import 'package:flutter_test/flutter_test.dart';
import 'package:snap_lio/domain/expense/dedupe.dart';
import 'package:snap_lio/domain/expense/expense_category.dart';
import 'package:snap_lio/domain/expense/expense_extractor.dart';
import 'package:snap_lio/domain/expense/money.dart';
import 'package:snap_lio/domain/expense/spend_summary.dart';

void main() {
  const x = ExpenseExtractor();
  final shotAt = DateTime(2026, 10, 5, 22, 45);

  ExtractedExpense run(String text, {String currency = 'PKR', Map<String, ExpenseCategory> rules = const {}}) {
    final e = x.extract(text, fallbackDate: shotAt, defaultCurrency: currency, rules: rules);
    expect(e, isNotNull, reason: 'no expense found in:\n$text');
    return e!;
  }

  group('realistic receipts', () {
    test('1. bank IBFT transfer (HBL)', () {
      final e = run('''
10:46 4G 78%
HBL Mobile
Funds Transfer Successful
Amount
PKR 15,000.00
Beneficiary Name
MUHAMMAD AHMED
Beneficiary Account
PK36MEZN0001234567890123
Bank
Meezan Bank
Transaction Reference No.
FT2627810345
Date & Time
05-Oct-2026 10:42 PM
Fee: PKR 0.00''');
      expect(e.amountMinor, 1500000);
      expect(e.currency, 'PKR');
      expect(e.type, ExpenseType.expense);
      expect(e.payee, 'MUHAMMAD AHMED');
      expect(e.transactionId, 'FT2627810345');
      expect(e.category, ExpenseCategory.transfers);
      expect(e.needsReview, isFalse);
      expect(e.confidence, greaterThanOrEqualTo(0.85));
    });

    test('2. JazzCash money transfer', () {
      final e = run('''
JazzCash
Transaction Successful
Rs. 2,500
Sent to
Ali Khan
0300-1234567
TID: 012345678901
05 Oct 2026, 10:42 PM
Fee Rs. 0.00
Share Receipt''');
      expect(e.amountMinor, 250000);
      expect(e.payee, 'Ali Khan');
      expect(e.transactionId, '012345678901');
      expect(e.category, ExpenseCategory.transfers);
      expect(e.date, shotAt, reason: 'same day as the screenshot → keep its exact time');
      expect(e.confidence, greaterThanOrEqualTo(0.85));
    });

    test('3. Easypaisa bill payment (K-Electric)', () {
      final e = run('''
easypaisa
Telenor Microfinance Bank
Bill Payment Successful
Paid to
K-Electric
Consumer No. 0400012345678
Amount Paid
Rs 8,430
Due Date 20/10/2026
Transaction ID 38291047561
04/10/2026 06:15 PM''');
      expect(e.amountMinor, 843000);
      expect(e.payee, 'K-Electric');
      expect(e.category, ExpenseCategory.bills);
      expect(e.type, ExpenseType.expense, reason: 'bill payment is an expense');
      expect(e.transactionId, '38291047561');
      // Due date is in the future → ignored; the payment date is used.
      expect(e.date, DateTime(2026, 10, 4, 18, 15));
    });

    test('4. foodpanda order — total, not subtotal', () {
      final e = run('''
foodpanda
Thank you for your order!
Order #q7xk-2931-ab12
Cheezious - Gulberg
Subtotal Rs. 1,050
Delivery fee Rs. 99
Platform fee Rs. 10
Total (incl. VAT) Rs. 1,159
Paid with card''');
      expect(e.amountMinor, 115900);
      expect(e.payee, 'foodpanda');
      expect(e.category, ExpenseCategory.food);
      expect(e.needsReview, isFalse);
    });

    test('5. Daraz order with Rs2,500/- format', () {
      final e = run('''
Daraz
Payment Successful
Your order has been placed
Order No. 401928375610294
Items total Rs2,499/-
Shipping Rs149/-
Grand Total Rs2,648/-''');
      expect(e.amountMinor, 264800);
      expect(e.payee, 'Daraz');
      expect(e.category, ExpenseCategory.shopping);
      expect(e.transactionId, '401928375610294');
    });

    test('6. Careem ride receipt', () {
      final e = run('''
Careem
Thanks for riding, Sara
Your trip with Imran
Total PKR 685.50
Paid by Careem Pay
Trip ID 9F3K28104''');
      expect(e.amountMinor, 68550);
      expect(e.payee, 'Careem');
      expect(e.category, ExpenseCategory.transport);
    });

    test('7. K-Electric online bill receipt', () {
      final e = run('''
K-Electric
Payment Receipt
We have received your payment
Account No: 0400 0123 4567
Bill Month: Sep 2026
Amount: Rs. 12,340.00
Payment Date: 3 Oct 2026
Ref No: KE-77120934''');
      expect(e.amountMinor, 1234000);
      expect(e.type, ExpenseType.expense);
      expect(e.payee, 'K-Electric');
      expect(e.category, ExpenseCategory.bills);
      expect(e.date, DateTime(2026, 10, 3, 12));
      expect(e.transactionId, 'KE-77120934');
    });

    test(r'8. US card receipt in $', () {
      final e = x.extract('''
Starbucks Coffee #10234
Seattle, WA
Grande Latte 5.45
Croissant 3.95
Subtotal \$9.40
Tax \$0.89
Tip \$2.70
TOTAL \$12.99
VISA **** 4421 APPROVED
10/04/2026 08:12 AM''', fallbackDate: DateTime(2026, 10, 5, 9), defaultCurrency: 'PKR')!;
      expect(e.amountMinor, 1299);
      expect(e.currency, 'USD');
      expect(e.payee, 'Starbucks');
      expect(e.category, ExpenseCategory.food);
      // US receipts are month-first.
      expect(e.date, DateTime(2026, 10, 4, 8, 12));
    });

    test('9. AED receipt (Carrefour Dubai)', () {
      final e = run('''
Carrefour
Mall of the Emirates
TAX INVOICE
Invoice No: 2026-118274
VAT 5% AED 2.14
Total AED 45.00
Card payment approved''');
      expect(e.amountMinor, 4500);
      expect(e.currency, 'AED');
      expect(e.payee, 'Carrefour');
      expect(e.category, ExpenseCategory.shopping);
    });

    test('10. income: money received (JazzCash)', () {
      final e = run('''
JazzCash
You have received Rs. 5,000
from Bilal Hussain
0321-7654321
TID 019283746501
05-10-2026 02:10 PM''');
      expect(e.type, ExpenseType.income);
      expect(e.amountMinor, 500000);
      expect(e.payee, 'Bilal Hussain');
    });

    test('11. INR and suffix currency formats', () {
      expect(run('Paid to Ravi Store\nAmount ₹1,200\nUPI Ref No 4021 9928 1234', currency: 'INR').amountMinor, 120000);
      final sar = run('Payment successful\nAmount paid\n1,250.50 SAR\nMerchant: Jarir Bookstore');
      expect(sar.amountMinor, 125050);
      expect(sar.currency, 'SAR');
      expect(sar.payee, 'Jarir Bookstore');
    });

    test('12. low confidence: amount only, no payee or payment words', () {
      final e = run('Rs 3,200\nMonday\nNotes for later');
      expect(e.amountMinor, 320000);
      expect(e.payee, isNull);
      expect(e.needsReview, isTrue);
    });

    test('13. balance is never the payment amount', () {
      final e = run('Rs. 750 sent to Usman Tariq\nAvailable balance Rs. 48,210.33\nTID 77283910021');
      expect(e.amountMinor, 75000);
      expect(e.payee, 'Usman Tariq');
    });

    test('14. amount printed without a currency uses the default', () {
      final e = run('Transfer successful\nTransfer Amount: 4,000.00\nTo: Hamza Iqbal', currency: 'PKR');
      expect(e.amountMinor, 400000);
      expect(e.currency, 'PKR');
      expect(e.currencyExplicit, isFalse);
      expect(e.payee, 'Hamza Iqbal');
    });

    test('no amount → null', () {
      expect(x.extract('Payment successful\nThank you', fallbackDate: shotAt), isNull);
    });
  });

  group('category mapping', () {
    const m = CategoryMapper();
    test('JazzCash is not the Jazz telco', () {
      expect(m.map(payee: 'Ali Khan', text: 'JazzCash Sent to Ali Khan').category, ExpenseCategory.transfers);
      expect(m.map(payee: 'Jazz', text: 'Mobile load').category, ExpenseCategory.bills);
    });
    test('more specific keyword wins', () {
      expect(m.map(payee: 'Uber Eats', text: '').category, ExpenseCategory.food);
      expect(m.map(payee: 'Uber', text: '').category, ExpenseCategory.transport);
    });
    test('learned merchant rule beats the built-in map', () {
      final rules = {payeeKey('Ali Khan')!: ExpenseCategory.education};
      final e = run('Rs. 2,500\nSent to\nAli Khan\nTID: 012345678901', rules: rules);
      expect(e.category, ExpenseCategory.education);
      expect(e.categoryFromRule, isTrue);
    });
    test('fallback is Other', () {
      expect(m.map(payee: null, text: 'Thank you').category, ExpenseCategory.other);
    });
    test('payee keys are stable', () {
      expect(payeeKey('  FOODPANDA  PK! '), 'foodpanda pk');
      expect(payeeKey('Ali Khan'), payeeKey('ali  khan'));
    });
  });

  group('dedupe', () {
    const d = ExpenseDedupe();
    final t = DateTime(2026, 10, 5, 22, 42);
    DedupeRef ref(int id, {int amount = 250000, String? payee = 'ali khan', String? tid, DateTime? at}) =>
        DedupeRef(id: id, amountMinor: amount, currency: 'PKR', payeeKey: payee, transactionId: tid, date: at ?? t);

    test('same TID → same transaction', () {
      final r = d.check(ref(0, tid: '0123-4567-8901'), [ref(7, tid: '012345678901', amount: 1)]);
      expect(r.kind, DedupeKind.sameTransaction);
      expect(r.matchId, 7);
    });
    test('different TIDs are different payments', () {
      expect(d.check(ref(0, tid: 'A1111'), [ref(1, tid: 'B2222')]).kind, DedupeKind.unique);
    });
    test('same amount + payee within 10 min without TID → likely duplicate', () {
      final r = d.check(ref(0), [ref(3, at: t.add(const Duration(minutes: 6)))]);
      expect(r.kind, DedupeKind.likelyDuplicate);
      expect(r.matchId, 3);
    });
    test('outside the window or different payee → unique', () {
      expect(d.check(ref(0), [ref(3, at: t.add(const Duration(minutes: 11)))]).kind, DedupeKind.unique);
      expect(d.check(ref(0), [ref(3, payee: 'sara')]).kind, DedupeKind.unique);
    });
    test('duplicate screenshots of one receipt end-to-end', () {
      const text = 'JazzCash\nRs. 2,500\nSent to\nAli Khan\n05 Oct 2026';
      final a = run(text);
      final b = x.extract(text, fallbackDate: shotAt.add(const Duration(minutes: 2)))!;
      DedupeRef toRef(int id, ExtractedExpense e) => DedupeRef(
          id: id, amountMinor: e.amountMinor, currency: e.currency, payeeKey: payeeKey(e.payee), transactionId: e.transactionId, date: e.date);
      expect(d.check(toRef(0, b), [toRef(1, a)]).kind, DedupeKind.likelyDuplicate);
    });
  });

  group('money', () {
    test('parses without doubles', () {
      expect(parseMinor('2,500'), 250000);
      expect(parseMinor('1,20,000'), 12000000);
      expect(parseMinor('12.9'), 1290);
      expect(parseMinor('0.07'), 7);
      expect(parseMinor('12.999'), isNull);
    });
    test('formats', () {
      expect(formatMoneyMinor(250000, 'PKR'), 'Rs 2,500');
      expect(formatMoneyMinor(1299, 'USD'), r'$12.99');
      expect(formatMoneyMinor(4500, 'AED'), 'AED 45');
      expect(formatMoneyCompact(12840000, 'PKR'), 'Rs 128k');
      expect(minorToDecimalString(250005), '2500.05');
    });
  });

  group('month summary', () {
    SpendEntry e(int id, int amount, DateTime d,
            {ExpenseType type = ExpenseType.expense, String cur = 'PKR', ExpenseCategory cat = ExpenseCategory.food, bool excluded = false, bool dup = false}) =>
        SpendEntry(id: id, amountMinor: amount, currency: cur, type: type, category: cat, date: d, isExcluded: excluded, isDuplicate: dup);

    test('totals, categories, comparison; income/excluded/duplicates not counted', () {
      final s = summarizeMonth([
        e(1, 100000, DateTime(2026, 10, 1)),
        e(2, 50000, DateTime(2026, 10, 1, 20), cat: ExpenseCategory.bills),
        e(3, 999999, DateTime(2026, 10, 2), type: ExpenseType.income),
        e(4, 70000, DateTime(2026, 10, 3), excluded: true),
        e(5, 100000, DateTime(2026, 10, 1, 0, 5), dup: true),
        e(6, 1299, DateTime(2026, 10, 4), cur: 'USD'),
        e(7, 120000, DateTime(2026, 9, 15)),
        e(8, 5000, DateTime(2026, 11, 1)),
      ], DateTime(2026, 10, 18), 'PKR');
      expect(s.totalMinor, 150000);
      expect(s.previousTotalMinor, 120000);
      expect(s.changePct, closeTo(25, 0.001));
      expect(s.byCategory.first.category, ExpenseCategory.food);
      expect(s.daily[0], 150000);
      expect(s.daily.length, 31);
      expect(s.totalsByCurrency, [('PKR', 150000), ('USD', 1299)]);
      expect(s.incomeByCurrency, [('PKR', 999999)]);
      expect(s.count, 3);
    });

    test('most frequent currency', () {
      expect(mostFrequentCurrency([e(1, 1, DateTime(2026)), e(2, 1, DateTime(2026), cur: 'AED'), e(3, 1, DateTime(2026), cur: 'AED')]), 'AED');
    });
  });
}
