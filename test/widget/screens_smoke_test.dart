import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_lio/app/providers.dart';
import 'package:snap_lio/app/theme/app_theme.dart';
import 'package:snap_lio/data/screenshot_repository.dart';
import 'package:snap_lio/domain/cleanup_rules/cleanup_rules.dart';
import 'package:snap_lio/domain/models.dart';
import 'package:snap_lio/features/cleanup/cleanup_screen.dart';
import 'package:snap_lio/features/home/home_screen.dart';
import 'package:snap_lio/features/onboarding/onboarding_screen.dart';
import 'package:snap_lio/features/onboarding/permission_screen.dart';
import 'package:snap_lio/features/search/search_screen.dart';
import 'package:snap_lio/features/settings/settings_screen.dart';
import 'package:snap_lio/services/gallery_service.dart';
import 'package:snap_lio/services/scan_service.dart';

class _FakeAccess extends GalleryAccessNotifier {
  @override
  Future<GalleryAccess> build() async => GalleryAccess.limited;
}

ScreenshotRow _row(int i, ScreenshotCategory c) => ScreenshotRow(
      assetId: 'a$i',
      fileName: 'Screenshot_$i.png',
      createdAt: DateTime(2026, 10, 8).subtract(Duration(days: i)),
      width: 1080,
      height: 2400,
      sizeBytes: 900000 + i * 1000,
      category: c.name,
      categoryLocked: false,
      isFavorite: false,
      processedAt: DateTime(2026, 10, 8),
    );

Future<void> _pump(WidgetTester tester, Widget screen, {required Brightness brightness, double textScale = 1.3}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      galleryAccessProvider.overrideWith(_FakeAccess.new),
      sourceAppsProvider.overrideWith((ref) async => ['WhatsApp', 'Chrome']),
      scanProgressProvider.overrideWith((ref) => Stream.value(const ScanProgress(phase: ScanPhase.processing, processed: 412, total: 1240))),
      libraryStatsProvider.overrideWith((ref) => Stream.value(const LibraryStats(total: 1240, processed: 412, bytes: 3400000000))),
      categoryStatsProvider.overrideWith((ref) => Stream.value([
            for (final c in ScreenshotCategory.values) CategoryStat(c, 120 + c.index * 7, 100000000, const ['a1', 'a2', 'a3']),
          ])),
      recentScreenshotsProvider.overrideWith((ref) => Stream.value([for (var i = 0; i < 6; i++) _row(i, ScreenshotCategory.otp)])),
      cleanupReportProvider.overrideWith((ref) => Stream.value(const CleanupReport([
            CleanupSuggestion(kind: CleanupKind.oldOtps, assetIds: ['a1', 'a2'], totalBytes: 1800000),
            CleanupSuggestion(kind: CleanupKind.duplicates, assetIds: ['a3'], totalBytes: 900000),
            CleanupSuggestion(kind: CleanupKind.old, assetIds: ['a4', 'a5', 'a6'], totalBytes: 330000000),
          ], 1100000000, 54))),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(size: const Size(320, 640), textScaler: TextScaler.linear(textScale)),
        child: screen,
      ),
    ),
  ));
  // Shimmers/looping art never settle, so pump a fixed duration.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final screens = <String, Widget Function()>{
    'onboarding': () => const OnboardingScreen(),
    'permission': () => const PermissionScreen(),
    'home': () => const HomeScreen(),
    'cleanup': () => const CleanupScreen(),
    'settings': () => const SettingsScreen(),
    'search': () => const SearchScreen(),
  };

  for (final b in Brightness.values) {
    for (final e in screens.entries) {
      testWidgets('${e.key} renders without overflow on a small screen (${b.name})', (tester) async {
        await _pump(tester, e.value(), brightness: b);
        // Any overflow or framework assertion fails the test with full details.
      });
    }
  }
}
