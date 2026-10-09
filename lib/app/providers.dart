import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/expense_repository.dart';
import '../data/screenshot_repository.dart';
import '../domain/cleanup_rules/cleanup_rules.dart';
import '../domain/models.dart';
import '../services/expense_service.dart';
import '../services/gallery_service.dart';
import '../services/ocr_service.dart';
import '../services/prefs_keys.dart';
import '../services/scan_service.dart';
import '../services/widget_sync.dart';

// ------------------------------------------------------------------ Settings

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.onboardingDone,
    required this.excludedAlbumIds,
    required this.recentSearches,
    required this.defaultCurrency,
    required this.currencyManual,
  });

  final ThemeMode themeMode;
  final bool onboardingDone;
  final Set<String> excludedAlbumIds;
  final List<String> recentSearches;

  /// ISO code used when a receipt shows no currency, and as Spend's primary.
  final String defaultCurrency;

  /// True once the user picked it; otherwise it follows their receipts.
  final bool currencyManual;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? onboardingDone,
    Set<String>? excludedAlbumIds,
    List<String>? recentSearches,
    String? defaultCurrency,
    bool? currencyManual,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        excludedAlbumIds: excludedAlbumIds ?? this.excludedAlbumIds,
        recentSearches: recentSearches ?? this.recentSearches,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
        currencyManual: currencyManual ?? this.currencyManual,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'theme_mode';
  static const _kOnboarding = 'onboarding_done';
  static const _kExcluded = 'excluded_albums';
  static const _kRecent = 'recent_searches';

  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    final p = ref.watch(sharedPrefsProvider);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == p.getString(_kTheme),
        orElse: () => ThemeMode.dark,
      ),
      onboardingDone: p.getBool(_kOnboarding) ?? false,
      excludedAlbumIds: (p.getStringList(_kExcluded) ?? const []).toSet(),
      recentSearches: p.getStringList(_kRecent) ?? const [],
      defaultCurrency: p.getString(PrefsKeys.defaultCurrency) ?? 'PKR',
      currencyManual: p.getBool(PrefsKeys.currencyManual) ?? false,
    );
  }

  /// Re-reads values other engines (background job) may have written.
  Future<void> reload() async {
    await _p.reload();
    ref.invalidateSelf();
  }

  Future<void> setCurrency(String code, {bool manual = true}) async {
    state = state.copyWith(defaultCurrency: code, currencyManual: manual || state.currencyManual);
    await _p.setString(PrefsKeys.defaultCurrency, code);
    if (manual) await _p.setBool(PrefsKeys.currencyManual, true);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _p.setString(_kTheme, mode.name);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    await _p.setBool(_kOnboarding, true);
  }

  Future<void> setAlbumExcluded(String id, bool excluded) async {
    final next = {...state.excludedAlbumIds};
    excluded ? next.add(id) : next.remove(id);
    state = state.copyWith(excludedAlbumIds: next);
    await _p.setStringList(_kExcluded, next.toList());
  }

  Future<void> addRecentSearch(String q) async {
    final query = q.trim();
    if (query.length < 2) return;
    final next = [query, ...state.recentSearches.where((s) => s.toLowerCase() != query.toLowerCase())].take(8).toList();
    state = state.copyWith(recentSearches: next);
    await _p.setStringList(_kRecent, next);
  }

  Future<void> clearRecentSearches() async {
    state = state.copyWith(recentSearches: const []);
    await _p.remove(_kRecent);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ------------------------------------------------------------------ Services

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<ScreenshotRepository>(
  (ref) => ScreenshotRepository(ref.watch(databaseProvider)),
);

final galleryServiceProvider = Provider<GalleryService>((ref) => GalleryService());

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(databaseProvider)),
);

class _SettingsCurrencyStore implements CurrencyStore {
  _SettingsCurrencyStore(this.ref);
  final Ref ref;

  @override
  String get defaultCurrency => ref.read(settingsProvider).defaultCurrency;

  @override
  bool get isManual => ref.read(settingsProvider).currencyManual;

  @override
  Future<void> setAuto(String currency) => ref.read(settingsProvider.notifier).setCurrency(currency, manual: false);
}

final widgetSyncProvider = Provider<WidgetSync>((ref) {
  final s = WidgetSync(
    prefs: ref.watch(sharedPrefsProvider),
    shots: ref.watch(repositoryProvider),
    expenses: ref.watch(expenseRepositoryProvider),
  );
  ref.onDispose(s.dispose);
  return s;
});

final expenseServiceProvider = Provider<ExpenseService>(
  (ref) => ExpenseService(repo: ref.watch(expenseRepositoryProvider), currency: _SettingsCurrencyStore(ref))
    // Any spend change refreshes the home-screen widgets (debounced).
    ..onChanged = ref.read(widgetSyncProvider).schedule,
);

