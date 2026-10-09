import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/deep_links.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/shell.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/asset_thumb.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/shimmer.dart';
import '../../core/widgets/states.dart';
import '../../data/screenshot_repository.dart';
import '../../domain/models.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _token = 0;

  final Set<ScreenshotCategory> _cats = {};
  final Set<String> _apps = {};
  DateFilter? _date;

  List<SearchHit>? _results;
  bool _loading = false;
  Object? _error;

  bool get _hasFilters => _cats.isNotEmpty || _apps.isNotEmpty || _date != null;
  bool get _hasQuery => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _run);
  }

  Future<void> _run() async {
    final token = ++_token;
    if (!_hasQuery && !_hasFilters) {
      setState(() {
        _results = null;
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = _results == null);
    try {
      final hits = await ref.read(repositoryProvider).search(
            query: _controller.text,
            categories: _cats,
            apps: _apps,
            date: _date,
          );
      if (!mounted || token != _token) return;
      setState(() {
        _results = hits;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || token != _token) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _setQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    _run();
    setState(() {});
  }

  void _saveRecent() => ref.read(settingsProvider.notifier).addRecentSearch(_controller.text);

  @override
  Widget build(BuildContext context) {
    // Home's search pill asks us to focus the field.
    ref.listen(searchFocusRequestProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    });
    // The Links widget / deep link opens Search filtered to Links.
    ref.listen(searchPresetProvider, (_, p) {
      if (!p.links) return;
      _focus.unfocus();
      setState(() {
        _cats
          ..clear()
          ..add(ScreenshotCategory.links);
      });
      _run();
    });

    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: GestureDetector(
        onTap: () => _focus.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            SizedBox(height: topPad + Space.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: _SearchField(
                controller: _controller,
                focus: _focus,
                onChanged: _onChanged,
                onSubmitted: (_) => _saveRecent(),
                onClear: () => _setQuery(''),
              ),
            ),
            const SizedBox(height: Space.sm),
            _FilterRow(
              cats: _cats,
              apps: _apps,
              date: _date,
              onCat: (c) {
                setState(() => _cats.contains(c) ? _cats.remove(c) : _cats.add(c));
                _run();
              },
              onApp: (a) {
                setState(() => _apps.contains(a) ? _apps.remove(a) : _apps.add(a));
                _run();
              },
              onDate: (d) {
                setState(() => _date = _date == d ? null : d);
                _run();
              },
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) return ErrorState(onRetry: _run);
    if (!_hasQuery && !_hasFilters) {
      return _Suggestions(onPick: (q) {
        _setQuery(q);
        _saveRecent();
      });
    }
    if (_loading) return const _ResultsSkeleton();
    final results = _results ?? const [];
    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: _hasQuery ? 'Nothing found for “${_controller.text.trim()}”. Try fewer words or another filter.' : 'No screenshots match these filters.',
      );
    }
    final ids = [for (final h in results) h.row.assetId];
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, navBarClearance(context)),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Text('${formatCount(results.length)}${results.length >= 120 ? '+' : ''} results', style: context.text.labelSmall),
          );
        }
        final hit = results[i - 1];
        return _ResultTile(
          hit: hit,
          onTap: () {
            _saveRecent();
            _focus.unfocus();
            context.push(Routes.detail(hit.row.assetId), extra: DetailArgs(ids: ids, heroScope: 'search'));
          },
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: focus,
      builder: (context, _) => AnimatedContainer(
        duration: Motion.fast,
        height: 54,
        padding: const EdgeInsets.only(left: Space.md, right: 4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: focus.hasFocus ? Brand.violet.withValues(alpha: 0.7) : c.border, width: focus.hasFocus ? 1.5 : 1),
          boxShadow: [
            if (focus.hasFocus) BoxShadow(color: Brand.violet.withValues(alpha: 0.15), blurRadius: 18),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: focus.hasFocus ? Brand.violet : c.textSecondary),
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                style: context.text.bodyLarge,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search text in screenshots',
                  hintStyle: context.text.bodyLarge?.copyWith(color: c.textTertiary),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                onPressed: onClear,
                tooltip: 'Clear',
                icon: Icon(Icons.close_rounded, color: c.textSecondary, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({
    required this.cats,
    required this.apps,
    required this.date,
    required this.onCat,
    required this.onApp,
    required this.onDate,
  });

  final Set<ScreenshotCategory> cats;
  final Set<String> apps;
  final DateFilter? date;
  final ValueChanged<ScreenshotCategory> onCat;
  final ValueChanged<String> onApp;
  final ValueChanged<DateFilter> onDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceApps = ref.watch(sourceAppsProvider).value ?? const [];
    final divider = Container(width: 1, height: 22, margin: const EdgeInsets.symmetric(horizontal: 4), color: context.colors.border);
    final children = <Widget>[
      for (final d in DateFilter.values) FilterPill(label: d.label, selected: date == d, onTap: () => onDate(d), icon: Icons.calendar_today_rounded),
      divider,
      for (final c in ScreenshotCategory.values)
        FilterPill(
          label: c.label,
          selected: cats.contains(c),
          onTap: () => onCat(c),
          icon: CategoryStyle.of(c).icon,
          accent: CategoryStyle.of(c).color,
        ),
      if (sourceApps.isNotEmpty) divider,
      for (final a in sourceApps) FilterPill(label: a, selected: apps.contains(a), onTap: () => onApp(a), icon: Icons.apps_rounded, accent: Brand.sky),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.screen, vertical: 4),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.onPick});
  final ValueChanged<String> onPick;

  static const _tries = ['OTP', 'receipt', 'wifi', 'address', 'order', 'password', 'error'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(settingsProvider.select((s) => s.recentSearches));
    final c = context.colors;
    return ListView(
      padding: EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, navBarClearance(context)),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (recent.isNotEmpty) ...[
          Row(children: [
            Expanded(child: Text('Recent searches', style: context.text.titleSmall)),
            TextButton(
              onPressed: () {
                Haptics.selection();
                ref.read(settingsProvider.notifier).clearRecentSearches();
              },
              child: const Text('Clear'),
            ),
          ]),
          for (final r in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history_rounded, color: c.textTertiary),
              title: Text(r, style: context.text.bodyLarge),
              trailing: Icon(Icons.north_west_rounded, size: 18, color: c.textTertiary),
              onTap: () => onPick(r),
            ),
          const SizedBox(height: Space.lg),
        ],
        Center(
          child: Column(
            children: [
              const SizedBox(height: Space.lg),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Brand.violet.withValues(alpha: 0.12)),
                child: const Icon(Icons.manage_search_rounded, size: 34, color: Brand.violet),
              ),
              const SizedBox(height: Space.md),
              Text('Search inside your screenshots', style: context.text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('Every word on screen is searchable, offline.', style: context.text.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: Space.md),
              Text('Try:', style: context.text.labelSmall),
              const SizedBox(height: Space.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in _tries) FilterPill(label: t, selected: false, onTap: () => onPick(t)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.hit, required this.onTap});
  final SearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = hit.row;
    final c = context.colors;
    final snippet = hit.snippet;
    final body = (snippet != null && snippet.trim().isNotEmpty) ? snippet : (r.ocrText ?? r.fileName);
    final tile = Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.sm),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: c.surface, borderRadius: Radii.mdAll, border: Border.all(color: c.border)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              height: 96,
              child: Hero(tag: 'search-${r.assetId}', child: AssetThumb(r.assetId, size: 200, radius: 10)),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CategoryTag(ScreenshotCategory.fromName(r.category)),
                    const Spacer(),
                    Text(relativeDate(r.createdAt), style: context.text.labelSmall),
                  ]),
                  const SizedBox(height: 6),
                  HighlightedText(body, maxLines: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return RepaintBoundary(child: context.reduceMotion ? tile : tile.animate().fadeIn(duration: Motion.fast));
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(Space.screen),
        itemCount: 5,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(bottom: Space.sm),
          child: ShimmerBox(height: 116, radius: Radii.md),
        ),
      );
}
