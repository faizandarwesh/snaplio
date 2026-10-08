import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/screenshot_repository.dart';
import '../domain/analyzer.dart';
import '../domain/models.dart';
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

/// Finds screenshots, diffs them against the DB and OCRs the unprocessed queue
/// newest-first in small batches. Resumable (unprocessed rows have
/// `processedAt == null`) and incremental (only new assets are inserted).
class ScanService {
  ScanService({
    required this.repo,
    required this.gallery,
    required this.ocr,
    required this.excludedAlbumIds,
    this.analyzer = const ScreenshotAnalyzer(),
  });

  final ScreenshotRepository repo;
  final GalleryService gallery;
  final OcrService ocr;
  final ScreenshotAnalyzer analyzer;
  final Set<String> Function() excludedAlbumIds;

  static const batchSize = 8;

  final _controller = StreamController<ScanProgress>.broadcast();
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
          final category = await _processOne(row);
          if (category != null) counts[category] = (counts[category] ?? 0) + 1;
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

  Future<ScreenshotCategory?> _processOne(ScreenshotRow row) async {
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
      return row.categoryLocked ? ScreenshotCategory.fromName(row.category) : analysis.category;
    } catch (e) {
      debugPrint('Processing failed for ${row.assetId}: $e');
      await repo.markFailed(row.assetId);
      return null;
    }
  }

  Future<void> dispose() async {
    _cancelled = true;
    await _controller.close();
    await ocr.dispose();
  }
}
