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

  /// Set while one scanner (foreground isolate or the background job engine)
  /// owns this row. Claimed with a conditional UPDATE, so two engines never
  /// process — or notify about — the same screenshot. (v2)
  DateTimeColumn get claimedAt => dateTime().nullable()();

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

  /// When the user last opened this link from the app or a notification (v2).
  DateTimeColumn get openedAt => dateTime().nullable()();
}

@DataClassName('ExpenseRow')
@TableIndex(name: 'idx_expenses_date', columns: {#date})
@TableIndex(name: 'idx_expenses_asset', columns: {#assetId})
@TableIndex(name: 'idx_expenses_tid', columns: {#transactionId})
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Null for manual entries. Kept (set null) if the screenshot is deleted so
  /// spend history survives a cleanup.
  TextColumn get assetId =>
      text().nullable().references(Screenshots, #assetId, onDelete: KeyAction.setNull)();

  /// Money is always integer minor units (paisa, cents) — never double.
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();

  /// `expense` | `income`.
  TextColumn get type => text().withDefault(const Constant('expense'))();
  TextColumn get payee => text().nullable()();

  /// Normalized payee used for merchant rules and dedupe.
  TextColumn get payeeKey => text().nullable()();
  TextColumn get transactionId => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// `auto` | `manual`.
  TextColumn get source => text().withDefault(const Constant('auto'))();
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(false))();
  BoolColumn get isExcluded => boolean().withDefault(const Constant(false))();

  /// Set when this looks like a repeat of another expense (same amount + payee
  /// within 10 minutes). Not counted until the user confirms it.
  IntColumn get duplicateOfId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Category learned from a user correction, applied to future receipts.
@DataClassName('MerchantRuleRow')
class MerchantRules extends Table {
  TextColumn get payeeKey => text()();
  TextColumn get category => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {payeeKey};
}

/// One generated weekly recap. Numbers are frozen at generation time.
@DataClassName('RecapRow')
@TableIndex(name: 'idx_recaps_week', columns: {#weekStart}, unique: true)
class Recaps extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get weekStart => dateTime()();
  DateTimeColumn get weekEnd => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  /// Serialized `WeeklyRecap` (see domain/recap).
  TextColumn get payload => text()();
  DateTimeColumn get notifiedAt => dateTime().nullable()();
}
