import 'package:drift/drift.dart';

@DataClassName('ScreenshotRow')
@TableIndex(name: 'idx_screenshots_processed', columns: {#processedAt})
@TableIndex(name: 'idx_screenshots_category_created', columns: {#category, #createdAt})
@TableIndex(name: 'idx_screenshots_created', columns: {#createdAt})
@TableIndex(name: 'idx_screenshots_hash', columns: {#textHash})
class Screenshots extends Table {
  TextColumn get assetId => text()();
  TextColumn get filePath => text().nullable()();
  TextColumn get fileName => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get width => integer().withDefault(const Constant(0))();
  IntColumn get height => integer().withDefault(const Constant(0))();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  TextColumn get ocrText => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('others'))();

  /// True when the user changed the category by hand; re-scans keep it.
  BoolColumn get categoryLocked => boolean().withDefault(const Constant(false))();
  TextColumn get sourceApp => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get textHash => text().nullable()();

  /// Null = not scanned yet. Makes the scan resumable.
  DateTimeColumn get processedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {assetId};
}

@DataClassName('EntityRow')
@TableIndex(name: 'idx_entities_asset', columns: {#assetId})
@TableIndex(name: 'idx_entities_type', columns: {#type})
class Entities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get assetId => text().references(Screenshots, #assetId, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get value => text()();
  TextColumn get displayValue => text()();
}
