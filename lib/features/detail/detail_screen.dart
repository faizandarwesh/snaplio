import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/asset_thumb.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/pressable.dart';
import '../../data/screenshot_repository.dart';
import '../../domain/models.dart';
import '../common/screenshot_actions.dart';
import 'entity_actions.dart';

/// Full-screen viewer: pinch-zoom, Hero from the grid, swipe down to dismiss,
/// swipe sideways for neighbours, and a draggable sheet with actions.
class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.initialId, required this.args});

  final String initialId;
  final DetailArgs args;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> with SingleTickerProviderStateMixin {
  late List<String> _ids;
  late int _index;
  late final PageController _pages;
  final _zoomed = ValueNotifier(false);
  bool _chrome = true;

  // Swipe-to-dismiss.
  double _drag = 0;
  late final AnimationController _settle = AnimationController(vsync: this, duration: Motion.medium);
  Animation<double>? _settleAnim;

  @override
  void initState() {
    super.initState();
    _ids = widget.args.ids.contains(widget.initialId) ? [...widget.args.ids] : [widget.initialId];
    _index = _ids.indexOf(widget.initialId);
    _pages = PageController(initialPage: _index);
    _settle.addListener(() => setState(() => _drag = _settleAnim?.value ?? 0));
  }

  @override
  void dispose() {
    _pages.dispose();
    _settle.dispose();
    _zoomed.dispose();
    super.dispose();
  }

  String get _currentId => _ids[_index];

  void _onDragUpdate(DragUpdateDetails d) {
    if (_zoomed.value) return;
    setState(() => _drag = (_drag + d.delta.dy).clamp(-60, 600));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_zoomed.value) return;
    if (_drag > 120 || d.primaryVelocity! > 900) {
      Haptics.light();
      context.pop();
      return;
    }
    _settleAnim = Tween(begin: _drag, end: 0.0).animate(CurvedAnimation(parent: _settle, curve: Curves.easeOutBack));
    _settle.forward(from: 0);
  }

  Future<void> _delete(ScreenshotRow row) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await deleteScreenshots(ref, [row]);
    if (!mounted || !outcome.any) return;
    if (_ids.length == 1) {
      context.pop();
    } else {
      setState(() {
        _ids.removeAt(_index);
        _index = _index.clamp(0, _ids.length - 1);
      });
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Deleted · ${formatBytes(outcome.bytes)} freed')));
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_drag.abs() / 400).clamp(0.0, 1.0);
    final bgOpacity = 1 - progress * 0.85;
    final row = ref.watch(screenshotProvider(_currentId)).value;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: bgOpacity))),
            Positioned.fill(
              child: GestureDetector(
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                onTap: () => setState(() => _chrome = !_chrome),
                child: Transform.translate(
                  offset: Offset(0, _drag),
                  child: Transform.scale(
                    scale: 1 - progress * 0.2,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _zoomed,
                      builder: (context, zoomed, _) => PageView.builder(
                        controller: _pages,
                        physics: zoomed ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                        itemCount: _ids.length,
                        onPageChanged: (i) {
                          Haptics.selection();
                          setState(() => _index = i);
                        },
                        itemBuilder: (context, i) => _ZoomableImage(
                          key: ValueKey(_ids[i]),
                          assetId: _ids[i],
                          heroTag: '${widget.args.heroScope}-${_ids[i]}',
                          onZoomChanged: (z) => _zoomed.value = z,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_chrome || progress > 0.05,
                child: AnimatedOpacity(
                  duration: Motion.fast,
                  opacity: _chrome ? (1 - progress * 3).clamp(0.0, 1.0) : 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 4, 8, 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                        const Spacer(),
                        if (_ids.length > 1)
                          Text('${_index + 1} / ${_ids.length}', style: context.text.labelMedium?.copyWith(color: Colors.white70)),
                        const Spacer(),
                        IconButton(
                          tooltip: row?.isFavorite == true ? 'Unfavorite' : 'Favorite',
                          onPressed: row == null
                              ? null
                              : () {
                                  Haptics.light();
                                  ref.read(repositoryProvider).setFavorite([row.assetId], !row.isFavorite);
                                },
                          icon: AnimatedSwitcher(
                            duration: Motion.fast,
                            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                            child: Icon(
                              row?.isFavorite == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              key: ValueKey(row?.isFavorite),
                              color: row?.isFavorite == true ? const Color(0xFFEB8DBA) : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (row != null)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_chrome || progress > 0.05,
                  child: AnimatedOpacity(
                    duration: Motion.fast,
                    opacity: _chrome ? (1 - progress * 3).clamp(0.0, 1.0) : 0,
                    child: _InfoSheet(
                      key: ValueKey(row.assetId),
                      row: row,
                      onDelete: () => _delete(row),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({super.key, required this.assetId, required this.heroTag, required this.onZoomChanged});

  final String assetId;
  final String heroTag;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> with SingleTickerProviderStateMixin {
  final _t = TransformationController();
  late final AnimationController _anim = AnimationController(vsync: this, duration: Motion.medium);
  Animation<Matrix4>? _matrixAnim;
  TapDownDetails? _doubleTap;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _t.addListener(() {
      final z = _t.value.getMaxScaleOnAxis() > 1.01;
      if (z != _zoomed) {
        _zoomed = z;
        widget.onZoomChanged(z);
      }
    });
    _anim.addListener(() => _t.value = _matrixAnim!.value);
  }

  @override
  void dispose() {
    _t.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final pos = _doubleTap?.localPosition ?? Offset.zero;
    final target = _zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
          ..translateByDouble(-pos.dx * 1.5, -pos.dy * 1.5, 0, 1)
          ..scaleByDouble(2.5, 2.5, 1, 1));
    _matrixAnim = Matrix4Tween(begin: _t.value, end: target).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final path = ref.watch(screenshotProvider(widget.assetId)).value?.filePath;
        return GestureDetector(
          onDoubleTapDown: (d) => _doubleTap = d,
          onDoubleTap: _toggleZoom,
          child: InteractiveViewer(
            transformationController: _t,
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Hero(
                tag: widget.heroTag,
                child: Image(
                  image: fullImageProvider(widget.assetId, path),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  // Show the cached grid thumbnail instantly while the full file decodes.
                  frameBuilder: (context, child, frame, sync) => frame == null && !sync
                      ? Image(image: AssetThumbProvider(widget.assetId), fit: BoxFit.contain)
                      : child,
                  errorBuilder: (context, e, s) => Image(
                    image: AssetThumbProvider(widget.assetId, size: 1600),
                    fit: BoxFit.contain,
                    errorBuilder: (context, e, s) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoSheet extends ConsumerWidget {
  const _InfoSheet({super.key, required this.row, required this.onDelete});

  final ScreenshotRow row;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final entities = ref.watch(entitiesProvider(row.assetId)).value ?? const [];
    final actions = actionsFor(entities);
    final category = ScreenshotCategory.fromName(row.category);
    final hasText = (row.ocrText ?? '').trim().isNotEmpty;

    void toast(String? msg) {
      if (msg == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
    }

    return DraggableScrollableSheet(
      initialChildSize: actions.isEmpty ? 0.16 : 0.24,
      minChildSize: 0.12,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.24, 0.55],
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
          border: Border(top: BorderSide(color: c.border)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 30)],
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(Space.screen, 10, Space.screen, MediaQuery.paddingOf(context).bottom + Space.lg),
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.textTertiary.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: Space.md),
            if (actions.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < actions.length; i++)
                    _ActionChip(action: actions[i], onResult: toast)
                        .animate()
                        .scale(begin: const Offset(0.7, 0.7), delay: (40 * i).ms, duration: 450.ms, curve: Curves.elasticOut)
                        .fadeIn(delay: (40 * i).ms, duration: 150.ms),
                ],
              ),
              const SizedBox(height: Space.lg),
            ] else ...[
              Text(
                hasText ? 'No links, numbers or codes found.' : (row.processedAt == null ? 'Still reading this screenshot…' : 'No text found in this screenshot.'),
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: Space.lg),
            ],
            Row(
              children: [
                Expanded(child: SoftButton(label: 'Share', icon: Icons.ios_share_rounded, expand: true, onPressed: () => shareScreenshots(ref, [row]))),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: SoftButton(
                    label: row.isFavorite ? 'Favorited' : 'Favorite',
                    icon: row.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    expand: true,
                    color: row.isFavorite ? const Color(0xFFEB8DBA) : null,
                    onPressed: () => ref.read(repositoryProvider).setFavorite([row.assetId], !row.isFavorite),
                  ),
                ),
                const SizedBox(width: Space.xs),
                Expanded(child: SoftButton(label: 'Delete', icon: Icons.delete_outline_rounded, expand: true, color: c.danger, onPressed: onDelete)),
              ],
            ),
            const SizedBox(height: Space.lg),
            if (hasText) ...[
              Row(
                children: [
                  Expanded(child: Text('Extracted text', style: context.text.titleSmall)),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: row.ocrText!));
                      Haptics.light();
                      toast('Text copied');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy all'),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Space.sm),
                decoration: BoxDecoration(color: c.surface, borderRadius: Radii.smAll, border: Border.all(color: c.border)),
                child: SelectableText(row.ocrText!, style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
              ),
              const SizedBox(height: Space.lg),
            ],
            Text('Details', style: context.text.titleSmall),
            const SizedBox(height: Space.xs),
            _MetaRow(icon: Icons.schedule_rounded, label: 'Taken', value: fullDate(row.createdAt)),
            if (row.sourceApp != null) _MetaRow(icon: Icons.apps_rounded, label: 'App', value: row.sourceApp!),
            _MetaRow(icon: Icons.sd_storage_outlined, label: 'Size', value: '${formatBytes(row.sizeBytes)} · ${row.width}×${row.height}'),
            Pressable(
              onTap: () => _pickCategory(context, ref, category),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.label_outline_rounded, size: 18, color: c.textTertiary),
                    const SizedBox(width: Space.sm),
                    SizedBox(width: 64, child: Text('Category', style: context.text.bodyMedium)),
                    CategoryTag(category, dense: false),
                    const Spacer(),
                    Text('Change', style: context.text.labelMedium?.copyWith(color: Brand.violet)),
                    const Icon(Icons.chevron_right_rounded, color: Brand.violet),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCategory(BuildContext context, WidgetRef ref, ScreenshotCategory current) async {
    final picked = await showModalBottomSheet<ScreenshotCategory>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, Space.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Move to category', style: context.text.titleLarge),
              const SizedBox(height: Space.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in ScreenshotCategory.values)
                    FilterPill(
                      label: cat.label,
                      icon: CategoryStyle.of(cat).icon,
                      accent: CategoryStyle.of(cat).color,
                      selected: cat == current,
                      onTap: () => Navigator.of(context).pop(cat),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != current) {
      await ref.read(repositoryProvider).setCategory(row.assetId, picked);
    }
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action, required this.onResult});
  final EntityAction action;
  final ValueChanged<String?> onResult;

  @override
  Widget build(BuildContext context) {
    final a = action;
    return Pressable(
      semanticLabel: '${a.label} ${a.detail ?? ''}',
      onTap: () async => onResult(await a.run()),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: a.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: a.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(a.icon, size: 18, color: a.color),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.label, style: context.text.labelMedium?.copyWith(color: a.color)),
                  if (a.detail != null)
                    Text(a.detail!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelSmall?.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.textTertiary),
          const SizedBox(width: Space.sm),
          SizedBox(width: 64, child: Text(label, style: context.text.bodyMedium)),
          Expanded(child: Text(value, style: context.text.bodyMedium?.copyWith(color: c.textPrimary))),
        ],
      ),
    );
  }
}
