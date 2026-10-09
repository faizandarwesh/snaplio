import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaplio_native/snaplio_native.dart';
import 'package:workmanager/workmanager.dart';

import '../core/utils/format.dart';
import '../data/expense_repository.dart';
import '../data/recap_repository.dart';
import '../data/screenshot_repository.dart';
import '../domain/cleanup_rules/cleanup_rules.dart';
import '../domain/models.dart';
import '../domain/recap/weekly_recap.dart';
import 'prefs_keys.dart';

/// Builds, stores and announces the weekly recap. Numbers are computed at
/// delivery time from the live database. Used by the workmanager isolate and
/// by the app (catch-up on start).
class RecapService {
  RecapService({required this.prefs, required this.shots, required this.expenses, required this.recaps});

  final SharedPreferences prefs;
  final ScreenshotRepository shots;
  final ExpenseRepository expenses;
  final RecapRepository recaps;

  static const notificationId = 998;

  static RecapSchedule scheduleOf(SharedPreferences p) => RecapSchedule(
        enabled: p.getBool(PrefsKeys.recapEnabled) ?? true,
        weekday: p.getInt(PrefsKeys.recapWeekday) ?? DateTime.sunday,
        hour: p.getInt(PrefsKeys.recapHour) ?? 19,
        minute: p.getInt(PrefsKeys.recapMinute) ?? 0,
      );

  Future<WeeklyRecap> compute(DateTime start, DateTime end) async {
    final rows = await shots.createdBetween(start, end);
    final spend = await expenses.range(start, end);
    final links = await shots.unreadLinks(since: start);
    final cleanup = const CleanupRules().analyze(await shots.cleanupItems());
    return computeWeeklyRecap(
      start: start,
      end: end,
      shots: [for (final r in rows) RecapShot(r.createdAt, ScreenshotCategory.fromName(r.category), r.sourceApp)],
      spend: [for (final x in spend) x.entry],
      unreadLinks: [for (final l in links) RecapLink(l.assetId, l.url, l.display)],
      cleanableBytes: cleanup.reclaimableBytes,
      currency: prefs.getString(PrefsKeys.defaultCurrency) ?? 'PKR',
    );
  }

  /// Generates this week's recap if its time has come and it wasn't handled
  /// yet. Returns the stored id, or null when nothing was due.
  Future<int?> runIfDue({DateTime? now, bool notify = true}) async {
    final t = now ?? DateTime.now();
    final schedule = scheduleOf(prefs);
    final lastMs = prefs.getInt(PrefsKeys.recapLastOccurrence);
    final occ = schedule.due(t, lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs));
    if (occ == null) return null;

    final (start, end) = RecapSchedule.weekFor(occ);
    final recap = await compute(start, end);
    final id = await recaps.upsert(recap);
    // Handled for this week, even if too quiet to notify.
    await prefs.setInt(PrefsKeys.recapLastOccurrence, occ.millisecondsSinceEpoch);

    if (notify && recap.worthNotifying && await SnapNative.notificationsEnabled()) {
      await SnapNative.post(
        id: notificationId,
        channel: SnapNative.channelRecap,
        title: 'Your week in screenshots',
        body: 'Your week: ${recap.summaryLine(formatBytes)}',
        link: 'snaplio://recap/$id',
      );
      await recaps.markNotified(id);
    }
    return id;
  }
}

/// Workmanager scheduling: a daily safety-net task plus a one-off timed for
/// the exact recap moment (re-armed after every run and settings change).
abstract final class RecapScheduler {
  static const task = 'weeklyRecap';
  static const _daily = 'snaplio-recap-daily';
  static const _exact = 'snaplio-recap-exact';

  static Future<void> schedule(SharedPreferences prefs, {DateTime? now}) async {
    final s = RecapService.scheduleOf(prefs);
    final wm = Workmanager();
    if (!s.enabled) {
      await wm.cancelByUniqueName(_daily);
      await wm.cancelByUniqueName(_exact);
      return;
    }
    final t = now ?? DateTime.now();
    await wm.registerPeriodicTask(
      _daily,
      task,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    await wm.registerOneOffTask(
      _exact,
      task,
      initialDelay: s.nextOccurrence(t).difference(t) + const Duration(minutes: 1),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}
