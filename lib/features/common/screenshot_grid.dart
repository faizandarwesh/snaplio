import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/widgets/asset_thumb.dart';
import '../../data/screenshot_repository.dart';

/// 3-column sliver grid of screenshot thumbnails with optional selection.
class ScreenshotSliverGrid extends StatelessWidget {
  const ScreenshotSliverGrid({
    super.key,
    required this.rows,
    required this.heroScope,
    required this.onTap,
    this.selected = const {},
    this.selecting = false,
    this.onLongPress,
    this.showSize = false,
  });

  final List<ScreenshotRow> rows;
  final String heroScope;
  final Set<String> selected;
  final bool selecting;
  final void Function(ScreenshotRow row, int index) onTap;
  final void Function(ScreenshotRow row)? onLongPress;
  final bool showSize;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.screen),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.56,
        ),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final r = rows[i];
          return _GridCell(
            key: ValueKey(r.assetId),
            row: r,
            heroTag: '$heroScope-${r.assetId}',
            selecting: selecting,
            selected: selected.contains(r.assetId),
            showSize: showSize,
            onTap: () => onTap(r, i),
            onLongPress: onLongPress == null ? null : () => onLongPress!(r),
          );
        },
      ),
    );
  }
}

class _GridCell extends StatefulWidget {
  const _GridCell({
    super.key,
    required this.row,
    required this.heroTag,
    required this.selecting,
    required this.selected,
    required this.showSize,
    required this.onTap,
    this.onLongPress,
  });

  final ScreenshotRow row;
  final String heroTag;
  final bool selecting;
  final bool selected;
  final bool showSize;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final scale = _down ? 0.96 : (sel ? 0.9 : 1.0);
    return RepaintBoundary(
      child: Semantics(
        button: true,
        selected: sel,
        label: 'Screenshot',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: () {
            if (widget.selecting) Haptics.selection();
            widget.onTap();
          },
          onLongPress: widget.onLongPress == null
              ? null
              : () {
                  setState(() => _down = false);
                  Haptics.medium();
                  widget.onLongPress!();
                },
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(tag: widget.heroTag, child: AssetThumb(widget.row.assetId)),
                if (widget.showSize)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(6)),
                      child: Text(_mb(widget.row.sizeBytes), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (widget.row.isFavorite)
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: Icon(Icons.favorite_rounded, size: 16, color: Colors.white, shadows: [Shadow(blurRadius: 6)]),
                  ),
                if (widget.selecting)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: AnimatedContainer(
                      duration: Motion.fast,
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: sel ? Brand.gradient : null,
                        color: sel ? null : Colors.black.withValues(alpha: 0.3),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: sel ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                    ),
                  ),
                if (sel)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: Border.all(color: Brand.violet, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _mb(int b) => b >= 1024 * 1024 ? '${(b / 1024 / 1024).toStringAsFixed(1)} MB' : '${(b / 1024).round()} KB';
}

/// Floating bottom action bar used in selection modes.
class SelectionBar extends StatelessWidget {
  const SelectionBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, bottom + Space.sm),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: Radii.lgAll,
          border: Border.all(color: c.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: children),
      ),
    );
  }
}

class SelectionAction extends StatelessWidget {
  const SelectionAction({super.key, required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = onTap == null ? context.colors.textTertiary : (color ?? context.colors.textPrimary);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 2),
            Text(label, style: context.text.labelSmall?.copyWith(color: fg, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
