import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/format.dart';
import '../data/expense_repository.dart';
import '../data/screenshot_repository.dart';
import '../domain/cleanup_rules/cleanup_rules.dart';
import '../domain/expense/spend_summary.dart';
import '../domain/widgets/widget_snapshot.dart';
import 'prefs_keys.dart';

/// Pushes fresh numbers to the home-screen widgets. Called (debounced) after
/// scans, expense changes and cleanups — from the app and from background
/// engines alike.
class WidgetSync {
  WidgetSync({required this.prefs, required this.shots, required this.expenses});

  final SharedPreferences prefs;
  final ScreenshotRepository shots;
  final ExpenseRepository expenses;

  static const searchProvider = 'com.snaplio.app.widget.SearchWidgetProvider';
  static const snapshotProvider = 'com.snaplio.app.widget.SnapshotWidgetProvider';

  Timer? _debounce;

  /// Coalesces bursts of changes (a scan sorts many screenshots).
  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), push);
  }

  Future<Map<String, String>> snapshot({DateTime? now}) async {
    final month = monthStart(now ?? DateTime.now());
    final currency = prefs.getString(PrefsKeys.defaultCurrency) ?? 'PKR';
    final list = await expenses.range(previousMonth(month), nextMonth(month));
    final spend = summarizeMonth([for (final x in list) x.entry], month, currency);
    final latest = await expenses.latestCounted();
    final cleanup = const CleanupRules().analyze(await shots.cleanupItems());
    return buildWidgetSnapshot(
      spend: spend,
      latest: latest == null ? null : LatestReceipt(latest.row.amountMinor, latest.row.currency, latest.row.payee),
      cleanableBytes: cleanup.reclaimableBytes,
      unreadLinks: await shots.unreadLinkCount(),
      formatBytes: formatBytes,
    );
  }

  Future<void> push() async {
    try {
      final data = await snapshot();
      for (final e in data.entries) {
        await HomeWidget.saveWidgetData<String>(e.key, e.value);
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: snapshotProvider);
      await HomeWidget.updateWidget(qualifiedAndroidName: searchProvider);
    } on MissingPluginException {
      // Tests / non-Android.
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  /// Asks the launcher to add a widget (Android 8+, launcher permitting).
  /// Returns false when pinning isn't supported.
  static Future<bool> requestPin(String qualifiedName) async {
    try {
      if (await HomeWidget.isRequestPinWidgetSupported() != true) return false;
      await HomeWidget.requestPinWidget(qualifiedAndroidName: qualifiedName);
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _debounce?.cancel();
}
