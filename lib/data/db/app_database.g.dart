// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ScreenshotsTable extends Screenshots
    with TableInfo<$ScreenshotsTable, ScreenshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScreenshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('others'),
  );
  static const VerificationMeta _categoryLockedMeta = const VerificationMeta(
    'categoryLocked',
  );
  @override
  late final GeneratedColumn<bool> categoryLocked = GeneratedColumn<bool>(
    'category_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("category_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceAppMeta = const VerificationMeta(
    'sourceApp',
  );
  @override
  late final GeneratedColumn<String> sourceApp = GeneratedColumn<String>(
    'source_app',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _textHashMeta = const VerificationMeta(
    'textHash',
  );
  @override
  late final GeneratedColumn<String> textHash = GeneratedColumn<String>(
    'text_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<DateTime> processedAt = GeneratedColumn<DateTime>(
    'processed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _claimedAtMeta = const VerificationMeta(
    'claimedAt',
  );
  @override
  late final GeneratedColumn<DateTime> claimedAt = GeneratedColumn<DateTime>(
    'claimed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    assetId,
    filePath,
    fileName,
    createdAt,
    width,
    height,
    sizeBytes,
    ocrText,
    category,
    categoryLocked,
    sourceApp,
    isFavorite,
    textHash,
    processedAt,
    claimedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'screenshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScreenshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('category_locked')) {
      context.handle(
        _categoryLockedMeta,
        categoryLocked.isAcceptableOrUnknown(
          data['category_locked']!,
          _categoryLockedMeta,
        ),
      );
    }
    if (data.containsKey('source_app')) {
      context.handle(
        _sourceAppMeta,
        sourceApp.isAcceptableOrUnknown(data['source_app']!, _sourceAppMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('text_hash')) {
      context.handle(
        _textHashMeta,
        textHash.isAcceptableOrUnknown(data['text_hash']!, _textHashMeta),
      );
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    }
    if (data.containsKey('claimed_at')) {
      context.handle(
        _claimedAtMeta,
        claimedAt.isAcceptableOrUnknown(data['claimed_at']!, _claimedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  ScreenshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScreenshotRow(
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      categoryLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}category_locked'],
      )!,
      sourceApp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_app'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      textHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_hash'],
      ),
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}processed_at'],
      ),
      claimedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}claimed_at'],
      ),
    );
  }

  @override
  $ScreenshotsTable createAlias(String alias) {
    return $ScreenshotsTable(attachedDatabase, alias);
  }
}

class ScreenshotRow extends DataClass implements Insertable<ScreenshotRow> {
  final String assetId;
  final String? filePath;
  final String fileName;
  final DateTime createdAt;
  final int width;
  final int height;
  final int sizeBytes;
  final String? ocrText;
  final String category;

  /// True when the user changed the category by hand; re-scans keep it.
  final bool categoryLocked;
  final String? sourceApp;
  final bool isFavorite;
  final String? textHash;

  /// Null = not scanned yet. Makes the scan resumable.
  final DateTime? processedAt;

