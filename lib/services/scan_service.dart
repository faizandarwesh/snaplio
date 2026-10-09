import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/screenshot_repository.dart';
import '../domain/analyzer.dart';
import '../domain/models.dart';
import 'expense_service.dart';
import 'gallery_service.dart';
import 'ocr_service.dart';

enum ScanPhase { idle, discovering, processing, done, failed }

@immutable
class ScanProgress {
  const ScanProgress({
    required this.phase,
    this.processed = 0,
    this.total = 0,
    this.counts = const {},
    this.error,
  });

  final ScanPhase phase;
  final int processed;
  final int total;

  /// Category counts for screenshots processed in this run.
  final Map<ScreenshotCategory, int> counts;
  final Object? error;

  static const idle = ScanProgress(phase: ScanPhase.idle);

  bool get isRunning => phase == ScanPhase.discovering || phase == ScanPhase.processing;
  double get fraction => total == 0 ? 0 : (processed / total).clamp(0, 1);

  ScanProgress copyWith({ScanPhase? phase, int? processed, int? total, Map<ScreenshotCategory, int>? counts, Object? error}) =>
      ScanProgress(
        phase: phase ?? this.phase,
        processed: processed ?? this.processed,
        total: total ?? this.total,
        counts: counts ?? this.counts,
        error: error ?? this.error,
      );
}

/// Result of processing one screenshot (feeds notifications and toasts).
class ProcessedShot {
  const ProcessedShot({required this.row, required this.category, required this.entities, this.text, this.expense});

  /// The row as it was before processing (id, file name, createdAt).
  final ScreenshotRow row;
  final ScreenshotCategory category;
  final List<ExtractedEntity> entities;
  final String? text;
  final IngestResult? expense;
}

/// Finds screenshots, diffs them against the DB and OCRs the unprocessed queue
/// newest-first in small batches. Resumable (unprocessed rows have
/// `processedAt == null`) and incremental (only new assets are inserted).
class ScanService {
  ScanService({
    required this.repo,
    required this.gallery,
    required this.ocr,
    required this.excludedAlbumIds,
    this.expenses,
    this.analyzer = const ScreenshotAnalyzer(),
  });

  /// Creates expenses for receipts as they are sorted (null in tests).
  final ExpenseService? expenses;

  final ScreenshotRepository repo;
  final GalleryService gallery;
  final OcrService ocr;
  final ScreenshotAnalyzer analyzer;
  final Set<String> Function() excludedAlbumIds;

  static const batchSize = 8;

  final _controller = StreamController<ScanProgress>.broadcast();
  final _processed = StreamController<ProcessedShot>.broadcast();

  /// Every screenshot this service finishes, from any scan path.
  Stream<ProcessedShot> get processed => _processed.stream;
  ScanProgress _current = ScanProgress.idle;
  Future<void>? _running;
  bool _cancelled = false;

  ScanProgress get current => _current;

  /// Emits the current value first, then live updates.
  Stream<ScanProgress> get progress async* {
    yield _current;
    yield* _controller.stream;
  }

  void _emit(ScanProgress p) {
    _current = p;
    _controller.add(p);
  }

  /// Starts a scan, or joins the one already running.
  Future<void> scan() => _running ??= _run().whenComplete(() => _running = null);

  /// Forgets all OCR results (keeps manual categories) and scans everything again.
  Future<void> rescanAll() async {
    await _running;
    await repo.resetAllProcessing();
    await scan();
  }

  void cancel() => _cancelled = true;

