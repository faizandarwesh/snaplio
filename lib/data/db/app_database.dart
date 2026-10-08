import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Screenshots, Entities])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults() : super(driftDatabase(name: 'snaplio'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createFts();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  /// External-content FTS5 index over `ocr_text` + `file_name`, kept in sync by
  /// triggers. Prefix queries (`wif*`) are served by the prefix index.
  Future<void> _createFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS screenshots_fts USING fts5(
        ocr_text, file_name,
        content='screenshots', content_rowid='rowid',
        tokenize='unicode61 remove_diacritics 2',
        prefix='2 3 4'
      )''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS screenshots_fts_ai AFTER INSERT ON screenshots BEGIN
        INSERT INTO screenshots_fts(rowid, ocr_text, file_name)
        VALUES (new.rowid, new.ocr_text, new.file_name);
      END''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS screenshots_fts_ad AFTER DELETE ON screenshots BEGIN
        INSERT INTO screenshots_fts(screenshots_fts, rowid, ocr_text, file_name)
        VALUES ('delete', old.rowid, old.ocr_text, old.file_name);
      END''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS screenshots_fts_au AFTER UPDATE OF ocr_text, file_name ON screenshots BEGIN
        INSERT INTO screenshots_fts(screenshots_fts, rowid, ocr_text, file_name)
        VALUES ('delete', old.rowid, old.ocr_text, old.file_name);
        INSERT INTO screenshots_fts(rowid, ocr_text, file_name)
        VALUES (new.rowid, new.ocr_text, new.file_name);
      END''');
  }
}
