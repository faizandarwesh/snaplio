import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_lio/data/screenshot_repository.dart';

/// The exact v1 (SnapLio 1.0) schema, dumped from the shipped build.
const _v1 = [
  '''CREATE TABLE "screenshots" ("asset_id" TEXT NOT NULL, "file_path" TEXT NULL, "file_name" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "width" INTEGER NOT NULL DEFAULT 0, "height" INTEGER NOT NULL DEFAULT 0, "size_bytes" INTEGER NOT NULL DEFAULT 0, "ocr_text" TEXT NULL, "category" TEXT NOT NULL DEFAULT 'others', "category_locked" INTEGER NOT NULL DEFAULT 0 CHECK ("category_locked" IN (0, 1)), "source_app" TEXT NULL, "is_favorite" INTEGER NOT NULL DEFAULT 0 CHECK ("is_favorite" IN (0, 1)), "text_hash" TEXT NULL, "processed_at" INTEGER NULL, PRIMARY KEY ("asset_id"))''',
  'CREATE TABLE "entities" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "asset_id" TEXT NOT NULL REFERENCES screenshots (asset_id) ON DELETE CASCADE, "type" TEXT NOT NULL, "value" TEXT NOT NULL, "display_value" TEXT NOT NULL)',
  'CREATE INDEX idx_screenshots_processed ON screenshots (processed_at)',
  'CREATE INDEX idx_screenshots_category_created ON screenshots (category, created_at)',
  'CREATE INDEX idx_screenshots_created ON screenshots (created_at)',
  'CREATE INDEX idx_screenshots_hash ON screenshots (text_hash)',
  'CREATE INDEX idx_entities_asset ON entities (asset_id)',
  'CREATE INDEX idx_entities_type ON entities (type)',
  """CREATE VIRTUAL TABLE screenshots_fts USING fts5(ocr_text, file_name, content='screenshots', content_rowid='rowid', tokenize='unicode61 remove_diacritics 2', prefix='2 3 4')""",
  '''CREATE TRIGGER screenshots_fts_ai AFTER INSERT ON screenshots BEGIN
    INSERT INTO screenshots_fts(rowid, ocr_text, file_name) VALUES (new.rowid, new.ocr_text, new.file_name);
  END''',
  '''CREATE TRIGGER screenshots_fts_ad AFTER DELETE ON screenshots BEGIN
    INSERT INTO screenshots_fts(screenshots_fts, rowid, ocr_text, file_name) VALUES ('delete', old.rowid, old.ocr_text, old.file_name);
  END''',
  '''CREATE TRIGGER screenshots_fts_au AFTER UPDATE OF ocr_text, file_name ON screenshots BEGIN
    INSERT INTO screenshots_fts(screenshots_fts, rowid, ocr_text, file_name) VALUES ('delete', old.rowid, old.ocr_text, old.file_name);
    INSERT INTO screenshots_fts(rowid, ocr_text, file_name) VALUES (new.rowid, new.ocr_text, new.file_name);
  END''',
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('v1 → v2 keeps every row, favorite, manual category and search', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      if (raw.userVersion != 0) return;
      for (final sql in _v1) {
        raw.execute(sql);
      }
      raw.execute(
        "INSERT INTO screenshots (asset_id, file_name, created_at, size_bytes, ocr_text, category, category_locked, is_favorite, processed_at) VALUES "
        "('r1', 'Screenshot_1.png', 1790000000, 1200, 'JazzCash Rs. 2,500 Sent to Ali Khan TID 012345678901', 'receipts', 0, 1, 1790000100), "
        "('n1', 'Screenshot_2.png', 1790000500, 900, 'meeting notes wifi password', 'notes', 1, 0, 1790000600)",
      );
      raw.execute("INSERT INTO entities (asset_id, type, value, display_value) VALUES ('r1', 'url', 'https://example.com', 'example.com')");
      raw.userVersion = 1;
    }));
    final repo = ScreenshotRepository(db);

    final rows = await repo.byIds(['r1', 'n1']);
    expect(rows, hasLength(2));
    expect(rows.first.isFavorite, isTrue);
    expect(rows.last.categoryLocked, isTrue);
    expect(rows.first.claimedAt, isNull);

    final ents = await repo.entitiesOf('r1');
    expect(ents.single.openedAt, isNull);

    // FTS index and triggers still work after the upgrade.
    final hits = await repo.search(query: 'wifi');
    expect(hits.single.row.assetId, 'n1');

    // New tables exist and are usable.
    expect(await db.select(db.expenses).get(), isEmpty);
    expect(await db.select(db.merchantRules).get(), isEmpty);
    expect(await db.select(db.recaps).get(), isEmpty);
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), 2);
    await db.close();
  });
}
