import 'package:flutter/material.dart';

import '../../data/screenshot_repository.dart' show kHlEnd, kHlStart;
import '../../domain/models.dart';
import '../design/tokens.dart';
import '../haptics.dart';

/// Small category label with the category accent.
class CategoryTag extends StatelessWidget {
  const CategoryTag(this.category, {super.key, this.dense = true});

  final ScreenshotCategory category;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = CategoryStyle.of(category);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 6),
      decoration: BoxDecoration(color: s.tint(context), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: dense ? 12 : 14, color: s.color),
          const SizedBox(width: 4),
          Text(category.label, style: context.text.labelSmall?.copyWith(color: s.color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Selectable filter chip with haptics and a soft accent fill.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent = Brand.violet,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.enter,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.16) : c.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: selected ? accent.withValues(alpha: 0.6) : c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: selected ? accent : c.textSecondary),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: context.text.labelMedium?.copyWith(color: selected ? accent : c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a search snippet, emphasizing the parts between highlight markers.
class HighlightedText extends StatelessWidget {
  const HighlightedText(this.text, {super.key, this.maxLines = 2, this.style});

  final String text;
  final int maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.text.bodyMedium!;
    final hl = base.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w700,
      backgroundColor: Brand.violet.withValues(alpha: 0.22),
    );
    final spans = <TextSpan>[];
    var rest = text.replaceAll('\n', ' ');
    while (rest.isNotEmpty) {
      final s = rest.indexOf(kHlStart);
      if (s < 0) {
        spans.add(TextSpan(text: rest));
        break;
      }
      if (s > 0) spans.add(TextSpan(text: rest.substring(0, s)));
      final e = rest.indexOf(kHlEnd, s);
      if (e < 0) {
        spans.add(TextSpan(text: rest.substring(s + 1), style: hl));
        break;
      }
      spans.add(TextSpan(text: rest.substring(s + 1, e), style: hl));
      rest = rest.substring(e + 1);
    }
    return Text.rich(TextSpan(style: base, children: spans), maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
}

/// Section title row with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.screen, Space.lg, Space.screen, Space.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleMedium)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Animated integer counter (respects reduce-motion).
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style, this.format, this.duration = const Duration(milliseconds: 900)});

  final num value;
  final TextStyle? style;
  final String Function(num v)? format;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final fmt = format ?? (v) => v.round().toString();
    if (context.reduceMotion) return Text(fmt(value), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(fmt(v), style: style),
    );
  }
}
