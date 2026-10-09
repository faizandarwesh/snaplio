import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../app/providers.dart';
import '../../background/recap_worker.dart';
import '../../data/recap_repository.dart';
import '../../domain/recap/weekly_recap.dart';
import '../../services/prefs_keys.dart';
import '../../services/recap_service.dart';

final recapRepositoryProvider = Provider<RecapRepository>((ref) => RecapRepository(ref.watch(databaseProvider)));

final recapServiceProvider = Provider<RecapService>(
  (ref) => RecapService(
    prefs: ref.watch(sharedPrefsProvider),
    shots: ref.watch(repositoryProvider),
    expenses: ref.watch(expenseRepositoryProvider),
    recaps: ref.watch(recapRepositoryProvider),
  ),
);

final recapsProvider = StreamProvider<List<StoredRecap>>((ref) => ref.watch(recapRepositoryProvider).watchAll());

final recapProvider = StreamProvider.autoDispose.family<StoredRecap?, int>(
  (ref, id) => ref.watch(recapRepositoryProvider).watchOne(id),
);

/// The recap generated in the last 48 hours (Home card), if any.
final freshRecapProvider = Provider<StoredRecap?>((ref) {
  final all = ref.watch(recapsProvider).value ?? const [];
  if (all.isEmpty) return null;
  final r = all.first;
  final fresh = DateTime.now().difference(r.createdAt) < const Duration(hours: 48);
  return fresh && r.recap.screenshots > 0 ? r : null;
});

/// Recap schedule settings + background scheduling.
class RecapController extends Notifier<RecapSchedule> {
  static bool _wmReady = false;

  @override
  RecapSchedule build() => RecapService.scheduleOf(ref.read(sharedPrefsProvider));

  Future<void> onAppStart() async {
    try {
      if (!_wmReady) {
        await Workmanager().initialize(recapCallbackDispatcher);
        _wmReady = true;
      }
      await RecapScheduler.schedule(ref.read(sharedPrefsProvider));
      // Catch up if the worker was delayed: the Home card shows it, no
      // notification needed while the user is already in the app.
      await ref.read(recapServiceProvider).runIfDue(notify: false);
    } catch (e) {
      debugPrint('Recap scheduling failed: $e');
    }
  }

  Future<void> update({bool? enabled, int? weekday, int? hour, int? minute}) async {
    final p = ref.read(sharedPrefsProvider);
    if (enabled != null) await p.setBool(PrefsKeys.recapEnabled, enabled);
    if (weekday != null) await p.setInt(PrefsKeys.recapWeekday, weekday);
    if (hour != null) await p.setInt(PrefsKeys.recapHour, hour);
    if (minute != null) await p.setInt(PrefsKeys.recapMinute, minute);
    if (weekday != null || hour != null || minute != null) {
      // A new time means "the next one at the new time", not "right now".
      final s = RecapService.scheduleOf(p);
      await p.setInt(PrefsKeys.recapLastOccurrence, s.lastOccurrence(DateTime.now()).millisecondsSinceEpoch);
    }
    state = RecapService.scheduleOf(p);
    if (_wmReady) await RecapScheduler.schedule(p);
  }
}

final recapControllerProvider = NotifierProvider<RecapController, RecapSchedule>(RecapController.new);
