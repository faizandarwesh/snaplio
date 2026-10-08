import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../design/tokens.dart';
import 'pressable.dart';

/// Designed empty state: soft glowing icon, title, message, optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.accent = Brand.violet,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: Space.xl, vertical: compact ? Space.lg : Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 40)],
            ),
            child: Icon(icon, size: 34, color: accent),
          ),
          const SizedBox(height: Space.lg),
          Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(message, textAlign: TextAlign.center, style: context.text.bodyMedium),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.lg),
            SoftButton(label: actionLabel!, onPressed: onAction, color: accent),
          ],
        ],
      ),
    );
    if (context.reduceMotion) return Center(child: content);
    return Center(
      child: content.animate().fadeIn(duration: Motion.slow).moveY(begin: 12, end: 0, curve: Motion.enter),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: message ?? 'We couldn\'t load this right now. Your screenshots are safe.',
        actionLabel: onRetry == null ? null : 'Try again',
        onAction: onRetry,
        accent: context.colors.danger,
      );
}
