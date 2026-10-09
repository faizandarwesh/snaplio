import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_lio/data/expense_repository.dart';
import 'package:snap_lio/data/recap_repository.dart';
import 'package:snap_lio/data/screenshot_repository.dart';
import 'package:snap_lio/domain/analyzer.dart';
import 'package:snap_lio/services/prefs_keys.dart';
import 'package:snap_lio/services/recap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('runIfDue builds the week once, stores it, and remembers it', () async {
    SharedPreferences.setMockInitialValues({PrefsKeys.defaultCurrency: 'PKR'});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final shots = ScreenshotRepository(db);
    final recaps = RecapRepository(db);
    final service = RecapService(prefs: prefs, shots: shots, expenses: ExpenseRepository(db), recaps: recaps);

    // Three screenshots in the week ending Sunday 2026-10-11 19:00.
    for (final (id, day, text) in [
      ('1', 6, 'https://www.example.com/read-later'),
      ('2', 7, 'just some meeting notes for the team with a few more words here'),
      ('3', 8, 'Your OTP is 4821'),
    ]) {
      await shots.insertDiscovered([DiscoveredAsset(id: id, fileName: 'Screenshot_$id.png', createdAt: DateTime(2026, 10, day, 12), width: 1, height: 1)]);
      final row = (await shots.byIds([id])).single;
      await shots.saveResult(row: row, filePath: null, sizeBytes: 1000, ocrText: text, analysis: const ScreenshotAnalyzer().analyze(fileName: row.fileName, text: text));
    }

    expect(await service.runIfDue(now: DateTime(2026, 10, 11, 18)), isNull, reason: 'not time yet');
    final id = await service.runIfDue(now: DateTime(2026, 10, 11, 19, 2));
    expect(id, isNotNull);
    final stored = (await recaps.watchAll().first).single;
    expect(stored.recap.screenshots, 3);
    expect(stored.recap.unreadLinks, 1);
    expect(stored.recap.links.single.host, 'example.com');

    expect(await service.runIfDue(now: DateTime(2026, 10, 11, 21)), isNull, reason: 'once per week');

    // Opening the link means it no longer counts next week.
    await shots.markLinkOpened('1', 'https://www.example.com/read-later');
    expect(await shots.unreadLinkCount(), 0);
  });
}
