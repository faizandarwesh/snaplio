import 'package:drift/drift.dart';

import '../domain/cleanup_rules/cleanup_rules.dart';
import '../domain/entity_extractor/entity_extractor.dart';
import '../domain/models.dart';
import 'db/app_database.dart';

export 'db/app_database.dart' show ScreenshotRow, EntityRow, AppDatabase;

/// Snippet highlight markers (control chars never appear in OCR output).
const kHlStart = '\u0002';
const kHlEnd = '\u0003';

enum SortOrder { newest, oldest, largest }

enum DateFilter {
  today('Today'),
  week('This week'),
  month('This month'),
  older('Older');

  const DateFilter(this.label);
  final String label;
}

class CategoryStat {
  const CategoryStat(this.category, this.count, this.bytes, this.previewIds);
  final ScreenshotCategory category;
  final int count;
  final int bytes;
  final List<String> previewIds;
}

class LibraryStats {
  const LibraryStats({required this.total, required this.processed, required this.bytes});
  final int total;
  final int processed;
  final int bytes;
  static const empty = LibraryStats(total: 0, processed: 0, bytes: 0);
}

class SearchHit {
  const SearchHit(this.row, this.snippet);
  final ScreenshotRow row;

  /// Text excerpt with matches wrapped in [kHlStart] / [kHlEnd].
  final String? snippet;
}

/// New asset discovered in the gallery (before OCR).
class DiscoveredAsset {
  const DiscoveredAsset({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.width,
    required this.height,
  });
  final String id;
  final String fileName;
  final DateTime createdAt;
  final int width;
  final int height;
}

class ScreenshotRepository {
  ScreenshotRepository(this.db);

  final AppDatabase db;

  $ScreenshotsTable get _s => db.screenshots;
  $EntitiesTable get _e => db.entities;

  // ------------------------------------------------------------ Scan support

  Future<Set<String>> allAssetIds() async {
    final q = db.selectOnly(_s)..addColumns([_s.assetId]);
    final rows = await q.map((r) => r.read(_s.assetId)!).get();
    return rows.toSet();
  }

