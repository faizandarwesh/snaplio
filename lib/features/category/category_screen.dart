import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/shimmer.dart';
import '../../core/widgets/states.dart';
import '../../data/screenshot_repository.dart';
import '../../domain/models.dart';
import '../common/screenshot_actions.dart';
import '../common/screenshot_grid.dart';

final _categoryRowsProvider = StreamProvider.autoDispose.family<List<ScreenshotRow>, (ScreenshotCategory, SortOrder)>(
  (ref, arg) => ref.watch(repositoryProvider).watchCategory(arg.$1, arg.$2),
);

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.category});
  final ScreenshotCategory category;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  SortOrder _sort = SortOrder.newest;
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _toggle(String id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  List<ScreenshotRow> _selectedRows(List<ScreenshotRow> rows) => rows.where((r) => _selected.contains(r.assetId)).toList();

  Future<void> _delete(List<ScreenshotRow> rows) async {
    final outcome = await deleteScreenshots(ref, _selectedRows(rows));
    if (!mounted) return;
    if (outcome.any) setState(_selected.clear);
    showFreedSnack(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(widget.category);
    final async = ref.watch(_categoryRowsProvider((widget.category, _sort)));
    final rows = async.value ?? const <ScreenshotRow>[];
    final allSelected = rows.isNotEmpty && _selected.length == rows.length;

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        extendBody: true,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 132,
              backgroundColor: context.colors.background,
              leading: IconButton(
                tooltip: _selecting ? 'Cancel selection' : 'Back',
                icon: Icon(_selecting ? Icons.close_rounded : Icons.arrow_back_rounded),
                onPressed: () => _selecting ? setState(_selected.clear) : context.pop(),
              ),
              actions: [
                if (_selecting)
                  TextButton(
                    onPressed: () {
                      Haptics.selection();
                      setState(() => allSelected ? _selected.clear() : _selected.addAll(rows.map((r) => r.assetId)));
                    },
                    child: Text(allSelected ? 'Deselect all' : 'Select all'),
                  )
                else
                  PopupMenuButton<SortOrder>(
                    tooltip: 'Sort',
                    icon: const Icon(Icons.swap_vert_rounded),
                    initialValue: _sort,
                    color: context.colors.surfaceElevated,
                    shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
                    onSelected: (s) {
                      Haptics.selection();
                      setState(() => _sort = s);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: SortOrder.newest, child: Text('Newest first')),
                      PopupMenuItem(value: SortOrder.oldest, child: Text('Oldest first')),
                      PopupMenuItem(value: SortOrder.largest, child: Text('Largest first')),
                    ],
                  ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14, end: 100),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_selecting) ...[
                      Icon(style.icon, color: style.color, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        _selecting ? '${_selected.length} selected' : widget.category.label,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.category == ScreenshotCategory.receipts && !_selecting)
              const SliverToBoxAdapter(child: _ReceiptsSummary()),
            if (async.isLoading && rows.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.56),
                  itemCount: 12,
                  itemBuilder: (_, _) => const ShimmerBox(radius: Radii.sm),
                ),
              )
            else if (async.hasError)
              SliverFillRemaining(hasScrollBody: false, child: ErrorState(onRetry: () => ref.invalidate(_categoryRowsProvider)))
            else if (rows.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: style.icon,
                  accent: style.color,
                  title: 'Nothing here yet',
                  message: 'Screenshots sorted into ${widget.category.label} will show up here.',
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, Space.sm),
                  child: Text(
                    '${formatCount(rows.length)} screenshots · ${formatBytes(rows.fold(0, (s, r) => s + r.sizeBytes))}',
                    style: context.text.labelSmall,
                  ),
                ),
              ),
              ScreenshotSliverGrid(
                rows: rows,
                heroScope: 'cat',
                selecting: _selecting,
                selected: _selected,
                showSize: _sort == SortOrder.largest,
                onLongPress: (r) => _toggle(r.assetId),
                onTap: (r, i) {
                  if (_selecting) {
                    _toggle(r.assetId);
                  } else {
                    context.push(
                      Routes.detail(r.assetId),
                      extra: DetailArgs(ids: [for (final x in rows) x.assetId], heroScope: 'cat'),
                    );
                  }
                },
              ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 100)),
          ],
        ),
        bottomNavigationBar: AnimatedSwitcher(
          duration: Motion.medium,
          transitionBuilder: (child, a) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Motion.enter)),
            child: child,
          ),
          child: !_selecting
              ? const SizedBox.shrink()
              : SelectionBar(
                  key: const ValueKey('bar'),
                  children: [
                    SelectionAction(
                      icon: Icons.favorite_border_rounded,
                      label: 'Favorite',
                      onTap: () async {
                        final sel = _selectedRows(rows);
                        final makeFav = sel.any((r) => !r.isFavorite);
                        await ref.read(repositoryProvider).setFavorite(sel.map((r) => r.assetId), makeFav);
                        Haptics.light();
                        if (mounted) setState(_selected.clear);
                      },
                    ),
                    SelectionAction(
                      icon: Icons.ios_share_rounded,
                      label: 'Share',
                      onTap: () => shareScreenshots(ref, _selectedRows(rows)),
                    ),
                    SelectionAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: context.colors.danger,
                      onTap: () => _delete(rows),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ReceiptsSummary extends ConsumerWidget {
  const _ReceiptsSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(receiptTotalsProvider).value ?? const {};
    final c = context.colors;
    final s = CategoryStyle.of(ScreenshotCategory.receipts);
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, Space.sm),
      child: Pressable(
        haptic: false,
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(color: s.tint(context), borderRadius: Radii.mdAll, border: Border.all(color: s.color.withValues(alpha: 0.2))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detected this month', style: context.text.labelSmall),
              const SizedBox(height: 4),
              if (entries.isEmpty)
                Text('No amounts yet', style: context.text.titleLarge?.copyWith(color: c.textSecondary))
              else
                Wrap(
                  spacing: Space.md,
                  runSpacing: 4,
                  children: [
                    for (final e in entries.take(3)) Text(formatMoney(e.key, e.value), style: context.text.headlineSmall?.copyWith(color: s.color)),
                  ],
                ),
              const SizedBox(height: 4),
              Text('Largest amount on each receipt, summed by currency.', style: context.text.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
