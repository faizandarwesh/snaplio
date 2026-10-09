import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/expense_repository.dart';
import '../data/screenshot_repository.dart';
import '../services/expense_service.dart';
import '../services/gallery_service.dart';
import '../services/ocr_service.dart';
import '../services/prefs_keys.dart';
import '../services/scan_service.dart';
import '../services/smart_notifier.dart';

/// The app's data + services, wired for a headless engine (no Riverpod, no
/// Activity). Same classes the UI uses — logic lives in one place.
class BackgroundServices {
  BackgroundServices._(this.prefs, this.db, this.shots, this.expenses, this.scan, this.notifier);

  final SharedPreferences prefs;
  final AppDatabase db;
  final ScreenshotRepository shots;
  final ExpenseService expenses;
  final ScanService scan;
  final SmartNotifier notifier;

  static Future<BackgroundServices> open() async {
    final prefs = await SharedPreferences.getInstance();
    // Another engine (the app) may have written since this one started.
    await prefs.reload();
    final gallery = GalleryService(background: true);
    await gallery.ignorePermissionCheck();
    final db = AppDatabase.defaults();
    final shots = ScreenshotRepository(db);
    final expenses = ExpenseService(repo: ExpenseRepository(db), currency: PrefsCurrencyStore(prefs));
    final scan = ScanService(
      repo: shots,
      gallery: gallery,
      ocr: OcrService(),
      excludedAlbumIds: () => (prefs.getStringList(PrefsKeys.excludedAlbums) ?? const []).toSet(),
      expenses: expenses,
    );
    return BackgroundServices._(prefs, db, shots, expenses, scan, SmartNotifier(prefs));
  }

  /// Screenshots added since the last fast scan (with a small overlap), never
  /// more than a day back.
  DateTime scanWindowStart(DateTime now) {
    final last = prefs.getInt(PrefsKeys.lastNewScanAt);
    final floor = now.subtract(const Duration(hours: 24));
    if (last == null) return now.subtract(const Duration(hours: 1));
    final since = DateTime.fromMillisecondsSinceEpoch(last).subtract(const Duration(minutes: 2));
    return since.isBefore(floor) ? floor : since;
  }

  /// New screenshot(s) arrived: sort them, track receipts, notify.
  Future<void> scanNewAndNotify() async {
    final started = DateTime.now();
    final processed = await scan.scanNew(since: scanWindowStart(started));
    await prefs.setInt(PrefsKeys.lastNewScanAt, started.millisecondsSinceEpoch);
    if (processed.isNotEmpty) await expenses.autoDetectCurrency();
    try {
      await notifier.notify(processed);
    } catch (e) {
      debugPrint('Notify failed: $e');
    }
  }

  Future<void> dispose() async {
    await scan.dispose();
    await db.close();
  }
}
