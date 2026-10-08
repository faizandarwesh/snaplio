import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/shimmer.dart';
import '../../core/widgets/states.dart';
import '../../data/screenshot_repository.dart';
import '../../domain/cleanup_rules/cleanup_rules.dart';
import '../../domain/models.dart';
import '../common/screenshot_actions.dart';
import '../common/screenshot_grid.dart';
import 'cleanup_screen.dart';

/// Pre-selected grid for one cleanup suggestion. The user can unselect, then
/// deletes through the system dialog and sees how much space was freed.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.kind});
  final CleanupKind kind;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<ScreenshotRow>? _rows;
  final Set<String> _selected = {};
  bool _deleting = false;
  DeleteOutcome? _done;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final report = await ref.read(cleanupReportProvider.future);
      final s = report.suggestions.where((x) => x.kind == widget.kind).firstOrNull;
      final rows = await ref.read(repositoryProvider).byIds(s?.assetIds ?? const []);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _selected
          ..clear()
          ..addAll(rows.map((r) => r.assetId));
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  int get _selectedBytes => (_rows ?? const <ScreenshotRow>[])
      .where((r) => _selected.contains(r.assetId))
      .fold(0, (s, r) => s + r.sizeBytes);

  Future<void> _delete() async {
    final rows = _rows!.where((r) => _selected.contains(r.assetId)).toList();
    setState(() => _deleting = true);
    try {
      final outcome = await deleteScreenshots(ref, rows);
      if (!mounted) return;
      if (!outcome.any) {
        setState(() => _deleting = false);
        return;
      }
      setState(() {
        _deleting = false;
        _done = outcome;
      });
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn\'t delete. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done != null) return _SuccessView(outcome: _done!);

    final rows = _rows;
    final allSelected = rows != null && rows.isNotEmpty && _selected.length == rows.length;
    final count = _selected.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kind.title),
        actions: [
          if (rows != null && rows.isNotEmpty)
            TextButton(
              onPressed: () {
                Haptics.selection();
                setState(() => allSelected ? _selected.clear() : _selected.addAll(rows.map((r) => r.assetId)));
              },
              child: Text(allSelected ? 'Select none' : 'Select all'),
            ),
        ],
      ),
      body: _error != null
          ? ErrorState(onRetry: _load)
          : rows == null
              ? GridView.builder(
                  padding: const EdgeInsets.all(Space.screen),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.56),
                  itemCount: 9,
                  itemBuilder: (_, _) => const ShimmerBox(radius: Radii.sm),
                )
              : rows.isEmpty
                  ? EmptyState(icon: widget.kind.icon, accent: widget.kind.color, title: 'Nothing to review', message: 'This suggestion is already cleaned up.')
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.md),
                            child: Text('${widget.kind.subtitle}. Tap to keep a screenshot.', style: context.text.bodyMedium),
                          ),
                        ),
                        ScreenshotSliverGrid(
                          rows: rows,
                          heroScope: 'review',
                          selecting: true,
                          selected: _selected,
                          showSize: widget.kind == CleanupKind.large,
                          onTap: (r, _) => setState(() => _selected.contains(r.assetId) ? _selected.remove(r.assetId) : _selected.add(r.assetId)),
                          onLongPress: (r) => context.push(
                            Routes.detail(r.assetId),
                            extra: DetailArgs(ids: [for (final x in rows) x.assetId], heroScope: 'review'),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 110)),
                      ],
                    ),
      bottomNavigationBar: rows == null || rows.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, MediaQuery.paddingOf(context).bottom + Space.sm),
              child: GradientButton(
                label: count == 0 ? 'Select screenshots to delete' : 'Delete ${formatCount(count)} · ${formatBytes(_selectedBytes)}',
                icon: count == 0 ? null : Icons.delete_outline_rounded,
                loading: _deleting,
                onPressed: count == 0 ? null : _delete,
              ),
            ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.outcome});
  final DeleteOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    Widget enter(Widget w, int i) => reduce ? w : w.animate().fadeIn(delay: (120 * i).ms, duration: 400.ms).moveY(begin: 14, end: 0, curve: Motion.enter);
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                enter(
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: Brand.gradient,
                      boxShadow: [BoxShadow(color: Brand.violet.withValues(alpha: 0.5), blurRadius: 60)],
                    ),
                    child: const Icon(Icons.check_rounded, size: 60, color: Colors.white),
                  ),
                  0,
                ),
                const SizedBox(height: Space.xl),
                enter(
                  CountUp(outcome.bytes, format: (v) => '${formatBytes(v.round())} freed', style: context.text.displaySmall),
                  1,
                ),
                const SizedBox(height: Space.xs),
                enter(Text('${formatCount(outcome.count)} screenshots deleted', style: context.text.bodyLarge?.copyWith(color: context.colors.textSecondary)), 2),
              ],
            ),
          ),
          Positioned.fill(
            child: ConfettiBurst(colors: [for (final c in ScreenshotCategory.values) CategoryStyle.of(c).color]),
          ),
        ],
      ),
    );
  }
}