  Future<void> _run() async {
    _cancelled = false;
    try {
      _emit(const ScanProgress(phase: ScanPhase.discovering));
      await _discover();

      final total = await repo.unprocessedCount();
      var processed = 0;
      final counts = <ScreenshotCategory, int>{};
      _emit(ScanProgress(phase: ScanPhase.processing, total: total));

      while (!_cancelled) {
        final batch = await repo.nextUnprocessed(batchSize);
        if (batch.isEmpty) break;
        for (final row in batch) {
          if (_cancelled) break;
          final shot = await _processOne(row);
          if (shot != null) counts[shot.category] = (counts[shot.category] ?? 0) + 1;
          processed++;
        }
        _emit(ScanProgress(
          phase: ScanPhase.processing,
          processed: processed,
          total: total < processed ? processed : total,
          counts: Map.unmodifiable(counts),
        ));
        // Let the UI breathe between batches.
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      if (processed > 0) await expenses?.autoDetectCurrency();
      _emit(_current.copyWith(phase: ScanPhase.done));
    } catch (e, st) {
      debugPrint('Scan failed: $e\n$st');
      _emit(_current.copyWith(phase: ScanPhase.failed, error: e));
    }
  }

  Future<void> _discover() async {
    final access = await gallery.currentAccess();
    if (!access.canRead) return;
    final found = await gallery.findScreenshots(excludedAlbumIds: excludedAlbumIds());
    final existing = await repo.allAssetIds();
    final foundIds = {for (final a in found) a.id};
    await repo.insertDiscovered([for (final a in found) if (!existing.contains(a.id)) a]);
    final removed = existing.difference(foundIds);
    if (removed.isNotEmpty) await repo.deleteByIds(removed);
  }

  /// Fast path for brand-new screenshots (background job, foreground
  /// listener): discovers only assets added since [since] and processes just
  /// those plus any recent leftovers. Never deletes rows.
  Future<List<ProcessedShot>> scanNew({required DateTime since}) async {
    final access = await gallery.currentAccess();
    if (!access.canRead) return const [];
    final found = await gallery.findScreenshots(excludedAlbumIds: excludedAlbumIds(), since: since);
    if (found.isEmpty) return const [];
    final existing = await repo.allAssetIds();
    await repo.insertDiscovered([for (final a in found) if (!existing.contains(a.id)) a]);
    final rows = await repo.nextUnprocessed(found.length, ids: [for (final a in found) a.id]);
    final out = <ProcessedShot>[];
    // Oldest first so grouped summaries read in order.
    for (final row in rows.reversed) {
      final shot = await _processOne(row);
      if (shot != null) out.add(shot);
    }
    return out;
  }

  Future<ProcessedShot?> _processOne(ScreenshotRow row) async {
    // Another engine may already own this screenshot.
    if (!await repo.claim(row.assetId)) return null;
    try {
      final File? file = await gallery.fileFor(row.assetId);
      if (file == null || !await file.exists()) {
        // The asset vanished between discovery and processing.
        await repo.deleteByIds([row.assetId]);
        return null;
      }
      final size = await file.length();
      String? text;
      try {
        text = await ocr.recognize(file.path);
      } catch (e) {
        debugPrint('OCR failed for ${row.assetId}: $e');
      }
      final analysis = analyzer.analyze(fileName: row.fileName, text: text);
      await repo.saveResult(
        row: row,
        filePath: file.path,
        sizeBytes: size,
        ocrText: text,
        analysis: analysis,
      );
      final category = row.categoryLocked ? ScreenshotCategory.fromName(row.category) : analysis.category;
      IngestResult? expense;
      if (category == ScreenshotCategory.receipts && expenses != null) {
        try {
          expense = await expenses!.ingestScreenshot(assetId: row.assetId, ocrText: text, createdAt: row.createdAt);
        } catch (e) {
          debugPrint('Expense extraction failed for ${row.assetId}: $e');
        }
      }
      final shot = ProcessedShot(row: row, category: category, entities: analysis.entities, text: text, expense: expense);
      if (!_processed.isClosed) _processed.add(shot);
      return shot;
    } catch (e) {
      debugPrint('Processing failed for ${row.assetId}: $e');
      await repo.markFailed(row.assetId);
      return null;
    }
  }

  Future<void> dispose() async {
    _cancelled = true;
    await _controller.close();
    await _processed.close();
    await ocr.dispose();
  }
}
