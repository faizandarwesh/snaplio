import 'package:drift/drift.dart';

import '../domain/recap/weekly_recap.dart';
import 'db/app_database.dart';

class StoredRecap {
  const StoredRecap(this.id, this.createdAt, this.recap);
  final int id;
  final DateTime createdAt;
  final WeeklyRecap recap;

  static StoredRecap of(RecapRow r) => StoredRecap(r.id, r.createdAt, WeeklyRecap.decode(r.payload));
}

class RecapRepository {
  RecapRepository(this.db);
  final AppDatabase db;

  $RecapsTable get _r => db.recaps;

  /// One recap per week: regenerating the same week replaces it.
  Future<int> upsert(WeeklyRecap recap) async {
    final existing = await (db.select(_r)..where((t) => t.weekStart.equals(recap.weekStart))).getSingleOrNull();
    if (existing != null) {
      await (db.update(_r)..where((t) => t.id.equals(existing.id)))
          .write(RecapsCompanion(payload: Value(recap.encode()), createdAt: Value(DateTime.now())));
      return existing.id;
    }
    return db.into(_r).insert(RecapsCompanion.insert(
          weekStart: recap.weekStart,
          weekEnd: recap.weekEnd,
          createdAt: DateTime.now(),
          payload: recap.encode(),
        ));
  }

  Future<void> markNotified(int id) =>
      (db.update(_r)..where((t) => t.id.equals(id))).write(RecapsCompanion(notifiedAt: Value(DateTime.now())));

  Stream<List<StoredRecap>> watchAll() => (db.select(_r)..orderBy([(t) => OrderingTerm.desc(t.weekStart)]))
      .watch()
      .map((rows) => [for (final r in rows) StoredRecap.of(r)]);

  Stream<StoredRecap?> watchOne(int id) =>
      (db.select(_r)..where((t) => t.id.equals(id))).watchSingleOrNull().map((r) => r == null ? null : StoredRecap.of(r));
}
