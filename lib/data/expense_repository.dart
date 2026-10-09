import 'package:drift/drift.dart';

import '../domain/expense/dedupe.dart';
import '../domain/expense/expense_category.dart';
import '../domain/expense/expense_extractor.dart';
import '../domain/expense/spend_summary.dart';
import 'db/app_database.dart';

export 'db/app_database.dart' show ExpenseRow;

/// Expense with the receipt screenshot's file path for thumbnails.
class ExpenseView {
  const ExpenseView(this.row);
  final ExpenseRow row;

  ExpenseType get type => ExpenseType.fromName(row.type);
  ExpenseCategory get category => ExpenseCategory.fromName(row.category);
  bool get isDuplicate => row.duplicateOfId != null && !row.isConfirmed;
  bool get needsReview =>
      !row.isConfirmed && !row.isExcluded && (row.confidence < ExpenseExtractor.reviewThreshold || row.duplicateOfId != null);

  SpendEntry get entry => SpendEntry(
        id: row.id,
        amountMinor: row.amountMinor,
        currency: row.currency,
        type: type,
        category: category,
        date: row.date,
        isExcluded: row.isExcluded,
        isDuplicate: isDuplicate,
      );
}

class ExpenseRepository {
  ExpenseRepository(this.db);

  final AppDatabase db;

  $ExpensesTable get _x => db.expenses;

  // ------------------------------------------------------------------ Reads

  /// Expenses dated in [from, to), newest first.
  Stream<List<ExpenseView>> watchRange(DateTime from, DateTime to) => (db.select(_x)
        ..where((t) => t.date.isBiggerOrEqualValue(from) & t.date.isSmallerThanValue(to))
        ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.desc(t.id)]))
      .watch()
      .map((rows) => [for (final r in rows) ExpenseView(r)]);

  Future<List<ExpenseView>> range(DateTime from, DateTime to) async => [
        for (final r in await (db.select(_x)
              ..where((t) => t.date.isBiggerOrEqualValue(from) & t.date.isSmallerThanValue(to))
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get())
          ExpenseView(r),
      ];

  Stream<ExpenseView?> watchOne(int id) =>
      (db.select(_x)..where((t) => t.id.equals(id))).watchSingleOrNull().map((r) => r == null ? null : ExpenseView(r));

  Future<ExpenseView?> one(int id) async {
    final r = await (db.select(_x)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : ExpenseView(r);
  }

  Stream<ExpenseView?> watchForAsset(String assetId) => (db.select(_x)
        ..where((t) => t.assetId.equals(assetId))
        ..orderBy([(t) => OrderingTerm.asc(t.id)])
        ..limit(1))
      .watchSingleOrNull()
      .map((r) => r == null ? null : ExpenseView(r));

  Future<bool> hasForAsset(String assetId) async =>
      (await (db.select(_x)..where((t) => t.assetId.equals(assetId))..limit(1)).getSingleOrNull()) != null;

  Stream<List<ExpenseView>> watchNeedsReview() => (db.select(_x)
        ..where((t) =>
            t.isConfirmed.equals(false) &
            t.isExcluded.equals(false) &
            (t.confidence.isSmallerThanValue(ExpenseExtractor.reviewThreshold) | t.duplicateOfId.isNotNull()))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch()
      .map((rows) => [for (final r in rows) ExpenseView(r)]);

  /// Candidates for dedupe: anything within a day of [date] or with [tid].
  Future<List<DedupeRef>> dedupeCandidates(DateTime date, String? tid) async {
    final from = date.subtract(const Duration(days: 1));
    final to = date.add(const Duration(days: 1));
    final rows = await (db.select(_x)
          ..where((t) {
            final near = t.date.isBiggerOrEqualValue(from) & t.date.isSmallerOrEqualValue(to);
            return tid == null ? near : (near | t.transactionId.isNotNull());
          }))
        .get();
    return [
      for (final r in rows)
        DedupeRef(
          id: r.id,
          amountMinor: r.amountMinor,
          currency: r.currency,
          payeeKey: r.payeeKey,
          transactionId: r.transactionId,
          date: r.date,
        ),
    ];
  }

  /// Receipt screenshots that have no expense yet (for the backfill).
  Future<List<ScreenshotRow>> receiptsWithoutExpense() => db
      .customSelect(
        'SELECT s.* FROM screenshots s WHERE s.category = ? AND s.processed_at IS NOT NULL '
        'AND NOT EXISTS (SELECT 1 FROM expenses x WHERE x.asset_id = s.asset_id) ORDER BY s.created_at',
        variables: [Variable.withString('receipts')],
        readsFrom: {db.screenshots, _x},
      )
      .asyncMap((r) => db.screenshots.mapFromRow(r))
      .get();

  /// Most recent expense that counts as spend (widget "latest receipt").
  Future<ExpenseView?> latestCounted() async {
    final r = await (db.select(_x)
          ..where((t) => t.type.equals('expense') & t.isExcluded.equals(false) & t.duplicateOfId.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    return r == null ? null : ExpenseView(r);
  }

  Future<String?> mostFrequentCurrency() async {
    final r = await db.customSelect(
      "SELECT currency, COUNT(*) AS n FROM expenses WHERE type = 'expense' AND is_excluded = 0 "
      'GROUP BY currency ORDER BY n DESC LIMIT 1',
    ).getSingleOrNull();
    return r?.read<String>('currency');
  }

  Future<Map<String, ExpenseCategory>> rules() async => {
        for (final r in await db.select(db.merchantRules).get()) r.payeeKey: ExpenseCategory.fromName(r.category),
      };

  // -------------------------------------------------------------- Mutations

  Future<int> insert(ExpensesCompanion c) => db.into(_x).insert(c);

  Future<void> update(int id, ExpensesCompanion c) =>
      (db.update(_x)..where((t) => t.id.equals(id))).write(c.copyWith(updatedAt: Value(DateTime.now())));

  Future<void> setExcluded(int id, bool excluded) => update(
        id,
        ExpensesCompanion(isExcluded: Value(excluded), isConfirmed: Value(!excluded)),
      );

  /// "Looks right": counts it even if it was a suspected duplicate.
  Future<void> confirm(int id) =>
      update(id, const ExpensesCompanion(isConfirmed: Value(true), isExcluded: Value(false), duplicateOfId: Value(null)));

  Future<void> delete(int id) => (db.delete(_x)..where((t) => t.id.equals(id))).go();

  Future<void> deleteUnconfirmedAutoForAsset(String assetId) => (db.delete(_x)
        ..where((t) => t.assetId.equals(assetId) & t.source.equals('auto') & t.isConfirmed.equals(false)))
      .go();

  Future<void> saveRule(String payeeKey, ExpenseCategory c) => db.into(db.merchantRules).insertOnConflictUpdate(
        MerchantRulesCompanion.insert(payeeKey: payeeKey, category: c.name, updatedAt: DateTime.now()),
      );

  /// Applies a learned category to other unconfirmed expenses from the payee.
  Future<void> applyRuleToUnconfirmed(String payeeKey, ExpenseCategory c) => (db.update(_x)
        ..where((t) => t.payeeKey.equals(payeeKey) & t.isConfirmed.equals(false)))
      .write(ExpensesCompanion(category: Value(c.name), updatedAt: Value(DateTime.now())));
}
