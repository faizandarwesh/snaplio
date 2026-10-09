import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snaplio_native/snaplio_native.dart';

import 'providers.dart';
import 'router.dart';

/// Where a `snaplio://` (or `snapsort://`) link leads.
class DeepLinkTarget {
  const DeepLinkTarget(this.location, {this.tab = false, this.focusSearch = false, this.linksFilter = false});

  final String location;

  /// A shell tab (go) rather than a screen pushed on top (push).
  final bool tab;
  final bool focusSearch;
  final bool linksFilter;

  @override
  String toString() => 'DeepLinkTarget($location, tab: $tab)';
}

/// snaplio://search · spend · clean · links · home
/// snaplio://screenshot/`id` · expense/`id` · recap/`id`
DeepLinkTarget? parseDeepLink(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !(uri.scheme == 'snaplio' || uri.scheme == 'snapsort')) return null;
  final host = uri.host.toLowerCase();
  final seg = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final id = seg.isEmpty ? null : seg.first;
  return switch (host) {
    'home' || '' => const DeepLinkTarget(Routes.home, tab: true),
    'search' => const DeepLinkTarget(Routes.search, tab: true, focusSearch: true),
    'spend' => const DeepLinkTarget(Routes.spend, tab: true),
    'clean' => const DeepLinkTarget(Routes.clean, tab: true),
    'links' => const DeepLinkTarget(Routes.search, tab: true, linksFilter: true),
    'screenshot' when id != null => DeepLinkTarget(Routes.detail(id)),
    'expense' when id != null && int.tryParse(id) != null => DeepLinkTarget(Routes.expense(int.parse(id))),
    'recap' when id != null => DeepLinkTarget(Routes.recap(id)),
    _ => null,
  };
}

/// Ask Search to show a preset filter (bumped for each request).
class SearchPreset extends Notifier<({int seq, bool links})> {
  @override
  ({int seq, bool links}) build() => (seq: 0, links: false);
  void links() => state = (seq: state.seq + 1, links: true);
}

final searchPresetProvider = NotifierProvider<SearchPreset, ({int seq, bool links})>(SearchPreset.new);

/// Routes deep links from notifications and widgets. Links that arrive
/// before the app is ready (splash, onboarding) wait in [_pending].
class DeepLinkController {
  DeepLinkController(this.ref);

  final Ref ref;
  String? _pending;
  bool _ready = false;
  StreamSubscription<String>? _sub;

  void start() {
    _sub ??= SnapNative.links.listen(handle);
  }

  /// Called by the splash once it knows where the app should go.
  Future<String?> takeInitialLink() async => _pending ?? await SnapNative.initialLink();

  /// The shell is showing; deliver anything that was waiting.
  void markReady() {
    _ready = true;
    final p = _pending;
    _pending = null;
    if (p != null) handle(p);
  }

  void handle(String link) {
    if (!_ready) {
      _pending = link;
      return;
    }
    final t = parseDeepLink(link);
    if (t == null) return;
    final router = ref.read(routerProvider);
    if (t.tab) {
      router.go(t.location);
      if (t.focusSearch) ref.read(searchFocusRequestProvider.notifier).request();
      if (t.linksFilter) ref.read(searchPresetProvider.notifier).links();
    } else {
      final here = router.routerDelegate.currentConfiguration.uri.path;
      final inShell = [Routes.home, Routes.search, Routes.spend, Routes.clean].contains(here);
      if (!inShell && here != t.location) router.go(Routes.home);
      if (here != t.location) router.push(t.location);
    }
  }

  void dispose() => _sub?.cancel();
}

final deepLinkProvider = Provider<DeepLinkController>((ref) {
  final c = DeepLinkController(ref)..start();
  ref.onDispose(c.dispose);
  return c;
});
