import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/app_database.dart';
import '../data/expense_repository.dart';
import '../domain/expense/dedupe.dart';
import '../domain/expense/expense_category.dart';
import '../domain/expense/expense_extractor.dart';
import '../domain/expense/money.dart';
import 'prefs_keys.dart';

enum IngestKind { created, likelyDuplicate, sameTransaction, noAmount, alreadyLinked }

class IngestResult {
  const IngestResult(this.kind, [this.expense]);
  final IngestKind kind;
  final ExpenseView? expense;

  bool get added => kind == IngestKind.created || kind == IngestKind.likelyDuplicate;
}

class BackfillResult {
  const BackfillResult(this.count, this.totalsByCurrency);
  final int count;
  final Map<String, int> totalsByCurrency;
}

/// Currency defaults, stored in shared preferences so background engines see
/// the same value as the app.
abstract class CurrencyStore {
  String get defaultCurrency;
  bool get isManual;
  Future<void> setAuto(String currency);
}

/// Turns receipt screenshots into expenses (extraction + rules + dedupe) and
/// applies user edits. Used by the scan pipeline, the backfill, the UI and the
/// background job — the single place expenses are created.
class ExpenseService {
  ExpenseService({
    required this.repo,
    required this.currency,
    this.extractor = const ExpenseExtractor(),
    this.dedupe = const ExpenseDedupe(),
  });

  final ExpenseRepository repo;
  final CurrencyStore currency;
  final ExpenseExtractor extractor;
  final ExpenseDedupe dedupe;

  /// Called after anything changes spend (widgets refresh on it).
  VoidCallback? onChanged;

  Future<IngestResult> ingestScreenshot({
    required String assetId,
    required String? ocrText,
    required DateTime createdAt,
    Map<String, ExpenseCategory>? rules,
  }) async {
    if (await repo.hasForAsset(assetId)) return const IngestResult(IngestKind.alreadyLinked);
    final e = extractor.extract(
      ocrText,
      fallbackDate: createdAt,
      defaultCurrency: currency.defaultCurrency,
      rules: rules ?? await repo.rules(),
    );
    if (e == null) return const IngestResult(IngestKind.noAmount);

    final key = payeeKey(e.payee);
    final check = dedupe.check(
      DedupeRef(id: -1, amountMinor: e.amountMinor, currency: e.currency, payeeKey: key, transactionId: e.transactionId, date: e.date),
      await repo.dedupeCandidates(e.date, e.transactionId),
    );
    if (check.kind == DedupeKind.sameTransaction) {
      return IngestResult(IngestKind.sameTransaction, await repo.one(check.matchId!));
    }

    final now = DateTime.now();
    final id = await repo.insert(ExpensesCompanion.insert(
      assetId: Value(assetId),
      amountMinor: e.amountMinor,
      currency: e.currency,
      type: Value(e.type.name),
      payee: Value(e.payee),
      payeeKey: Value(key),
      transactionId: Value(e.transactionId),
      date: e.date,
      category: Value(e.category.name),
      source: const Value('auto'),
      confidence: Value(e.confidence),
      duplicateOfId: Value(check.kind == DedupeKind.likelyDuplicate ? check.matchId : null),
      createdAt: now,
      updatedAt: now,
    ));
    onChanged?.call();
    return IngestResult(
      check.kind == DedupeKind.likelyDuplicate ? IngestKind.likelyDuplicate : IngestKind.created,
      await repo.one(id),
    );
  }

  /// One-time pass over receipts scanned before Spend existed (v1 → v1.1).
  Future<BackfillResult> backfill() async {
    final rows = await repo.receiptsWithoutExpense();
    final rules = await repo.rules();
    var count = 0;
    final totals = <String, int>{};
    for (final r in rows) {
      try {
        final res = await ingestScreenshot(assetId: r.assetId, ocrText: r.ocrText, createdAt: r.createdAt, rules: rules);
        final x = res.expense;
        if (res.kind == IngestKind.created && x != null && x.type == ExpenseType.expense) {
          count++;
          totals[x.row.currency] = (totals[x.row.currency] ?? 0) + x.row.amountMinor;
        }
      } catch (e) {
        debugPrint('Backfill failed for ${r.assetId}: $e');
      }
    }
    await autoDetectCurrency();
    return BackfillResult(count, totals);
  }