  /// Set while one scanner (foreground isolate or the background job engine)
  /// owns this row. Claimed with a conditional UPDATE, so two engines never
  /// process — or notify about — the same screenshot. (v2)
  final DateTime? claimedAt;
  const ScreenshotRow({
    required this.assetId,
    this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.width,
    required this.height,
    required this.sizeBytes,
    this.ocrText,
    required this.category,
    required this.categoryLocked,
    this.sourceApp,
    required this.isFavorite,
    this.textHash,
    this.processedAt,
    this.claimedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['file_name'] = Variable<String>(fileName);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    map['category'] = Variable<String>(category);
    map['category_locked'] = Variable<bool>(categoryLocked);
    if (!nullToAbsent || sourceApp != null) {
      map['source_app'] = Variable<String>(sourceApp);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || textHash != null) {
      map['text_hash'] = Variable<String>(textHash);
    }
    if (!nullToAbsent || processedAt != null) {
      map['processed_at'] = Variable<DateTime>(processedAt);
    }
    if (!nullToAbsent || claimedAt != null) {
      map['claimed_at'] = Variable<DateTime>(claimedAt);
    }
    return map;
  }

  ScreenshotsCompanion toCompanion(bool nullToAbsent) {
    return ScreenshotsCompanion(
      assetId: Value(assetId),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      fileName: Value(fileName),
      createdAt: Value(createdAt),
      width: Value(width),
      height: Value(height),
      sizeBytes: Value(sizeBytes),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      category: Value(category),
      categoryLocked: Value(categoryLocked),
      sourceApp: sourceApp == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceApp),
      isFavorite: Value(isFavorite),
      textHash: textHash == null && nullToAbsent
          ? const Value.absent()
          : Value(textHash),
      processedAt: processedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAt),
      claimedAt: claimedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(claimedAt),
    );
  }

  factory ScreenshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScreenshotRow(
      assetId: serializer.fromJson<String>(json['assetId']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      category: serializer.fromJson<String>(json['category']),
      categoryLocked: serializer.fromJson<bool>(json['categoryLocked']),
      sourceApp: serializer.fromJson<String?>(json['sourceApp']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      textHash: serializer.fromJson<String?>(json['textHash']),
      processedAt: serializer.fromJson<DateTime?>(json['processedAt']),
      claimedAt: serializer.fromJson<DateTime?>(json['claimedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'filePath': serializer.toJson<String?>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'ocrText': serializer.toJson<String?>(ocrText),
      'category': serializer.toJson<String>(category),
      'categoryLocked': serializer.toJson<bool>(categoryLocked),
      'sourceApp': serializer.toJson<String?>(sourceApp),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'textHash': serializer.toJson<String?>(textHash),
      'processedAt': serializer.toJson<DateTime?>(processedAt),
      'claimedAt': serializer.toJson<DateTime?>(claimedAt),
    };
  }

  ScreenshotRow copyWith({
    String? assetId,
    Value<String?> filePath = const Value.absent(),
    String? fileName,
    DateTime? createdAt,
    int? width,
    int? height,
    int? sizeBytes,
    Value<String?> ocrText = const Value.absent(),
    String? category,
    bool? categoryLocked,
    Value<String?> sourceApp = const Value.absent(),
    bool? isFavorite,
    Value<String?> textHash = const Value.absent(),
    Value<DateTime?> processedAt = const Value.absent(),
    Value<DateTime?> claimedAt = const Value.absent(),
  }) => ScreenshotRow(
    assetId: assetId ?? this.assetId,
    filePath: filePath.present ? filePath.value : this.filePath,
    fileName: fileName ?? this.fileName,
    createdAt: createdAt ?? this.createdAt,
    width: width ?? this.width,
    height: height ?? this.height,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
    category: category ?? this.category,
    categoryLocked: categoryLocked ?? this.categoryLocked,
    sourceApp: sourceApp.present ? sourceApp.value : this.sourceApp,
    isFavorite: isFavorite ?? this.isFavorite,
    textHash: textHash.present ? textHash.value : this.textHash,
    processedAt: processedAt.present ? processedAt.value : this.processedAt,
    claimedAt: claimedAt.present ? claimedAt.value : this.claimedAt,
  );
  ScreenshotRow copyWithCompanion(ScreenshotsCompanion data) {
    return ScreenshotRow(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      category: data.category.present ? data.category.value : this.category,
      categoryLocked: data.categoryLocked.present
          ? data.categoryLocked.value
          : this.categoryLocked,
      sourceApp: data.sourceApp.present ? data.sourceApp.value : this.sourceApp,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      textHash: data.textHash.present ? data.textHash.value : this.textHash,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
      claimedAt: data.claimedAt.present ? data.claimedAt.value : this.claimedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScreenshotRow(')
          ..write('assetId: $assetId, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('ocrText: $ocrText, ')
          ..write('category: $category, ')
          ..write('categoryLocked: $categoryLocked, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('textHash: $textHash, ')
          ..write('processedAt: $processedAt, ')
          ..write('claimedAt: $claimedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assetId,
    filePath,
    fileName,
    createdAt,
    width,
    height,
    sizeBytes,
    ocrText,
    category,
    categoryLocked,
    sourceApp,
    isFavorite,
    textHash,
    processedAt,
    claimedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScreenshotRow &&
          other.assetId == this.assetId &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.createdAt == this.createdAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.sizeBytes == this.sizeBytes &&
          other.ocrText == this.ocrText &&
          other.category == this.category &&
          other.categoryLocked == this.categoryLocked &&
          other.sourceApp == this.sourceApp &&
          other.isFavorite == this.isFavorite &&
          other.textHash == this.textHash &&
          other.processedAt == this.processedAt &&
          other.claimedAt == this.claimedAt);
}

class ScreenshotsCompanion extends UpdateCompanion<ScreenshotRow> {
  final Value<String> assetId;
  final Value<String?> filePath;
  final Value<String> fileName;
  final Value<DateTime> createdAt;
  final Value<int> width;
  final Value<int> height;
  final Value<int> sizeBytes;
  final Value<String?> ocrText;
  final Value<String> category;
  final Value<bool> categoryLocked;
  final Value<String?> sourceApp;
  final Value<bool> isFavorite;
  final Value<String?> textHash;
  final Value<DateTime?> processedAt;
  final Value<DateTime?> claimedAt;
  final Value<int> rowid;
  const ScreenshotsCompanion({
    this.assetId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.category = const Value.absent(),
    this.categoryLocked = const Value.absent(),
    this.sourceApp = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.textHash = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.claimedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScreenshotsCompanion.insert({
    required String assetId,
    this.filePath = const Value.absent(),
    required String fileName,
    required DateTime createdAt,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.category = const Value.absent(),
    this.categoryLocked = const Value.absent(),
    this.sourceApp = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.textHash = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.claimedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : assetId = Value(assetId),
       fileName = Value(fileName),
       createdAt = Value(createdAt);
  static Insertable<ScreenshotRow> custom({
    Expression<String>? assetId,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<DateTime>? createdAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? sizeBytes,
    Expression<String>? ocrText,
    Expression<String>? category,
    Expression<bool>? categoryLocked,
    Expression<String>? sourceApp,
    Expression<bool>? isFavorite,
    Expression<String>? textHash,
    Expression<DateTime>? processedAt,
    Expression<DateTime>? claimedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (createdAt != null) 'created_at': createdAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (ocrText != null) 'ocr_text': ocrText,
      if (category != null) 'category': category,
      if (categoryLocked != null) 'category_locked': categoryLocked,
      if (sourceApp != null) 'source_app': sourceApp,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (textHash != null) 'text_hash': textHash,
      if (processedAt != null) 'processed_at': processedAt,
      if (claimedAt != null) 'claimed_at': claimedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScreenshotsCompanion copyWith({
    Value<String>? assetId,
    Value<String?>? filePath,
    Value<String>? fileName,
    Value<DateTime>? createdAt,
    Value<int>? width,
    Value<int>? height,
    Value<int>? sizeBytes,
    Value<String?>? ocrText,
    Value<String>? category,
    Value<bool>? categoryLocked,
    Value<String?>? sourceApp,
    Value<bool>? isFavorite,
    Value<String?>? textHash,
    Value<DateTime?>? processedAt,
    Value<DateTime?>? claimedAt,
    Value<int>? rowid,
  }) {
    return ScreenshotsCompanion(
      assetId: assetId ?? this.assetId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      width: width ?? this.width,
      height: height ?? this.height,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      ocrText: ocrText ?? this.ocrText,
      category: category ?? this.category,
      categoryLocked: categoryLocked ?? this.categoryLocked,
      sourceApp: sourceApp ?? this.sourceApp,
      isFavorite: isFavorite ?? this.isFavorite,
      textHash: textHash ?? this.textHash,
      processedAt: processedAt ?? this.processedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (categoryLocked.present) {
      map['category_locked'] = Variable<bool>(categoryLocked.value);
    }
    if (sourceApp.present) {
      map['source_app'] = Variable<String>(sourceApp.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (textHash.present) {
      map['text_hash'] = Variable<String>(textHash.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<DateTime>(processedAt.value);
    }
    if (claimedAt.present) {
      map['claimed_at'] = Variable<DateTime>(claimedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScreenshotsCompanion(')
          ..write('assetId: $assetId, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('ocrText: $ocrText, ')
          ..write('category: $category, ')
          ..write('categoryLocked: $categoryLocked, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('textHash: $textHash, ')
          ..write('processedAt: $processedAt, ')
          ..write('claimedAt: $claimedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntitiesTable extends Entities
    with TableInfo<$EntitiesTable, EntityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES screenshots (asset_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayValueMeta = const VerificationMeta(
    'displayValue',
  );
  @override
  late final GeneratedColumn<String> displayValue = GeneratedColumn<String>(
    'display_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    type,
    value,
    displayValue,
    openedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('display_value')) {
      context.handle(
        _displayValueMeta,
        displayValue.isAcceptableOrUnknown(
          data['display_value']!,
          _displayValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayValueMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      displayValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_value'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
    );
  }

  @override
  $EntitiesTable createAlias(String alias) {
    return $EntitiesTable(attachedDatabase, alias);
  }
}

class EntityRow extends DataClass implements Insertable<EntityRow> {
  final int id;
  final String assetId;
  final String type;
  final String value;
  final String displayValue;

  /// When the user last opened this link from the app or a notification (v2).
  final DateTime? openedAt;
  const EntityRow({
    required this.id,
    required this.assetId,
    required this.type,
    required this.value,
    required this.displayValue,
    this.openedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['asset_id'] = Variable<String>(assetId);
    map['type'] = Variable<String>(type);
    map['value'] = Variable<String>(value);
    map['display_value'] = Variable<String>(displayValue);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    return map;
  }

  EntitiesCompanion toCompanion(bool nullToAbsent) {
    return EntitiesCompanion(
      id: Value(id),
      assetId: Value(assetId),
      type: Value(type),
      value: Value(value),
      displayValue: Value(displayValue),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
    );
  }

  factory EntityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntityRow(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<String>(json['assetId']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<String>(json['value']),
      displayValue: serializer.fromJson<String>(json['displayValue']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<String>(assetId),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<String>(value),
      'displayValue': serializer.toJson<String>(displayValue),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
    };
  }

  EntityRow copyWith({
    int? id,
    String? assetId,
    String? type,
    String? value,
    String? displayValue,
    Value<DateTime?> openedAt = const Value.absent(),
  }) => EntityRow(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    type: type ?? this.type,
    value: value ?? this.value,
    displayValue: displayValue ?? this.displayValue,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
  );
  EntityRow copyWithCompanion(EntitiesCompanion data) {
    return EntityRow(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      displayValue: data.displayValue.present
          ? data.displayValue.value
          : this.displayValue,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntityRow(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('displayValue: $displayValue, ')
          ..write('openedAt: $openedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, assetId, type, value, displayValue, openedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityRow &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.type == this.type &&
          other.value == this.value &&
          other.displayValue == this.displayValue &&
          other.openedAt == this.openedAt);
}

class EntitiesCompanion extends UpdateCompanion<EntityRow> {
  final Value<int> id;
  final Value<String> assetId;
  final Value<String> type;
  final Value<String> value;
  final Value<String> displayValue;
  final Value<DateTime?> openedAt;
  const EntitiesCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.displayValue = const Value.absent(),
    this.openedAt = const Value.absent(),
  });
  EntitiesCompanion.insert({
    this.id = const Value.absent(),
    required String assetId,
    required String type,
    required String value,
    required String displayValue,
    this.openedAt = const Value.absent(),
  }) : assetId = Value(assetId),
       type = Value(type),
       value = Value(value),
       displayValue = Value(displayValue);
  static Insertable<EntityRow> custom({
    Expression<int>? id,
    Expression<String>? assetId,
    Expression<String>? type,
    Expression<String>? value,
    Expression<String>? displayValue,
    Expression<DateTime>? openedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (displayValue != null) 'display_value': displayValue,
      if (openedAt != null) 'opened_at': openedAt,
    });
  }

  EntitiesCompanion copyWith({
    Value<int>? id,
    Value<String>? assetId,
    Value<String>? type,
    Value<String>? value,
    Value<String>? displayValue,
    Value<DateTime?>? openedAt,
  }) {
    return EntitiesCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      type: type ?? this.type,
      value: value ?? this.value,
      displayValue: displayValue ?? this.displayValue,
      openedAt: openedAt ?? this.openedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (displayValue.present) {
      map['display_value'] = Variable<String>(displayValue.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitiesCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('displayValue: $displayValue, ')
          ..write('openedAt: $openedAt')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses
    with TableInfo<$ExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES screenshots (asset_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  static const VerificationMeta _payeeMeta = const VerificationMeta('payee');
  @override
  late final GeneratedColumn<String> payee = GeneratedColumn<String>(
    'payee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payeeKeyMeta = const VerificationMeta(
    'payeeKey',
  );
  @override
  late final GeneratedColumn<String> payeeKey = GeneratedColumn<String>(
    'payee_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _isConfirmedMeta = const VerificationMeta(
    'isConfirmed',
  );
  @override
  late final GeneratedColumn<bool> isConfirmed = GeneratedColumn<bool>(
    'is_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isExcludedMeta = const VerificationMeta(
    'isExcluded',
  );
  @override
  late final GeneratedColumn<bool> isExcluded = GeneratedColumn<bool>(
    'is_excluded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_excluded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _duplicateOfIdMeta = const VerificationMeta(
    'duplicateOfId',
  );
  @override
  late final GeneratedColumn<int> duplicateOfId = GeneratedColumn<int>(
    'duplicate_of_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    amountMinor,
    currency,
    type,
    payee,
    payeeKey,
    transactionId,
    date,
    category,
    note,
    source,
    confidence,
    isConfirmed,
    isExcluded,
    duplicateOfId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('payee')) {
      context.handle(
        _payeeMeta,
        payee.isAcceptableOrUnknown(data['payee']!, _payeeMeta),
      );
    }
    if (data.containsKey('payee_key')) {
      context.handle(
        _payeeKeyMeta,
        payeeKey.isAcceptableOrUnknown(data['payee_key']!, _payeeKeyMeta),
      );
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('is_confirmed')) {
      context.handle(
        _isConfirmedMeta,
        isConfirmed.isAcceptableOrUnknown(
          data['is_confirmed']!,
          _isConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('is_excluded')) {
      context.handle(
        _isExcludedMeta,
        isExcluded.isAcceptableOrUnknown(data['is_excluded']!, _isExcludedMeta),
      );
    }
    if (data.containsKey('duplicate_of_id')) {
      context.handle(
        _duplicateOfIdMeta,
        duplicateOfId.isAcceptableOrUnknown(
          data['duplicate_of_id']!,
          _duplicateOfIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee'],
      ),
      payeeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee_key'],
      ),
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      isConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_confirmed'],
      )!,
      isExcluded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_excluded'],
      )!,
      duplicateOfId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duplicate_of_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final int id;

  /// Null for manual entries. Kept (set null) if the screenshot is deleted so
  /// spend history survives a cleanup.
  final String? assetId;

  /// Money is always integer minor units (paisa, cents) — never double.
  final int amountMinor;
  final String currency;

  /// `expense` | `income`.
  final String type;
  final String? payee;

  /// Normalized payee used for merchant rules and dedupe.
  final String? payeeKey;
  final String? transactionId;
  final DateTime date;
  final String category;
  final String note;

  /// `auto` | `manual`.
  final String source;
  final double confidence;
  final bool isConfirmed;
  final bool isExcluded;

  /// Set when this looks like a repeat of another expense (same amount + payee
  /// within 10 minutes). Not counted until the user confirms it.
  final int? duplicateOfId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExpenseRow({
    required this.id,
    this.assetId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    this.payee,
    this.payeeKey,
    this.transactionId,
    required this.date,
    required this.category,
    required this.note,
    required this.source,
    required this.confidence,
    required this.isConfirmed,
    required this.isExcluded,
    this.duplicateOfId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<String>(assetId);
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || payee != null) {
      map['payee'] = Variable<String>(payee);
    }
    if (!nullToAbsent || payeeKey != null) {
      map['payee_key'] = Variable<String>(payeeKey);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    map['date'] = Variable<DateTime>(date);
    map['category'] = Variable<String>(category);
    map['note'] = Variable<String>(note);
    map['source'] = Variable<String>(source);
    map['confidence'] = Variable<double>(confidence);
    map['is_confirmed'] = Variable<bool>(isConfirmed);
    map['is_excluded'] = Variable<bool>(isExcluded);
    if (!nullToAbsent || duplicateOfId != null) {
      map['duplicate_of_id'] = Variable<int>(duplicateOfId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      type: Value(type),
      payee: payee == null && nullToAbsent
          ? const Value.absent()
          : Value(payee),
      payeeKey: payeeKey == null && nullToAbsent
          ? const Value.absent()
          : Value(payeeKey),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      date: Value(date),
      category: Value(category),
      note: Value(note),
      source: Value(source),
      confidence: Value(confidence),
      isConfirmed: Value(isConfirmed),
      isExcluded: Value(isExcluded),
      duplicateOfId: duplicateOfId == null && nullToAbsent
          ? const Value.absent()
          : Value(duplicateOfId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<String?>(json['assetId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      type: serializer.fromJson<String>(json['type']),
      payee: serializer.fromJson<String?>(json['payee']),
      payeeKey: serializer.fromJson<String?>(json['payeeKey']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      date: serializer.fromJson<DateTime>(json['date']),
      category: serializer.fromJson<String>(json['category']),
      note: serializer.fromJson<String>(json['note']),
      source: serializer.fromJson<String>(json['source']),
      confidence: serializer.fromJson<double>(json['confidence']),
      isConfirmed: serializer.fromJson<bool>(json['isConfirmed']),
      isExcluded: serializer.fromJson<bool>(json['isExcluded']),
      duplicateOfId: serializer.fromJson<int?>(json['duplicateOfId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<String?>(assetId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'type': serializer.toJson<String>(type),
      'payee': serializer.toJson<String?>(payee),
      'payeeKey': serializer.toJson<String?>(payeeKey),
      'transactionId': serializer.toJson<String?>(transactionId),
      'date': serializer.toJson<DateTime>(date),
      'category': serializer.toJson<String>(category),
      'note': serializer.toJson<String>(note),
      'source': serializer.toJson<String>(source),
      'confidence': serializer.toJson<double>(confidence),
      'isConfirmed': serializer.toJson<bool>(isConfirmed),
      'isExcluded': serializer.toJson<bool>(isExcluded),
      'duplicateOfId': serializer.toJson<int?>(duplicateOfId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExpenseRow copyWith({
    int? id,
    Value<String?> assetId = const Value.absent(),
    int? amountMinor,
    String? currency,
    String? type,
    Value<String?> payee = const Value.absent(),
    Value<String?> payeeKey = const Value.absent(),
    Value<String?> transactionId = const Value.absent(),
    DateTime? date,
    String? category,
    String? note,
    String? source,
    double? confidence,
    bool? isConfirmed,
    bool? isExcluded,
    Value<int?> duplicateOfId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExpenseRow(
    id: id ?? this.id,
    assetId: assetId.present ? assetId.value : this.assetId,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    type: type ?? this.type,
    payee: payee.present ? payee.value : this.payee,
    payeeKey: payeeKey.present ? payeeKey.value : this.payeeKey,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    date: date ?? this.date,
    category: category ?? this.category,
    note: note ?? this.note,
    source: source ?? this.source,
    confidence: confidence ?? this.confidence,
    isConfirmed: isConfirmed ?? this.isConfirmed,
    isExcluded: isExcluded ?? this.isExcluded,
    duplicateOfId: duplicateOfId.present
        ? duplicateOfId.value
        : this.duplicateOfId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      type: data.type.present ? data.type.value : this.type,
      payee: data.payee.present ? data.payee.value : this.payee,
      payeeKey: data.payeeKey.present ? data.payeeKey.value : this.payeeKey,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      isConfirmed: data.isConfirmed.present
          ? data.isConfirmed.value
          : this.isConfirmed,
      isExcluded: data.isExcluded.present
          ? data.isExcluded.value
          : this.isExcluded,
      duplicateOfId: data.duplicateOfId.present
          ? data.duplicateOfId.value
          : this.duplicateOfId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('payee: $payee, ')
          ..write('payeeKey: $payeeKey, ')
          ..write('transactionId: $transactionId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('confidence: $confidence, ')
          ..write('isConfirmed: $isConfirmed, ')
          ..write('isExcluded: $isExcluded, ')
          ..write('duplicateOfId: $duplicateOfId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    amountMinor,
    currency,
    type,
    payee,
    payeeKey,
    transactionId,
    date,
    category,
    note,
    source,
    confidence,
    isConfirmed,
    isExcluded,
    duplicateOfId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.type == this.type &&
          other.payee == this.payee &&
          other.payeeKey == this.payeeKey &&
          other.transactionId == this.transactionId &&
          other.date == this.date &&
          other.category == this.category &&
          other.note == this.note &&
          other.source == this.source &&
          other.confidence == this.confidence &&
          other.isConfirmed == this.isConfirmed &&
          other.isExcluded == this.isExcluded &&
          other.duplicateOfId == this.duplicateOfId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<int> id;
  final Value<String?> assetId;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<String> type;
  final Value<String?> payee;
  final Value<String?> payeeKey;
  final Value<String?> transactionId;
  final Value<DateTime> date;
  final Value<String> category;
  final Value<String> note;
  final Value<String> source;
  final Value<double> confidence;
  final Value<bool> isConfirmed;
  final Value<bool> isExcluded;
  final Value<int?> duplicateOfId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.type = const Value.absent(),
    this.payee = const Value.absent(),
    this.payeeKey = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.confidence = const Value.absent(),
    this.isConfirmed = const Value.absent(),
    this.isExcluded = const Value.absent(),
    this.duplicateOfId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    required int amountMinor,
    required String currency,
    this.type = const Value.absent(),
    this.payee = const Value.absent(),
    this.payeeKey = const Value.absent(),
    this.transactionId = const Value.absent(),
    required DateTime date,
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.confidence = const Value.absent(),
    this.isConfirmed = const Value.absent(),
    this.isExcluded = const Value.absent(),
    this.duplicateOfId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : amountMinor = Value(amountMinor),
       currency = Value(currency),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExpenseRow> custom({
    Expression<int>? id,
    Expression<String>? assetId,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? type,
    Expression<String>? payee,
    Expression<String>? payeeKey,
    Expression<String>? transactionId,
    Expression<DateTime>? date,
    Expression<String>? category,
    Expression<String>? note,
    Expression<String>? source,
    Expression<double>? confidence,
    Expression<bool>? isConfirmed,
    Expression<bool>? isExcluded,
    Expression<int>? duplicateOfId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (type != null) 'type': type,
      if (payee != null) 'payee': payee,
      if (payeeKey != null) 'payee_key': payeeKey,
      if (transactionId != null) 'transaction_id': transactionId,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (confidence != null) 'confidence': confidence,
      if (isConfirmed != null) 'is_confirmed': isConfirmed,
      if (isExcluded != null) 'is_excluded': isExcluded,
      if (duplicateOfId != null) 'duplicate_of_id': duplicateOfId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ExpensesCompanion copyWith({
    Value<int>? id,
    Value<String?>? assetId,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<String>? type,
    Value<String?>? payee,
    Value<String?>? payeeKey,
    Value<String?>? transactionId,
    Value<DateTime>? date,
    Value<String>? category,
    Value<String>? note,
    Value<String>? source,
    Value<double>? confidence,
    Value<bool>? isConfirmed,
    Value<bool>? isExcluded,
    Value<int?>? duplicateOfId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      payee: payee ?? this.payee,
      payeeKey: payeeKey ?? this.payeeKey,
      transactionId: transactionId ?? this.transactionId,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isExcluded: isExcluded ?? this.isExcluded,
      duplicateOfId: duplicateOfId ?? this.duplicateOfId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payee.present) {
      map['payee'] = Variable<String>(payee.value);
    }
    if (payeeKey.present) {
      map['payee_key'] = Variable<String>(payeeKey.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (isConfirmed.present) {
      map['is_confirmed'] = Variable<bool>(isConfirmed.value);
    }
    if (isExcluded.present) {
      map['is_excluded'] = Variable<bool>(isExcluded.value);
    }
    if (duplicateOfId.present) {
      map['duplicate_of_id'] = Variable<int>(duplicateOfId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('payee: $payee, ')
          ..write('payeeKey: $payeeKey, ')
          ..write('transactionId: $transactionId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('confidence: $confidence, ')
          ..write('isConfirmed: $isConfirmed, ')
          ..write('isExcluded: $isExcluded, ')
          ..write('duplicateOfId: $duplicateOfId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MerchantRulesTable extends MerchantRules
    with TableInfo<$MerchantRulesTable, MerchantRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _payeeKeyMeta = const VerificationMeta(
    'payeeKey',
  );
  @override
  late final GeneratedColumn<String> payeeKey = GeneratedColumn<String>(
    'payee_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [payeeKey, category, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchant_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<MerchantRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('payee_key')) {
      context.handle(
        _payeeKeyMeta,
        payeeKey.isAcceptableOrUnknown(data['payee_key']!, _payeeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_payeeKeyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {payeeKey};
  @override
  MerchantRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MerchantRuleRow(
      payeeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee_key'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MerchantRulesTable createAlias(String alias) {
    return $MerchantRulesTable(attachedDatabase, alias);
  }
}

class MerchantRuleRow extends DataClass implements Insertable<MerchantRuleRow> {
  final String payeeKey;
  final String category;
  final DateTime updatedAt;
  const MerchantRuleRow({
    required this.payeeKey,
    required this.category,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['payee_key'] = Variable<String>(payeeKey);
    map['category'] = Variable<String>(category);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MerchantRulesCompanion toCompanion(bool nullToAbsent) {
    return MerchantRulesCompanion(
      payeeKey: Value(payeeKey),
      category: Value(category),
      updatedAt: Value(updatedAt),
    );
  }

  factory MerchantRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MerchantRuleRow(
      payeeKey: serializer.fromJson<String>(json['payeeKey']),
      category: serializer.fromJson<String>(json['category']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'payeeKey': serializer.toJson<String>(payeeKey),
      'category': serializer.toJson<String>(category),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MerchantRuleRow copyWith({
    String? payeeKey,
    String? category,
    DateTime? updatedAt,
  }) => MerchantRuleRow(
    payeeKey: payeeKey ?? this.payeeKey,
    category: category ?? this.category,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MerchantRuleRow copyWithCompanion(MerchantRulesCompanion data) {
    return MerchantRuleRow(
      payeeKey: data.payeeKey.present ? data.payeeKey.value : this.payeeKey,
      category: data.category.present ? data.category.value : this.category,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MerchantRuleRow(')
          ..write('payeeKey: $payeeKey, ')
          ..write('category: $category, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(payeeKey, category, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MerchantRuleRow &&
          other.payeeKey == this.payeeKey &&
          other.category == this.category &&
          other.updatedAt == this.updatedAt);
}

class MerchantRulesCompanion extends UpdateCompanion<MerchantRuleRow> {
  final Value<String> payeeKey;
  final Value<String> category;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MerchantRulesCompanion({
    this.payeeKey = const Value.absent(),
    this.category = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MerchantRulesCompanion.insert({
    required String payeeKey,
    required String category,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : payeeKey = Value(payeeKey),
       category = Value(category),
       updatedAt = Value(updatedAt);
  static Insertable<MerchantRuleRow> custom({
    Expression<String>? payeeKey,
    Expression<String>? category,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (payeeKey != null) 'payee_key': payeeKey,
      if (category != null) 'category': category,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MerchantRulesCompanion copyWith({
    Value<String>? payeeKey,
    Value<String>? category,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MerchantRulesCompanion(
      payeeKey: payeeKey ?? this.payeeKey,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (payeeKey.present) {
      map['payee_key'] = Variable<String>(payeeKey.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MerchantRulesCompanion(')
          ..write('payeeKey: $payeeKey, ')
          ..write('category: $category, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecapsTable extends Recaps with TableInfo<$RecapsTable, RecapRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<DateTime> weekStart = GeneratedColumn<DateTime>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekEndMeta = const VerificationMeta(
    'weekEnd',
  );
  @override
  late final GeneratedColumn<DateTime> weekEnd = GeneratedColumn<DateTime>(
    'week_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notifiedAtMeta = const VerificationMeta(
    'notifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> notifiedAt = GeneratedColumn<DateTime>(
    'notified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weekStart,
    weekEnd,
    createdAt,
    payload,
    notifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recaps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecapRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('week_end')) {
      context.handle(
        _weekEndMeta,
        weekEnd.isAcceptableOrUnknown(data['week_end']!, _weekEndMeta),
      );
    } else if (isInserting) {
      context.missing(_weekEndMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('notified_at')) {
      context.handle(
        _notifiedAtMeta,
        notifiedAt.isAcceptableOrUnknown(data['notified_at']!, _notifiedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecapRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecapRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}week_start'],
      )!,
      weekEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}week_end'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      notifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}notified_at'],
      ),
    );
  }

  @override
  $RecapsTable createAlias(String alias) {
    return $RecapsTable(attachedDatabase, alias);
  }
}

class RecapRow extends DataClass implements Insertable<RecapRow> {
  final int id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime createdAt;

  /// Serialized `WeeklyRecap` (see domain/recap).
  final String payload;
  final DateTime? notifiedAt;
  const RecapRow({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.createdAt,
    required this.payload,
    this.notifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week_start'] = Variable<DateTime>(weekStart);
    map['week_end'] = Variable<DateTime>(weekEnd);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || notifiedAt != null) {
      map['notified_at'] = Variable<DateTime>(notifiedAt);
    }
    return map;
  }

  RecapsCompanion toCompanion(bool nullToAbsent) {
    return RecapsCompanion(
      id: Value(id),
      weekStart: Value(weekStart),
      weekEnd: Value(weekEnd),
      createdAt: Value(createdAt),
      payload: Value(payload),
      notifiedAt: notifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(notifiedAt),
    );
  }

  factory RecapRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecapRow(
      id: serializer.fromJson<int>(json['id']),
      weekStart: serializer.fromJson<DateTime>(json['weekStart']),
      weekEnd: serializer.fromJson<DateTime>(json['weekEnd']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      payload: serializer.fromJson<String>(json['payload']),
      notifiedAt: serializer.fromJson<DateTime?>(json['notifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weekStart': serializer.toJson<DateTime>(weekStart),
      'weekEnd': serializer.toJson<DateTime>(weekEnd),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'payload': serializer.toJson<String>(payload),
      'notifiedAt': serializer.toJson<DateTime?>(notifiedAt),
    };
  }

  RecapRow copyWith({
    int? id,
    DateTime? weekStart,
    DateTime? weekEnd,
    DateTime? createdAt,
    String? payload,
    Value<DateTime?> notifiedAt = const Value.absent(),
  }) => RecapRow(
    id: id ?? this.id,
    weekStart: weekStart ?? this.weekStart,
    weekEnd: weekEnd ?? this.weekEnd,
    createdAt: createdAt ?? this.createdAt,
    payload: payload ?? this.payload,
    notifiedAt: notifiedAt.present ? notifiedAt.value : this.notifiedAt,
  );
  RecapRow copyWithCompanion(RecapsCompanion data) {
    return RecapRow(
      id: data.id.present ? data.id.value : this.id,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      weekEnd: data.weekEnd.present ? data.weekEnd.value : this.weekEnd,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      payload: data.payload.present ? data.payload.value : this.payload,
      notifiedAt: data.notifiedAt.present
          ? data.notifiedAt.value
          : this.notifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecapRow(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('createdAt: $createdAt, ')
          ..write('payload: $payload, ')
          ..write('notifiedAt: $notifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, weekStart, weekEnd, createdAt, payload, notifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecapRow &&
          other.id == this.id &&
          other.weekStart == this.weekStart &&
          other.weekEnd == this.weekEnd &&
          other.createdAt == this.createdAt &&
          other.payload == this.payload &&
          other.notifiedAt == this.notifiedAt);
}

class RecapsCompanion extends UpdateCompanion<RecapRow> {
  final Value<int> id;
  final Value<DateTime> weekStart;
  final Value<DateTime> weekEnd;
  final Value<DateTime> createdAt;
  final Value<String> payload;
  final Value<DateTime?> notifiedAt;
  const RecapsCompanion({
    this.id = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.weekEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.notifiedAt = const Value.absent(),
  });
  RecapsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime weekStart,
    required DateTime weekEnd,
    required DateTime createdAt,
    required String payload,
    this.notifiedAt = const Value.absent(),
  }) : weekStart = Value(weekStart),
       weekEnd = Value(weekEnd),
       createdAt = Value(createdAt),
       payload = Value(payload);
  static Insertable<RecapRow> custom({
    Expression<int>? id,
    Expression<DateTime>? weekStart,
    Expression<DateTime>? weekEnd,
    Expression<DateTime>? createdAt,
    Expression<String>? payload,
    Expression<DateTime>? notifiedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekStart != null) 'week_start': weekStart,
      if (weekEnd != null) 'week_end': weekEnd,
      if (createdAt != null) 'created_at': createdAt,
      if (payload != null) 'payload': payload,
      if (notifiedAt != null) 'notified_at': notifiedAt,
    });
  }

  RecapsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? weekStart,
    Value<DateTime>? weekEnd,
    Value<DateTime>? createdAt,
    Value<String>? payload,
    Value<DateTime?>? notifiedAt,
  }) {
    return RecapsCompanion(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
      notifiedAt: notifiedAt ?? this.notifiedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<DateTime>(weekStart.value);
    }
    if (weekEnd.present) {
      map['week_end'] = Variable<DateTime>(weekEnd.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (notifiedAt.present) {
      map['notified_at'] = Variable<DateTime>(notifiedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecapsCompanion(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('createdAt: $createdAt, ')
          ..write('payload: $payload, ')
          ..write('notifiedAt: $notifiedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScreenshotsTable screenshots = $ScreenshotsTable(this);
  late final $EntitiesTable entities = $EntitiesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $MerchantRulesTable merchantRules = $MerchantRulesTable(this);
  late final $RecapsTable recaps = $RecapsTable(this);
  late final Index idxScreenshotsProcessed = Index(
    'idx_screenshots_processed',
    'CREATE INDEX idx_screenshots_processed ON screenshots (processed_at)',
  );
  late final Index idxScreenshotsCategoryCreated = Index(
    'idx_screenshots_category_created',
    'CREATE INDEX idx_screenshots_category_created ON screenshots (category, created_at)',
  );
  late final Index idxScreenshotsCreated = Index(
    'idx_screenshots_created',
    'CREATE INDEX idx_screenshots_created ON screenshots (created_at)',
  );
  late final Index idxScreenshotsHash = Index(
    'idx_screenshots_hash',
    'CREATE INDEX idx_screenshots_hash ON screenshots (text_hash)',
  );
  late final Index idxEntitiesAsset = Index(
    'idx_entities_asset',
    'CREATE INDEX idx_entities_asset ON entities (asset_id)',
  );
  late final Index idxEntitiesType = Index(
    'idx_entities_type',
    'CREATE INDEX idx_entities_type ON entities (type)',
  );
  late final Index idxExpensesDate = Index(
    'idx_expenses_date',
    'CREATE INDEX idx_expenses_date ON expenses (date)',
  );
  late final Index idxExpensesAsset = Index(
    'idx_expenses_asset',
    'CREATE INDEX idx_expenses_asset ON expenses (asset_id)',
  );
  late final Index idxExpensesTid = Index(
    'idx_expenses_tid',
    'CREATE INDEX idx_expenses_tid ON expenses (transaction_id)',
  );
  late final Index idxRecapsWeek = Index(
    'idx_recaps_week',
    'CREATE UNIQUE INDEX idx_recaps_week ON recaps (week_start)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    screenshots,
    entities,
    expenses,
    merchantRules,
    recaps,
    idxScreenshotsProcessed,
    idxScreenshotsCategoryCreated,
    idxScreenshotsCreated,
    idxScreenshotsHash,
    idxEntitiesAsset,
    idxEntitiesType,
    idxExpensesDate,
    idxExpensesAsset,
    idxExpensesTid,
    idxRecapsWeek,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'screenshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entities', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'screenshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('expenses', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$ScreenshotsTableCreateCompanionBuilder =
    ScreenshotsCompanion Function({
      required String assetId,
      Value<String?> filePath,
      required String fileName,
      required DateTime createdAt,
      Value<int> width,
      Value<int> height,
      Value<int> sizeBytes,
      Value<String?> ocrText,
      Value<String> category,
      Value<bool> categoryLocked,
      Value<String?> sourceApp,
      Value<bool> isFavorite,
      Value<String?> textHash,
      Value<DateTime?> processedAt,
      Value<DateTime?> claimedAt,
      Value<int> rowid,
    });
typedef $$ScreenshotsTableUpdateCompanionBuilder =
    ScreenshotsCompanion Function({
      Value<String> assetId,
      Value<String?> filePath,
      Value<String> fileName,
      Value<DateTime> createdAt,
      Value<int> width,
      Value<int> height,
      Value<int> sizeBytes,
      Value<String?> ocrText,
      Value<String> category,
      Value<bool> categoryLocked,
      Value<String?> sourceApp,
      Value<bool> isFavorite,
      Value<String?> textHash,
      Value<DateTime?> processedAt,
      Value<DateTime?> claimedAt,
      Value<int> rowid,
    });

final class $$ScreenshotsTableReferences
    extends BaseReferences<_$AppDatabase, $ScreenshotsTable, ScreenshotRow> {
  $$ScreenshotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntitiesTable, List<EntityRow>>
  _entitiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entities,
    aliasName: 'screenshots__asset_id__entities__asset_id',
  );

  $$EntitiesTableProcessedTableManager get entitiesRefs {
    final manager = $$EntitiesTableTableManager($_db, $_db.entities).filter(
      (f) => f.assetId.assetId.sqlEquals($_itemColumn<String>('asset_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_entitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<ExpenseRow>>
  _expensesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'screenshots__asset_id__expenses__asset_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses).filter(
      (f) => f.assetId.assetId.sqlEquals($_itemColumn<String>('asset_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScreenshotsTableFilterComposer
    extends Composer<_$AppDatabase, $ScreenshotsTable> {
  $$ScreenshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get categoryLocked => $composableBuilder(
    column: $table.categoryLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textHash => $composableBuilder(
    column: $table.textHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get claimedAt => $composableBuilder(
    column: $table.claimedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entitiesRefs(
    Expression<bool> Function($$EntitiesTableFilterComposer f) f,
  ) {
    final $$EntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableFilterComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScreenshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScreenshotsTable> {
  $$ScreenshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get categoryLocked => $composableBuilder(
    column: $table.categoryLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textHash => $composableBuilder(
    column: $table.textHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get claimedAt => $composableBuilder(
    column: $table.claimedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScreenshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScreenshotsTable> {
  $$ScreenshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get categoryLocked => $composableBuilder(
    column: $table.categoryLocked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceApp =>
      $composableBuilder(column: $table.sourceApp, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textHash =>
      $composableBuilder(column: $table.textHash, builder: (column) => column);

  GeneratedColumn<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get claimedAt =>
      $composableBuilder(column: $table.claimedAt, builder: (column) => column);

  Expression<T> entitiesRefs<T extends Object>(
    Expression<T> Function($$EntitiesTableAnnotationComposer a) f,
  ) {
    final $$EntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScreenshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScreenshotsTable,
          ScreenshotRow,
          $$ScreenshotsTableFilterComposer,
          $$ScreenshotsTableOrderingComposer,
          $$ScreenshotsTableAnnotationComposer,
          $$ScreenshotsTableCreateCompanionBuilder,
          $$ScreenshotsTableUpdateCompanionBuilder,
          (ScreenshotRow, $$ScreenshotsTableReferences),
          ScreenshotRow,
          PrefetchHooks Function({bool entitiesRefs, bool expensesRefs})
        > {
  $$ScreenshotsTableTableManager(_$AppDatabase db, $ScreenshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScreenshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScreenshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScreenshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assetId = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> categoryLocked = const Value.absent(),
                Value<String?> sourceApp = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> textHash = const Value.absent(),
                Value<DateTime?> processedAt = const Value.absent(),
                Value<DateTime?> claimedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScreenshotsCompanion(
                assetId: assetId,
                filePath: filePath,
                fileName: fileName,
                createdAt: createdAt,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                ocrText: ocrText,
                category: category,
                categoryLocked: categoryLocked,
                sourceApp: sourceApp,
                isFavorite: isFavorite,
                textHash: textHash,
                processedAt: processedAt,
                claimedAt: claimedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assetId,
                Value<String?> filePath = const Value.absent(),
                required String fileName,
                required DateTime createdAt,
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> categoryLocked = const Value.absent(),
                Value<String?> sourceApp = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> textHash = const Value.absent(),
                Value<DateTime?> processedAt = const Value.absent(),
                Value<DateTime?> claimedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScreenshotsCompanion.insert(
                assetId: assetId,
                filePath: filePath,
                fileName: fileName,
                createdAt: createdAt,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                ocrText: ocrText,
                category: category,
                categoryLocked: categoryLocked,
                sourceApp: sourceApp,
                isFavorite: isFavorite,
                textHash: textHash,
                processedAt: processedAt,
                claimedAt: claimedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScreenshotsTable, ScreenshotRow>(table),
                  $$ScreenshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({entitiesRefs = false, expensesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entitiesRefs) db.entities,
                    if (expensesRefs) db.expenses,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entitiesRefs)
                        await $_getPrefetchedData<
                          ScreenshotRow,
                          $ScreenshotsTable,
                          EntityRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScreenshotsTableReferences
                              ._entitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScreenshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).entitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.assetId,
                              ),
                          typedResults: items,
                        ),
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          ScreenshotRow,
                          $ScreenshotsTable,
                          ExpenseRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScreenshotsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScreenshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.assetId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScreenshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScreenshotsTable,
      ScreenshotRow,
      $$ScreenshotsTableFilterComposer,
      $$ScreenshotsTableOrderingComposer,
      $$ScreenshotsTableAnnotationComposer,
      $$ScreenshotsTableCreateCompanionBuilder,
      $$ScreenshotsTableUpdateCompanionBuilder,
      (ScreenshotRow, $$ScreenshotsTableReferences),
      ScreenshotRow,
      PrefetchHooks Function({bool entitiesRefs, bool expensesRefs})
    >;
typedef $$EntitiesTableCreateCompanionBuilder = EntitiesCompanion Function({
  Value<int> id,
  required String assetId,
  required String type,
  required String value,
  required String displayValue,
  Value<DateTime?> openedAt,
});
typedef $$EntitiesTableUpdateCompanionBuilder = EntitiesCompanion Function({
  Value<int> id,
  Value<String> assetId,
  Value<String> type,
  Value<String> value,
  Value<String> displayValue,
  Value<DateTime?> openedAt,
});

final class $$EntitiesTableReferences
    extends BaseReferences<_$AppDatabase, $EntitiesTable, EntityRow> {
  $$EntitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScreenshotsTable _assetIdTable(_$AppDatabase db) =>
      db.screenshots.createAlias('entities__asset_id__screenshots__asset_id');

  $$ScreenshotsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $$ScreenshotsTableTableManager(
      $_db,
      $_db.screenshots,
    ).filter((f) => f.assetId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScreenshotsTableFilterComposer get assetId {
    final $$ScreenshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableFilterComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScreenshotsTableOrderingComposer get assetId {
    final $$ScreenshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableOrderingComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get displayValue => $composableBuilder(
    column: $table.displayValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  $$ScreenshotsTableAnnotationComposer get assetId {
    final $$ScreenshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntitiesTable,
          EntityRow,
          $$EntitiesTableFilterComposer,
          $$EntitiesTableOrderingComposer,
          $$EntitiesTableAnnotationComposer,
          $$EntitiesTableCreateCompanionBuilder,
          $$EntitiesTableUpdateCompanionBuilder,
          (EntityRow, $$EntitiesTableReferences),
          EntityRow,
          PrefetchHooks Function({bool assetId})
        > {
  $$EntitiesTableTableManager(_$AppDatabase db, $EntitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String> displayValue = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
              }) => EntitiesCompanion(
                id: id,
                assetId: assetId,
                type: type,
                value: value,
                displayValue: displayValue,
                openedAt: openedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String assetId,
                required String type,
                required String value,
                required String displayValue,
                Value<DateTime?> openedAt = const Value.absent(),
              }) => EntitiesCompanion.insert(
                id: id,
                assetId: assetId,
                type: type,
                value: value,
                displayValue: displayValue,
                openedAt: openedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntitiesTable, EntityRow>(table),
                  $$EntitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.assetId,
                        referencedTable: $$EntitiesTableReferences
                            ._assetIdTable(db),
                        referencedColumn: $$EntitiesTableReferences
                            ._assetIdTable(db)
                            .assetId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntitiesTable,
      EntityRow,
      $$EntitiesTableFilterComposer,
      $$EntitiesTableOrderingComposer,
      $$EntitiesTableAnnotationComposer,
      $$EntitiesTableCreateCompanionBuilder,
      $$EntitiesTableUpdateCompanionBuilder,
      (EntityRow, $$EntitiesTableReferences),
      EntityRow,
      PrefetchHooks Function({bool assetId})
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  Value<String?> assetId,
  required int amountMinor,
  required String currency,
  Value<String> type,
  Value<String?> payee,
  Value<String?> payeeKey,
  Value<String?> transactionId,
  required DateTime date,
  Value<String> category,
  Value<String> note,
  Value<String> source,
  Value<double> confidence,
  Value<bool> isConfirmed,
  Value<bool> isExcluded,
  Value<int?> duplicateOfId,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  Value<String?> assetId,
  Value<int> amountMinor,
  Value<String> currency,
  Value<String> type,
  Value<String?> payee,
  Value<String?> payeeKey,
  Value<String?> transactionId,
  Value<DateTime> date,
  Value<String> category,
  Value<String> note,
  Value<String> source,
  Value<double> confidence,
  Value<bool> isConfirmed,
  Value<bool> isExcluded,
  Value<int?> duplicateOfId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScreenshotsTable _assetIdTable(_$AppDatabase db) =>
      db.screenshots.createAlias('expenses__asset_id__screenshots__asset_id');

  $$ScreenshotsTableProcessedTableManager? get assetId {
    final $_column = $_itemColumn<String>('asset_id');
    if ($_column == null) return null;
    final manager = $$ScreenshotsTableTableManager(
      $_db,
      $_db.screenshots,
    ).filter((f) => f.assetId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payeeKey => $composableBuilder(
    column: $table.payeeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExcluded => $composableBuilder(
    column: $table.isExcluded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duplicateOfId => $composableBuilder(
    column: $table.duplicateOfId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScreenshotsTableFilterComposer get assetId {
    final $$ScreenshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableFilterComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payeeKey => $composableBuilder(
    column: $table.payeeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExcluded => $composableBuilder(
    column: $table.isExcluded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duplicateOfId => $composableBuilder(
    column: $table.duplicateOfId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScreenshotsTableOrderingComposer get assetId {
    final $$ScreenshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableOrderingComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payee =>
      $composableBuilder(column: $table.payee, builder: (column) => column);

  GeneratedColumn<String> get payeeKey =>
      $composableBuilder(column: $table.payeeKey, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isExcluded => $composableBuilder(
    column: $table.isExcluded,
    builder: (column) => column,
  );

  GeneratedColumn<int> get duplicateOfId => $composableBuilder(
    column: $table.duplicateOfId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ScreenshotsTableAnnotationComposer get assetId {
    final $$ScreenshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          ExpenseRow,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (ExpenseRow, $$ExpensesTableReferences),
          ExpenseRow,
          PrefetchHooks Function({bool assetId})
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String?> payeeKey = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<bool> isConfirmed = const Value.absent(),
                Value<bool> isExcluded = const Value.absent(),
                Value<int?> duplicateOfId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                assetId: assetId,
                amountMinor: amountMinor,
                currency: currency,
                type: type,
                payee: payee,
                payeeKey: payeeKey,
                transactionId: transactionId,
                date: date,
                category: category,
                note: note,
                source: source,
                confidence: confidence,
                isConfirmed: isConfirmed,
                isExcluded: isExcluded,
                duplicateOfId: duplicateOfId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                required int amountMinor,
                required String currency,
                Value<String> type = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String?> payeeKey = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                required DateTime date,
                Value<String> category = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<bool> isConfirmed = const Value.absent(),
                Value<bool> isExcluded = const Value.absent(),
                Value<int?> duplicateOfId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ExpensesCompanion.insert(
                id: id,
                assetId: assetId,
                amountMinor: amountMinor,
                currency: currency,
                type: type,
                payee: payee,
                payeeKey: payeeKey,
                transactionId: transactionId,
                date: date,
                category: category,
                note: note,
                source: source,
                confidence: confidence,
                isConfirmed: isConfirmed,
                isExcluded: isExcluded,
                duplicateOfId: duplicateOfId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensesTable, ExpenseRow>(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.assetId,
                        referencedTable: $$ExpensesTableReferences
                            ._assetIdTable(db),
                        referencedColumn: $$ExpensesTableReferences
                            ._assetIdTable(db)
                            .assetId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      ExpenseRow,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (ExpenseRow, $$ExpensesTableReferences),
      ExpenseRow,
      PrefetchHooks Function({bool assetId})
    >;
typedef $$MerchantRulesTableCreateCompanionBuilder =
    MerchantRulesCompanion Function({
      required String payeeKey,
      required String category,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MerchantRulesTableUpdateCompanionBuilder =
    MerchantRulesCompanion Function({
      Value<String> payeeKey,
      Value<String> category,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MerchantRulesTableFilterComposer
    extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get payeeKey => $composableBuilder(
    column: $table.payeeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MerchantRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get payeeKey => $composableBuilder(
    column: $table.payeeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MerchantRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MerchantRulesTable> {
  $$MerchantRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get payeeKey =>
      $composableBuilder(column: $table.payeeKey, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MerchantRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MerchantRulesTable,
          MerchantRuleRow,
          $$MerchantRulesTableFilterComposer,
          $$MerchantRulesTableOrderingComposer,
          $$MerchantRulesTableAnnotationComposer,
          $$MerchantRulesTableCreateCompanionBuilder,
          $$MerchantRulesTableUpdateCompanionBuilder,
          (
            MerchantRuleRow,
            BaseReferences<_$AppDatabase, $MerchantRulesTable, MerchantRuleRow>,
          ),
          MerchantRuleRow,
          PrefetchHooks Function()
        > {
  $$MerchantRulesTableTableManager(_$AppDatabase db, $MerchantRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MerchantRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MerchantRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MerchantRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> payeeKey = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MerchantRulesCompanion(
                payeeKey: payeeKey,
                category: category,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String payeeKey,
                required String category,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MerchantRulesCompanion.insert(
                payeeKey: payeeKey,
                category: category,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MerchantRulesTable, MerchantRuleRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MerchantRulesTable,
                    MerchantRuleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MerchantRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MerchantRulesTable,
      MerchantRuleRow,
      $$MerchantRulesTableFilterComposer,
      $$MerchantRulesTableOrderingComposer,
      $$MerchantRulesTableAnnotationComposer,
      $$MerchantRulesTableCreateCompanionBuilder,
      $$MerchantRulesTableUpdateCompanionBuilder,
      (
        MerchantRuleRow,
        BaseReferences<_$AppDatabase, $MerchantRulesTable, MerchantRuleRow>,
      ),
      MerchantRuleRow,
      PrefetchHooks Function()
    >;
typedef $$RecapsTableCreateCompanionBuilder = RecapsCompanion Function({
  Value<int> id,
  required DateTime weekStart,
  required DateTime weekEnd,
  required DateTime createdAt,
  required String payload,
  Value<DateTime?> notifiedAt,
});
typedef $$RecapsTableUpdateCompanionBuilder = RecapsCompanion Function({
  Value<int> id,
  Value<DateTime> weekStart,
  Value<DateTime> weekEnd,
  Value<DateTime> createdAt,
  Value<String> payload,
  Value<DateTime?> notifiedAt,
});

class $$RecapsTableFilterComposer
    extends Composer<_$AppDatabase, $RecapsTable> {
  $$RecapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get weekEnd => $composableBuilder(
    column: $table.weekEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecapsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecapsTable> {
  $$RecapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get weekEnd => $composableBuilder(
    column: $table.weekEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecapsTable> {
  $$RecapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<DateTime> get weekEnd =>
      $composableBuilder(column: $table.weekEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get notifiedAt => $composableBuilder(
    column: $table.notifiedAt,
    builder: (column) => column,
  );
}

class $$RecapsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecapsTable,
          RecapRow,
          $$RecapsTableFilterComposer,
          $$RecapsTableOrderingComposer,
          $$RecapsTableAnnotationComposer,
          $$RecapsTableCreateCompanionBuilder,
          $$RecapsTableUpdateCompanionBuilder,
          (RecapRow, BaseReferences<_$AppDatabase, $RecapsTable, RecapRow>),
          RecapRow,
          PrefetchHooks Function()
        > {
  $$RecapsTableTableManager(_$AppDatabase db, $RecapsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> weekStart = const Value.absent(),
                Value<DateTime> weekEnd = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime?> notifiedAt = const Value.absent(),
              }) => RecapsCompanion(
                id: id,
                weekStart: weekStart,
                weekEnd: weekEnd,
                createdAt: createdAt,
                payload: payload,
                notifiedAt: notifiedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime weekStart,
                required DateTime weekEnd,
                required DateTime createdAt,
                required String payload,
                Value<DateTime?> notifiedAt = const Value.absent(),
              }) => RecapsCompanion.insert(
                id: id,
                weekStart: weekStart,
                weekEnd: weekEnd,
                createdAt: createdAt,
                payload: payload,
                notifiedAt: notifiedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecapsTable, RecapRow>(table),
                  BaseReferences<_$AppDatabase, $RecapsTable, RecapRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecapsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecapsTable,
      RecapRow,
      $$RecapsTableFilterComposer,
      $$RecapsTableOrderingComposer,
      $$RecapsTableAnnotationComposer,
      $$RecapsTableCreateCompanionBuilder,
      $$RecapsTableUpdateCompanionBuilder,
      (RecapRow, BaseReferences<_$AppDatabase, $RecapsTable, RecapRow>),
      RecapRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScreenshotsTableTableManager get screenshots =>
      $$ScreenshotsTableTableManager(_db, _db.screenshots);
  $$EntitiesTableTableManager get entities =>
      $$EntitiesTableTableManager(_db, _db.entities);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$MerchantRulesTableTableManager get merchantRules =>
      $$MerchantRulesTableTableManager(_db, _db.merchantRules);
  $$RecapsTableTableManager get recaps =>
      $$RecapsTableTableManager(_db, _db.recaps);
}
