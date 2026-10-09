import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaplio_native/snaplio_native.dart';

import '../data/screenshot_repository.dart';
import '../domain/expense/expense_extractor.dart';
import '../domain/notifications/smart_notifications.dart';
import '../domain/text_utils.dart';
import 'expense_service.dart';
import 'prefs_keys.dart';
import 'scan_service.dart';

/// Smart Actions settings in shared preferences (read by background engines).
abstract final class SmartSettingsStore {
  static SmartSettings read(SharedPreferences p) => SmartSettings(
        enabled: p.getBool(PrefsKeys.smartEnabled) ?? false,
        otp: p.getBool(PrefsKeys.smartOtp) ?? true,
        receipts: p.getBool(PrefsKeys.smartReceipts) ?? true,
        links: p.getBool(PrefsKeys.smartLinks) ?? true,
        addresses: p.getBool(PrefsKeys.smartAddresses) ?? true,
        phones: p.getBool(PrefsKeys.smartPhones) ?? true,
      );
}

ShotInfo shotInfoOf(ProcessedShot s, {DateTime? at}) {
  final x = s.expense;
  final added = x != null && x.added && x.expense != null;
  return ShotInfo(
    assetId: s.row.assetId,
    category: s.category,
    entities: s.entities,
    words: wordCount(s.text),
    at: at ?? DateTime.now(),
    expense: added
        ? ShotExpense(
            id: x.expense!.row.id,
            amountMinor: x.expense!.row.amountMinor,
            currency: x.expense!.row.currency,
            payee: x.expense!.row.payee,
            type: ExpenseType.fromName(x.expense!.row.type),
            likelyDuplicate: x.kind == IngestKind.likelyDuplicate,
          )
        : null,
  );
}

NativeAction _native(SmartAction a) => switch (a.type) {
      SmartActionType.copy => NativeAction.copy(a.label, a.value!, what: a.what ?? 'Text'),
      SmartActionType.open => NativeAction.open(a.label, a.value!, assetId: a.assetId),
      SmartActionType.maps => NativeAction.maps(a.label, a.value!),
      SmartActionType.call => NativeAction.call(a.label, a.value!),
      SmartActionType.whatsapp => NativeAction.whatsapp(a.label, a.value!),
      SmartActionType.view => NativeAction.view(a.label, a.value!),
      SmartActionType.notExpense => NativeAction.notExpense(a.label, a.expenseId!),
    };

/// Posts system notifications for screenshots processed in the background.
class SmartNotifier {
  SmartNotifier(this.prefs, {this.planner = const NotificationPlanner()});

  final SharedPreferences prefs;
  final NotificationPlanner planner;

  /// Only screenshots this fresh are worth interrupting someone for.
  static const freshness = Duration(minutes: 30);

  Future<void> notify(List<ProcessedShot> processed) async {
    final settings = SmartSettingsStore.read(prefs);
    if (!settings.enabled || processed.isEmpty) return;
    if (!await SnapNative.notificationsEnabled()) return;
    final now = DateTime.now();
    final shots = [
      for (final p in processed)
        if (now.difference(p.row.createdAt) <= freshness) shotInfoOf(p, at: now),
    ];
    if (shots.isEmpty) return;

    final plan = planner.plan(
      log: BurstEntry.decode(prefs.getString(PrefsKeys.burstLog)),
      shots: shots,
      settings: settings,
      now: now,
    );
    await prefs.setString(PrefsKeys.burstLog, BurstEntry.encode(plan.log));

    for (final id in plan.cancel) {
      await SnapNative.cancel(id);
    }
    final summary = plan.summary;
    if (summary != null) {
      await SnapNative.post(id: kSummaryNotificationId, title: summary.title, body: summary.body, link: 'snaplio://home');
    }
    for (final n in plan.post) {
      await SnapNative.post(
        id: n.id,
        title: n.title,
        body: n.body,
        link: n.link,
        group: true,
        actions: [for (final a in n.actions) _native(a)],
      );
    }
  }
}

/// Applies actions taken from notifications while no Dart was running.
Future<bool> applyPendingOps({required ExpenseService expenses, required ScreenshotRepository shots}) async {
  final ops = await SnapNative.takePendingOps();
  for (final op in ops) {
    try {
      switch (op.op) {
        case 'exclude':
          final id = (op.data['expenseId'] as num?)?.toInt();
          if (id != null) await expenses.setExcluded(id, true);
        case 'linkOpened':
          final asset = op.data['assetId'] as String?;
          final url = op.data['url'] as String?;
          if (asset != null && url != null) await shots.markLinkOpened(asset, url);
      }
    } catch (e) {
      debugPrint('Pending op ${op.op} failed: $e');
    }
  }
  return ops.isNotEmpty;
}
