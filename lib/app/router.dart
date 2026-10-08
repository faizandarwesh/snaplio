import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/cleanup_rules/cleanup_rules.dart';
import '../domain/models.dart';
import '../features/category/category_screen.dart';
import '../features/cleanup/cleanup_screen.dart';
import '../features/cleanup/review_screen.dart';
import '../features/detail/detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/permission_screen.dart';
import '../features/scan/debug_scan_screen.dart';
import '../features/scan/first_scan_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/folders_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import 'shell.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const permission = '/permission';
  static const firstScan = '/first-scan';
  static const home = '/home';
  static const search = '/search';
  static const clean = '/clean';
  static const settings = '/settings';
  static const folders = '/settings/folders';
  static const debug = '/debug';

  static String category(ScreenshotCategory c) => '/category/${c.name}';
  static String detail(String id) => '/shot/${Uri.encodeComponent(id)}';
  static String review(CleanupKind k) => '/review/${k.name}';
}

/// Passed as `extra` when opening a screenshot so the detail view can swipe
/// between neighbours and match the Hero tag of the grid it came from.
class DetailArgs {
  const DetailArgs({required this.ids, required this.heroScope});
  final List<String> ids;
  final String heroScope;
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _fadeThrough(GoRouterState state, Widget child, {bool opaque = true}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    opaque: opaque,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.985, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    routes: [
      GoRoute(path: Routes.splash, pageBuilder: (c, s) => _fadeThrough(s, const SplashScreen())),
      GoRoute(path: Routes.onboarding, pageBuilder: (c, s) => _fadeThrough(s, const OnboardingScreen())),
      GoRoute(path: Routes.permission, pageBuilder: (c, s) => _fadeThrough(s, const PermissionScreen())),
      GoRoute(path: Routes.firstScan, pageBuilder: (c, s) => _fadeThrough(s, const FirstScanScreen())),
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            AnimatedBranchContainer(currentIndex: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (c, s) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.search, builder: (c, s) => const SearchScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.clean, builder: (c, s) => const CleanupScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.settings, builder: (c, s) => const SettingsScreen())]),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/category/:name',
        builder: (c, s) => CategoryScreen(category: ScreenshotCategory.fromName(s.pathParameters['name'])),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/shot/:id',
        pageBuilder: (c, s) {
          final id = s.pathParameters['id']!;
          final args = s.extra is DetailArgs ? s.extra! as DetailArgs : DetailArgs(ids: [id], heroScope: 'none');
          return _fadeThrough(s, DetailScreen(initialId: id, args: args), opaque: false);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/review/:kind',
        builder: (c, s) => ReviewScreen(
          kind: CleanupKind.values.firstWhere((k) => k.name == s.pathParameters['kind'], orElse: () => CleanupKind.old),
        ),
      ),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: Routes.folders, builder: (c, s) => const FoldersScreen()),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: Routes.debug, builder: (c, s) => const DebugScanScreen()),
    ],
  );
});
