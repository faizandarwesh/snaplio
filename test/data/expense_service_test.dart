import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_lio/data/expense_repository.dart';
import 'package:snap_lio/data/screenshot_repository.dart';
import 'package:snap_lio/domain/analyzer.dart';
import 'package:snap_lio/domain/expense/expense_category.dart';
import 'package:snap_lio/services/expense_service.dart';

class _Currency implements CurrencyStore {
  @override
  String defaultCurrency = 'PKR';
  @override
  bool isManual = false;
  @override
  Future<void> setAuto(String c) async => defaultCurrency = c;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ScreenshotRepository shots;
  late ExpenseRepository repo;
  late ExpenseService service;
  late _Currency currency;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    shots = ScreenshotRepository(db);
    repo = ExpenseRepository(db);
    currency = _Currency();
    service = ExpenseService(repo: repo, currency: currency);
  });
  tearDown(() => db.close());

  Future<void> addReceipt(String id, String text, DateTime at) async {
    await shots.insertDiscovered([DiscoveredAsset(id: id, fileName: 'Screenshot_$id.png', createdAt: at, width: 1, height: 1)]);
    final row = (await shots.byIds([id])).single;
    await shots.saveResult(
      row: row,
      filePath: null,
      sizeBytes: 1,
      ocrText: text,
      analysis: const ScreenshotAnalyzer().analyze(fileName: row.fileName, text: text),
    );
  }

  Future<IngestResult> ingest(String id, String text, DateTime when) async {
    await shots.insertDiscovered([DiscoveredAsset(id: id, fileName: 'Screenshot_$id.png', createdAt: when, width: 1, height: 1)]);
    return service.ingestScreenshot(assetId: id, ocrText: text, createdAt: when);
  }

  const jazz = 'JazzCash\nTransaction Successful\nRs. 2,500\nSent to\nAli Khan\nTID: 012345678901';
  final at = DateTime(2026, 10, 5, 22, 42);

  test('backfill creates expenses for existing receipts, skips repeats by TID', () async {
    await addReceipt('a', jazz, at);
    await addReceipt('b', jazz, at.add(const Duration(minutes: 1))); // same TID
    await addReceipt('c', 'foodpanda\nPayment successful\nTotal Rs. 1,159', at);
    await addReceipt('n', 'just some notes about a meeting with lots of words in it', at);

    final r = await service.backfill();
    expect(r.count, 2);
    expect(r.totalsByCurrency['PKR'], 250000 + 115900);
    final all = await repo.range(DateTime(2026), DateTime(2027));
    expect(all, hasLength(2));
    // Running again doesn't double anything.
    expect((await service.backfill()).count, 0);
  });

  test('same amount + payee within 10 min without TID is held for review', () async {
    const noTid = 'Payment successful\nRs. 900\nPaid to\nCafe Aylanto';
    final first = await ingest('x', noTid, at);
    final second = await ingest('y', noTid, at.add(const Duration(minutes: 4)));
    expect(first.kind, IngestKind.created);
    expect(second.kind, IngestKind.likelyDuplicate);
    expect(second.expense!.needsReview, isTrue);
    expect(second.expense!.entry.countsAsSpend, isFalse);

    await service.confirm(second.expense!.row.id);
    expect((await repo.one(second.expense!.row.id))!.entry.countsAsSpend, isTrue);
  });

  test('category correction is learned for the payee', () async {
    final a = await ingest('a', jazz, at);
    expect(a.expense!.category, ExpenseCategory.transfers);
    await service.setCategory(a.expense!, ExpenseCategory.education);

    final next = await ingest('b', 'JazzCash\nRs. 8,000\nSent to\nALI  KHAN\nTID: 99887766554', at.add(const Duration(days: 3)),
    );
    expect(next.expense!.category, ExpenseCategory.education);
  });

  test('excluded expenses stop counting; default currency follows receipts', () async {
    final a = await ingest('a', 'Payment successful\nTotal AED 45.00\nMerchant: Carrefour', at);
    await ingest('b', 'Paid to Lulu\nAmount AED 12', at);
    await service.autoDetectCurrency();
    expect(currency.defaultCurrency, 'AED');

    await service.setExcluded(a.expense!.row.id, true);
    expect((await repo.one(a.expense!.row.id))!.entry.countsAsSpend, isFalse);
  });
}