  Future<void> insertDiscovered(List<DiscoveredAsset> assets) async {
    if (assets.isEmpty) return;
    await db.batch((b) {
      b.insertAll(
        _s,
        [
          for (final a in assets)
            ScreenshotsCompanion.insert(
              assetId: a.id,
              fileName: a.fileName,
              createdAt: a.createdAt,
              width: Value(a.width),
              height: Value(a.height),
            ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<void> deleteByIds(Iterable<String> ids) async {
    final list = ids.toList();
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(i, (i + 500).clamp(0, list.length));
      await (db.delete(_s)..where((t) => t.assetId.isIn(chunk))).go();
    }
  }

  Future<List<ScreenshotRow>> nextUnprocessed(int limit) => (db.select(_s)
        ..where((t) => t.processedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(limit))
      .get();

  Future<int> unprocessedCount() async {
    final c = _s.assetId.count();
    final q = db.selectOnly(_s)
      ..addColumns([c])
      ..where(_s.processedAt.isNull());
    return (await q.map((r) => r.read(c)).getSingle()) ?? 0;
  }

  /// Writes OCR + analysis for one screenshot atomically.
  Future<void> saveResult({
    required ScreenshotRow row,
    required String? filePath,
    required int sizeBytes,
    required String? ocrText,
    required AnalysisResult analysis,
  }) {
    return db.transaction(() async {
      await (db.update(_s)..where((t) => t.assetId.equals(row.assetId))).write(
        ScreenshotsCompanion(
          filePath: Value(filePath),
          sizeBytes: Value(sizeBytes),
          ocrText: Value(ocrText),
          category: row.categoryLocked ? const Value.absent() : Value(analysis.category.name),
          sourceApp: Value(analysis.sourceApp),
          textHash: Value(analysis.textHash),
          processedAt: Value(DateTime.now()),
        ),
      );
      await (db.delete(_e)..where((t) => t.assetId.equals(row.assetId))).go();
      if (analysis.entities.isNotEmpty) {
        await db.batch((b) => b.insertAll(_e, [
              for (final e in analysis.entities)
                EntitiesCompanion.insert(
                  assetId: row.assetId,
                  type: e.type.name,
                  value: e.value,
                  displayValue: e.displayValue,
                ),
            ]));
      }
    });
  }

  /// Marks a screenshot as processed even when OCR failed, so the queue moves on.
  Future<void> markFailed(String assetId) =>
      (db.update(_s)..where((t) => t.assetId.equals(assetId))).write(ScreenshotsCompanion(processedAt: Value(DateTime.now())));

  Future<void> resetAllProcessing() => db.update(_s).write(const ScreenshotsCompanion(processedAt: Value(null)));

  // ------------------------------------------------------------------ Reads

  Stream<LibraryStats> watchStats() {
    return db
        .customSelect(
          'SELECT COUNT(*) AS total, '
          'COALESCE(SUM(processed_at IS NOT NULL), 0) AS processed, '
          'COALESCE(SUM(size_bytes), 0) AS bytes FROM screenshots',
          readsFrom: {_s},
        )
        .watchSingle()
        .map((r) => LibraryStats(
              total: r.read<int>('total'),
              processed: r.read<int>('processed'),
              bytes: r.read<int>('bytes'),
            ));
  }

  Stream<List<CategoryStat>> watchCategoryStats() {
    return db
        .customSelect(
          'SELECT category, COUNT(*) AS cnt, COALESCE(SUM(size_bytes), 0) AS bytes '
          'FROM screenshots WHERE processed_at IS NOT NULL GROUP BY category',
          readsFrom: {_s},
        )
        .watch()
        .asyncMap((rows) async {
      final previews = await db.customSelect(
        'SELECT asset_id, category FROM ('
        '  SELECT asset_id, category, ROW_NUMBER() OVER (PARTITION BY category ORDER BY created_at DESC) AS rn'
        '  FROM screenshots WHERE processed_at IS NOT NULL'
        ') WHERE rn <= 3',
      ).get();
      final byCat = <String, List<String>>{};
      for (final p in previews) {
        byCat.putIfAbsent(p.read<String>('category'), () => []).add(p.read<String>('asset_id'));
      }
      final stats = {
        for (final r in rows)
          r.read<String>('category'): CategoryStat(
            ScreenshotCategory.fromName(r.read<String>('category')),
            r.read<int>('cnt'),
            r.read<int>('bytes'),
            byCat[r.read<String>('category')] ?? const [],
          ),
      };
      // Always return every category, in display order.
      return [
        for (final c in ScreenshotCategory.values) stats[c.name] ?? CategoryStat(c, 0, 0, const []),
      ];
    });
  }

  Stream<List<ScreenshotRow>> watchRecent({int limit = 20}) => (db.select(_s)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(limit))
      .watch();

  Stream<List<ScreenshotRow>> watchCategory(ScreenshotCategory c, SortOrder sort) {
    final q = db.select(_s)
      ..where((t) => t.category.equals(c.name) & t.processedAt.isNotNull());
    q.orderBy([
      switch (sort) {
        SortOrder.newest => (t) => OrderingTerm.desc(t.createdAt),
        SortOrder.oldest => (t) => OrderingTerm.asc(t.createdAt),
        SortOrder.largest => (t) => OrderingTerm.desc(t.sizeBytes),
      },
    ]);
    return q.watch();
  }

  Stream<List<ScreenshotRow>> watchFavorites() => (db.select(_s)
        ..where((t) => t.isFavorite.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Stream<ScreenshotRow?> watchOne(String id) =>
      (db.select(_s)..where((t) => t.assetId.equals(id))).watchSingleOrNull();

  Stream<List<EntityRow>> watchEntities(String id) =>
      (db.select(_e)..where((t) => t.assetId.equals(id))).watch();

  Future<List<ScreenshotRow>> byIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = <ScreenshotRow>[];
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, (i + 500).clamp(0, ids.length));
      rows.addAll(await (db.select(_s)..where((t) => t.assetId.isIn(chunk))).get());
    }
    final order = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    rows.sort((a, b) => order[a.assetId]!.compareTo(order[b.assetId]!));
    return rows;
  }

  Future<List<String>> sourceApps() async {
    final rows = await db.customSelect(
      'SELECT source_app, COUNT(*) AS n FROM screenshots WHERE source_app IS NOT NULL '
      'GROUP BY source_app ORDER BY n DESC LIMIT 12',
    ).get();
    return [for (final r in rows) r.read<String>('source_app')];
  }

  // ----------------------------------------------------------------- Search

  /// Builds a safe FTS5 query: every token is quoted and prefix-matched.
  static String? ftsQuery(String input) {
    final tokens = input
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((t) => t.isNotEmpty)
        .take(8)
        .toList();
    if (tokens.isEmpty) return null;
    return tokens.map((t) => '"$t"*').join(' ');
  }

  static (DateTime?, DateTime?) dateRange(DateFilter? f, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (f) {
      null => (null, null),
      DateFilter.today => (today, null),
      DateFilter.week => (today.subtract(Duration(days: today.weekday - 1)), null),
      DateFilter.month => (DateTime(now.year, now.month), null),
      DateFilter.older => (null, DateTime(now.year, now.month)),
    };
  }

  Future<List<SearchHit>> search({
    required String query,
    Set<ScreenshotCategory> categories = const {},
    Set<String> apps = const {},
    DateFilter? date,
    int limit = 120,
  }) async {
    final fts = ftsQuery(query);
    final where = <String>['s.processed_at IS NOT NULL'];
    final vars = <Variable>[];

    if (categories.isNotEmpty) {
      where.add('s.category IN (${List.filled(categories.length, '?').join(',')})');
      vars.addAll(categories.map((c) => Variable.withString(c.name)));
    }
    if (apps.isNotEmpty) {
      where.add('s.source_app IN (${List.filled(apps.length, '?').join(',')})');
      vars.addAll(apps.map(Variable.withString));
    }
    final (from, to) = dateRange(date, DateTime.now());
    if (from != null) {
      where.add('s.created_at >= ?');
      vars.add(Variable.withDateTime(from));
    }
    if (to != null) {
      where.add('s.created_at < ?');
      vars.add(Variable.withDateTime(to));
    }

    final String sql;
    if (fts != null) {
      sql = 'SELECT s.*, snippet(screenshots_fts, 0, char(2), char(3), \'…\', 14) AS snip '
          'FROM screenshots_fts JOIN screenshots s ON s.rowid = screenshots_fts.rowid '
          'WHERE screenshots_fts MATCH ? AND ${where.join(' AND ')} '
          'ORDER BY bm25(screenshots_fts, 1.0, 0.4), s.created_at DESC LIMIT $limit';
      vars.insert(0, Variable.withString(fts));
    } else {
      if (categories.isEmpty && apps.isEmpty && date == null) return const [];
      sql = 'SELECT s.*, NULL AS snip FROM screenshots s WHERE ${where.join(' AND ')} '
          'ORDER BY s.created_at DESC LIMIT $limit';
    }

    final rows = await db.customSelect(sql, variables: vars, readsFrom: {_s}).get();
    return [
      for (final r in rows)
        SearchHit(
          await _s.mapFromRow(r),
          r.readNullable<String>('snip'),
        ),
    ];
  }

  // -------------------------------------------------------------- Mutations

  Future<void> setFavorite(Iterable<String> ids, bool value) =>
      (db.update(_s)..where((t) => t.assetId.isIn(ids.toList()))).write(ScreenshotsCompanion(isFavorite: Value(value)));

  Future<void> setCategory(String id, ScreenshotCategory c) =>
      (db.update(_s)..where((t) => t.assetId.equals(id))).write(
        ScreenshotsCompanion(category: Value(c.name), categoryLocked: const Value(true)),
      );

  // ---------------------------------------------------------------- Cleanup

  Stream<List<CleanupItem>> watchCleanupItems() {
    return db
        .customSelect(
          'SELECT asset_id, category, created_at, size_bytes, width, height, text_hash, is_favorite, '
          "CASE WHEN category = 'orders' THEN ocr_text ELSE NULL END AS ocr_text "
          'FROM screenshots WHERE processed_at IS NOT NULL',
          readsFrom: {_s},
        )
        .watch()
        .map((rows) => [
              for (final r in rows)
                CleanupItem(
                  assetId: r.read<String>('asset_id'),
                  category: ScreenshotCategory.fromName(r.read<String>('category')),
                  createdAt: r.read<DateTime>('created_at'),
                  sizeBytes: r.read<int>('size_bytes'),
                  width: r.read<int>('width'),
                  height: r.read<int>('height'),
                  textHash: r.readNullable<String>('text_hash'),
                  ocrText: r.readNullable<String>('ocr_text'),
                  isFavorite: r.read<bool>('is_favorite'),
                ),
            ]);
  }

  // ---------------------------------------------------------------- Receipts

  /// Sum of detected receipt totals since [since], per currency. Uses the
  /// largest amount on each receipt (the total, not line items).
  Stream<Map<String, double>> watchReceiptTotals(DateTime since) {
    return db
        .customSelect(
          'SELECT e.asset_id, e.value FROM entities e JOIN screenshots s ON s.asset_id = e.asset_id '
          "WHERE s.category = 'receipts' AND e.type = 'amount' AND s.created_at >= ?",
          variables: [Variable.withDateTime(since)],
          readsFrom: {_s, _e},
        )
        .watch()
        .map((rows) {
      final maxPerReceipt = <String, Map<String, double>>{};
      for (final r in rows) {
        final parsed = EntityExtractor.parseAmountValue(r.read<String>('value'));
        if (parsed == null) continue;
        final (cur, amount) = parsed;
        final m = maxPerReceipt.putIfAbsent(r.read<String>('asset_id'), () => {});
        if ((m[cur] ?? 0) < amount) m[cur] = amount;
      }
      final totals = <String, double>{};
      for (final m in maxPerReceipt.values) {
        m.forEach((cur, v) => totals[cur] = (totals[cur] ?? 0) + v);
      }
      return totals;
    });
  }
}
