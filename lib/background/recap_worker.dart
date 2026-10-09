import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../data/recap_repository.dart';
import '../services/recap_service.dart';
import 'background_services.dart';

/// Workmanager entrypoint: delivers the weekly recap when its time has come.
@pragma('vm:entry-point')
void recapCallbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    DartPluginRegistrant.ensureInitialized();
    BackgroundServices? s;
    try {
      s = await BackgroundServices.open();
      final recaps = RecapService(
        prefs: s.prefs,
        shots: s.shots,
        expenses: s.expenses.repo,
        recaps: RecapRepository(s.db),
      );
      await recaps.runIfDue();
      await RecapScheduler.schedule(s.prefs);
    } catch (e, st) {
      debugPrint('Recap task failed: $e\n$st');
    } finally {
      await s?.dispose();
    }
    // Never ask for a retry: the daily task is the safety net.
    return true;
  });
}