final scanServiceProvider = Provider<ScanService>((ref) {
  final service = ScanService(
    repo: ref.watch(repositoryProvider),
    gallery: ref.watch(galleryServiceProvider),
    ocr: OcrService(),
    excludedAlbumIds: () => ref.read(settingsProvider).excludedAlbumIds,
    expenses: ref.watch(expenseServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Turns receipts scanned before v1.1 into expenses, once. The result is kept
/// for the one-time "We found N receipts" celebration on Home.
class SpendBackfill extends Notifier<BackfillResult?> {
  bool _started = false;

  /// A pending celebration survives an app kill: "46|PKR:12840000,USD:1299".
  @override
  BackfillResult? build() {
    final raw = ref.read(sharedPrefsProvider).getString(PrefsKeys.spendCelebration);
    if (raw == null) return null;
    final parts = raw.split('|');
    final totals = <String, int>{
      for (final kv in parts.length > 1 && parts[1].isNotEmpty ? parts[1].split(',') : const <String>[])
        kv.split(':').first: int.tryParse(kv.split(':').last) ?? 0,
    };
    return BackfillResult(int.tryParse(parts.first) ?? 0, totals);
  }

  Future<void> runIfNeeded() async {
    final p = ref.read(sharedPrefsProvider);
    if (_started || (p.getBool(PrefsKeys.spendBackfillDone) ?? false)) return;
    _started = true;
    final result = await ref.read(expenseServiceProvider).backfill();
    await p.setBool(PrefsKeys.spendBackfillDone, true);
    // Only users upgrading from v1 (who already had receipts) get the moment.
    if (result.count > 0) {
      final totals = result.totalsByCurrency.entries.map((e) => '${e.key}:${e.value}').join(',');
      await p.setString(PrefsKeys.spendCelebration, '${result.count}|$totals');
      state = result;
    }
  }

  Future<void> dismissCelebration() async {
    await ref.read(sharedPrefsProvider).remove(PrefsKeys.spendCelebration);
    state = null;
  }
}

final spendBackfillProvider = NotifierProvider<SpendBackfill, BackfillResult?>(SpendBackfill.new);

final scanProgressProvider = StreamProvider<ScanProgress>(
  (ref) => ref.watch(scanServiceProvider).progress,
);

// ---------------------------------------------------------------- Permission

class GalleryAccessNotifier extends AsyncNotifier<GalleryAccess> {
  @override
  Future<GalleryAccess> build() => ref.read(galleryServiceProvider).currentAccess();

  Future<GalleryAccess> refresh() async {
    final a = await ref.read(galleryServiceProvider).currentAccess();
    state = AsyncData(a);
    return a;
  }

  Future<GalleryAccess> request() async {
    final a = await ref.read(galleryServiceProvider).requestAccess();
    state = AsyncData(a);
    return a;
  }
}

final galleryAccessProvider =
    AsyncNotifierProvider<GalleryAccessNotifier, GalleryAccess>(GalleryAccessNotifier.new);

// --------------------------------------------------------------------- Data

final libraryStatsProvider = StreamProvider<LibraryStats>(
  (ref) => ref.watch(repositoryProvider).watchStats(),
);

final categoryStatsProvider = StreamProvider<List<CategoryStat>>(
  (ref) => ref.watch(repositoryProvider).watchCategoryStats(),
);

final recentScreenshotsProvider = StreamProvider<List<ScreenshotRow>>(
  (ref) => ref.watch(repositoryProvider).watchRecent(limit: 16),
);

final cleanupReportProvider = StreamProvider<CleanupReport>(
  (ref) => ref
      .watch(repositoryProvider)
      .watchCleanupItems()
      .map((items) => const CleanupRules().analyze(items)),
);

final screenshotProvider = StreamProvider.autoDispose.family<ScreenshotRow?, String>(
  (ref, id) => ref.watch(repositoryProvider).watchOne(id),
);

final entitiesProvider = StreamProvider.autoDispose.family<List<EntityRow>, String>(
  (ref, id) => ref.watch(repositoryProvider).watchEntities(id),
);

final receiptTotalsProvider = StreamProvider.autoDispose<Map<String, double>>((ref) {
  final now = DateTime.now();
  return ref.watch(repositoryProvider).watchReceiptTotals(DateTime(now.year, now.month));
});

final sourceAppsProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => ref.watch(repositoryProvider).sourceApps(),
);

/// Ask the Search tab to focus its field (incremented by the Home search pill).
class SearchFocusRequest extends Notifier<int> {
  @override
  int build() => 0;
  void request() => state++;
}

final searchFocusRequestProvider = NotifierProvider<SearchFocusRequest, int>(SearchFocusRequest.new);

ScreenshotCategory categoryOf(ScreenshotRow row) => ScreenshotCategory.fromName(row.category);