  /// Keeps the default currency in sync with what the user actually spends in,
  /// unless they picked one by hand.
  Future<void> autoDetectCurrency() async {
    if (currency.isManual) return;
    final c = await repo.mostFrequentCurrency();
    if (c != null && c != currency.defaultCurrency) await currency.setAuto(c);
  }

  // -------------------------------------------------------------- Editing

  Future<void> setCategory(ExpenseView x, ExpenseCategory c) async {
    await repo.update(x.row.id, ExpensesCompanion(category: Value(c.name), isConfirmed: const Value(true)));
    final key = x.row.payeeKey;
    if (key != null) {
      // Learn: future receipts (and pending ones) from this payee use it.
      await repo.saveRule(key, c);
      await repo.applyRuleToUnconfirmed(key, c);
    }
    onChanged?.call();
  }

  Future<void> save(
    ExpenseView x, {
    ExpenseType? type,
    required int amountMinor,
    required String currencyCode,
    required String? payee,
    required ExpenseCategory category,
    required DateTime date,
    required String note,
  }) async {
    final p = payee?.trim().isEmpty ?? true ? null : payee!.trim();
    await repo.update(
      x.row.id,
      ExpensesCompanion(
        type: type == null ? const Value.absent() : Value(type.name),
        amountMinor: Value(amountMinor),
        currency: Value(currencyCode),
        payee: Value(p),
        payeeKey: Value(payeeKey(p)),
        date: Value(date),
        note: Value(note),
        isConfirmed: const Value(true),
        isExcluded: const Value(false),
        duplicateOfId: const Value(null),
      ),
    );
    if (category != x.category) {
      await setCategory((await repo.one(x.row.id))!, category);
    }
    onChanged?.call();
  }

  Future<int> addManual({
    required int amountMinor,
    required String currencyCode,
    required String? payee,
    required ExpenseCategory category,
    required DateTime date,
    required String note,
    ExpenseType type = ExpenseType.expense,
  }) async {
    final now = DateTime.now();
    final p = payee?.trim().isEmpty ?? true ? null : payee!.trim();
    final id = await repo.insert(ExpensesCompanion.insert(
      amountMinor: amountMinor,
      currency: currencyCode,
      type: Value(type.name),
      payee: Value(p),
      payeeKey: Value(payeeKey(p)),
      date: date,
      category: Value(category.name),
      note: Value(note),
      source: const Value('manual'),
      isConfirmed: const Value(true),
      createdAt: now,
      updatedAt: now,
    ));
    onChanged?.call();
    return id;
  }

  Future<void> setExcluded(int id, bool excluded) async {
    await repo.setExcluded(id, excluded);
    onChanged?.call();
  }

  Future<void> confirm(int id) async {
    await repo.confirm(id);
    onChanged?.call();
  }

  Future<void> delete(int id) async {
    await repo.delete(id);
    onChanged?.call();
  }

  /// "Rs 2,500 to Ali Khan" / "Rs 5,000 from Sara".
  static String describe(ExpenseView x) {
    final amount = formatMoneyMinor(x.row.amountMinor, x.row.currency);
    final p = x.row.payee;
    if (p == null) return amount;
    return '$amount ${x.type == ExpenseType.income ? 'from' : 'to'} $p';
  }
}

/// [CurrencyStore] straight on shared preferences (background engines).
class PrefsCurrencyStore implements CurrencyStore {
  PrefsCurrencyStore(this.prefs);
  final SharedPreferences prefs;

  @override
  String get defaultCurrency => prefs.getString(PrefsKeys.defaultCurrency) ?? 'PKR';

  @override
  bool get isManual => prefs.getBool(PrefsKeys.currencyManual) ?? false;

  @override
  Future<void> setAuto(String currency) => prefs.setString(PrefsKeys.defaultCurrency, currency);
}
