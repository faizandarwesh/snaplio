import 'package:drift/drift.dart' show driftRuntimeOptions, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_lio/data/db/app_database.dart';
import 'package:snap_lio/data/screenshot_repository.dart';
import 'package:snap_lio/domain/analyzer.dart';
import 'package:snap_lio/domain/models.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ScreenshotRepository repo;
  const analyzer = ScreenshotAnalyzer();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ScreenshotRepository(db);
  });
  tearDown(() => db.close());

  Future<void> addScanned(String id, String text, {DateTime? at, String file = 'Screenshot_1.png'}) async {
    await repo.insertDiscovered([
      DiscoveredAsset(id: id, fileName: file, createdAt: at ?? DateTime(2026, 10, 1), width: 1080, height: 2400),
    ]);
    final row = (await repo.byIds([id])).single;
    await repo.saveResult(
      row: row,
      filePath: '/x/$id.png',
      sizeBytes: 1000,
      ocrText: text,
      analysis: analyzer.analyze(fileName: file, text: text),
    );
  }

  test('scan queue: discovered rows are unprocessed until saved', () async {
    await repo.insertDiscovered([
      DiscoveredAsset(id: 'a', fileName: 'Screenshot_a.png', createdAt: DateTime(2026, 1, 1), width: 1, height: 1),
      DiscoveredAsset(id: 'b', fileName: 'Screenshot_b.png', createdAt: DateTime(2026, 2, 1), width: 1, height: 1),
    ]);
    expect(await repo.unprocessedCount(), 2);
    final next = await repo.nextUnprocessed(8);
    expect(next.map((r) => r.assetId), ['b', 'a'], reason: 'newest first');
  });

  test('FTS prefix search with highlighted snippet', () async {
    await addScanned('wifi', 'Home WiFi password: sunflower2026\nNetwork 5G');
    await addScanned('otp', 'Your OTP is 482913. Do not share.');

    final hits = await repo.search(query: 'wif pass');
    expect(hits.map((h) => h.row.assetId), ['wifi']);
    expect(hits.single.snippet, contains('${kHlStart}WiFi$kHlEnd'));

    final otp = await repo.search(query: 'otp');
    expect(otp.single.row.category, ScreenshotCategory.otp.name);
  });

  test('FTS stays in sync on update and delete', () async {
    await addScanned('x', 'first text about apples and more words');
    expect(await repo.search(query: 'apples'), hasLength(1));

    final row = (await repo.byIds(['x'])).single;
    await repo.saveResult(
      row: row,
      filePath: null,
      sizeBytes: 1,
      ocrText: 'now about bananas',
      analysis: analyzer.analyze(fileName: 'f.png', text: 'now about bananas'),
    );
    expect(await repo.search(query: 'apples'), isEmpty);
    expect(await repo.search(query: 'banana'), hasLength(1));

    await repo.deleteByIds(['x']);
    expect(await repo.search(query: 'banana'), isEmpty);
  });

  test('entities cascade and manual category is preserved on rescan', () async {
    await addScanned('r', 'Transaction Successful Rs. 2,500 paid TID 1234');
    await repo.setCategory('r', ScreenshotCategory.notes);
    final row = (await repo.byIds(['r'])).single;
    await repo.saveResult(
      row: row,
      filePath: null,
      sizeBytes: 1,
      ocrText: row.ocrText,
      analysis: analyzer.analyze(fileName: 'f.png', text: row.ocrText),
    );
    expect((await repo.byIds(['r'])).single.category, 'notes');

    await repo.deleteByIds(['r']);
    final ents = await db.select(db.entities).get();
    expect(ents, isEmpty);
  });

  test('category stats and receipt totals', () async {
    final now = DateTime.now();
    await addScanned('r1', 'Payment successful. Total Rs. 1,000', at: now);
    await addScanned('r2', 'Invoice paid\nSubtotal Rs 400\nTotal Rs 500', at: now);
    final stats = await repo.watchCategoryStats().first;
    expect(stats.firstWhere((s) => s.category == ScreenshotCategory.receipts).count, 2);
    final totals = await repo.watchReceiptTotals(DateTime(now.year, now.month)).first;
    expect(totals['PKR'], 1500);
  });

  test('search performance on 5,000 rows', () async {
    final words = ['invoice', 'wifi', 'meeting', 'flight', 'delivery', 'password', 'karachi', 'lahore'];
    await db.batch((b) {
      b.insertAll(db.screenshots, [
        for (var i = 0; i < 5000; i++)
          ScreenshotsCompanion.insert(
            assetId: 'id$i',
            fileName: 'Screenshot_$i.png',
            createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
            ocrText: Value('Sample text $i ${words[i % words.length]} lorem ipsum dolor sit amet consectetur'),
            processedAt: Value(DateTime(2026, 2, 1)),
          ),
      ]);
    });
    final sw = Stopwatch()..start();
    final hits = await repo.search(query: 'wif');
    sw.stop();
    expect(hits, isNotEmpty);
    // ignore: avoid_print
    print('FTS search on 5k rows: ${sw.elapsedMilliseconds}ms');
    expect(sw.elapsedMilliseconds, lessThan(200));
  });
}
